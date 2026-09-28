#!/usr/bin/env python3
"""Create the iOS distribution certificate and App Store provisioning profile
without ever touching a Mac. (Adapted from the Tubes project.)

Keychain Access is the usual way to make the certificate request, but it is not
the only way: a CSR is just a file, OpenSSL makes one anywhere, and App Store
Connect will issue against it over the API. That is the whole trick.

    python tools/asc/setup_signing.py --register-bundle-id \n        --key-path ../Tubes/tools/asc/out/private_key.pem --set-github-secrets

Heen needs the Push Notifications capability (APNs, no Firebase on iOS), so
this also registers the bundle id if it is missing and turns Push on before
the profile is made; a profile created before that would lack the
aps-environment entitlement.

--key-path reuses the team's existing distribution certificate (the one Tubes
already created) instead of burning one of Apple's few certificate slots.
That key is only read, never moved or overwritten.

Writes the private key, certificate, .p12 and .mobileprovision into
`tools/asc/out/` (git-ignored) and prints the base64 blobs to store as GitHub
secrets. Pass --set-github-secrets to upload them with `gh` directly.

Apple allows only a small number of distribution certificates per team, so this
reuses an existing certificate when its private key is already in `out/`, and
otherwise refuses to burn a slot unless you pass --force-new-cert.
"""

from __future__ import annotations

import argparse
import base64
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.parse

import asc

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    result = subprocess.run(cmd, capture_output=True, text=True, **kwargs)
    if result.returncode != 0:
        sys.exit(f"command failed: {' '.join(cmd)}\n{result.stderr}")
    return result


def make_csr(key_path: str, csr_path: str, common_name: str) -> str:
    """Generate an RSA 2048 key and a CSR — what Apple's CA expects."""
    if os.path.exists(key_path):
        # Overwriting strands whatever certificate this key belongs to: the
        # certificate keeps occupying one of the team's few slots and can never
        # be used again. Keep a copy instead of destroying it.
        backup = key_path + f".superseded-{int(time.time())}"
        shutil.copy2(key_path, backup)
        print(f"  existing key preserved as {os.path.basename(backup)}")
    run([asc.openssl(), "genrsa", "-out", key_path, "2048"])
    run([
        asc.openssl(), "req", "-new", "-key", key_path, "-out", csr_path,
        "-subj", f"/CN={common_name}/C=JO",
    ])
    with open(csr_path, "r", encoding="utf-8") as handle:
        return handle.read()


def create_certificate(csr: str, cert_type: str) -> dict:
    body = {
        "data": {
            "type": "certificates",
            "attributes": {"certificateType": cert_type, "csrContent": csr},
        }
    }
    return asc.request("POST", "/v1/certificates", body)["data"]


def _public_key_of_key(key_path: str) -> str:
    result = subprocess.run([asc.openssl(), "rsa", "-in", key_path, "-pubout"],
                            capture_output=True)
    return result.stdout.decode().strip() if result.returncode == 0 else ""


def _public_key_of_cert(der: bytes) -> str:
    """Read a DER certificate's public key.

    Via a temp file, not stdin: on Windows, piping binary DER through stdin
    fails with "Could not find certificate from <stdin>", and because that only
    shows on stderr it silently returns no match rather than an error.
    """
    handle = tempfile.NamedTemporaryFile(suffix=".cer", delete=False)
    handle.write(der)
    handle.close()
    try:
        result = subprocess.run(
            [asc.openssl(), "x509", "-inform", "DER", "-in", handle.name, "-noout", "-pubkey"],
            capture_output=True)
        return result.stdout.decode().strip() if result.returncode == 0 else ""
    finally:
        os.unlink(handle.name)


def existing_certificate(cert_type: str, key_path: str | None = None) -> dict | None:
    """Find a certificate of this type, preferring one our private key matches.

    A team can hold several distribution certificates — this one and another
    app's. Taking whichever comes back first would happily build a .p12 whose
    key and certificate disagree, and the failure only shows up later as an
    unhelpful codesign error.
    """
    query = urllib.parse.urlencode({"filter[certificateType]": cert_type, "limit": 200})
    certs = asc.get_all(f"/v1/certificates?{query}")
    if not certs:
        return None

    if key_path and os.path.exists(key_path):
        ours = _public_key_of_key(key_path)
        if not ours:
            raise SystemExit(f"could not read a public key out of {key_path}")
        for cert in certs:
            theirs = _public_key_of_cert(
                base64.b64decode(cert["attributes"]["certificateContent"]))
            if theirs and ours == theirs:
                return cert
        return None

    return certs[0]


def bundle_id_resource(bundle_id: str) -> dict:
    query = urllib.parse.urlencode({"filter[identifier]": bundle_id, "limit": 200})
    matches = [
        item for item in asc.get_all(f"/v1/bundleIds?{query}")
        if item["attributes"]["identifier"] == bundle_id
    ]
    if not matches:
        raise asc.ASCError(
            f"bundle id {bundle_id!r} is not registered in the Developer portal"
        )
    return matches[0]


def register_bundle_id(bundle_id: str, name: str) -> dict:
    body = {
        "data": {
            "type": "bundleIds",
            "attributes": {"identifier": bundle_id, "name": name, "platform": "IOS"},
        }
    }
    return asc.request("POST", "/v1/bundleIds", body)["data"]


def ensure_capability(bundle_ref: str, capability: str) -> bool:
    """Enable a capability on the bundle id. Returns True if it was just enabled."""
    existing = asc.get_all(f"/v1/bundleIds/{bundle_ref}/bundleIdCapabilities?limit=200")
    if any(c["attributes"].get("capabilityType") == capability for c in existing):
        return False
    body = {
        "data": {
            "type": "bundleIdCapabilities",
            "attributes": {"capabilityType": capability},
            "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle_ref}}},
        }
    }
    asc.request("POST", "/v1/bundleIdCapabilities", body)
    return True


def create_profile(name: str, bundle_ref: str, cert_ref: str) -> dict:
    """Recreate the profile each run so it always points at the current cert."""
    query = urllib.parse.urlencode({"filter[name]": name, "limit": 200})
    for profile in asc.get_all(f"/v1/profiles?{query}"):
        if profile["attributes"]["name"] == name:
            asc.request("DELETE", f"/v1/profiles/{profile['id']}")

    body = {
        "data": {
            "type": "profiles",
            "attributes": {"name": name, "profileType": "IOS_APP_STORE"},
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle_ref}},
                "certificates": {"data": [{"type": "certificates", "id": cert_ref}]},
            },
        }
    }
    return asc.request("POST", "/v1/profiles", body)["data"]


def build_p12(key_path: str, cert_der: bytes, p12_path: str, password: str) -> None:
    """Package key + certificate as a PKCS#12 the CI keychain can import."""
    cert_pem = os.path.join(OUT, "cert.pem")
    cert_der_path = os.path.join(OUT, "cert.cer")
    with open(cert_der_path, "wb") as handle:
        handle.write(cert_der)
    run([
        asc.openssl(), "x509", "-inform", "DER", "-in", cert_der_path,
        "-out", cert_pem, "-outform", "PEM",
    ])
    # macOS `security import` rejects an OpenSSL 3 default PKCS#12 with
    # "MAC verification failed" — it does not accept the newer PBKDF2/SHA-256
    # parameters. Pin the classic SHA1/3DES combination, which it does accept.
    run([
        asc.openssl(), "pkcs12", "-export",
        "-inkey", key_path, "-in", cert_pem,
        "-out", p12_path, "-name", "Heen distribution",
        "-keypbe", "PBE-SHA1-3DES",
        "-certpbe", "PBE-SHA1-3DES",
        "-macalg", "sha1",
        "-passout", f"pass:{password}",
    ])


def set_github_secrets(secrets: dict[str, str]) -> None:
    if not shutil.which("gh"):
        sys.exit("gh CLI not found — drop --set-github-secrets and add them by hand")
    for name, value in secrets.items():
        subprocess.run(["gh", "secret", "set", name], input=value, text=True, check=True)
        print(f"  set secret {name}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle-id", default="com.mashharawi.heen")
    parser.add_argument("--app-name", default="Heen", help="name for a newly registered bundle id")
    parser.add_argument("--register-bundle-id", action="store_true",
                        help="register the bundle id in the Developer portal if it is missing")
    parser.add_argument("--key-path",
                        help="private key of an existing distribution certificate to reuse (read-only)")
    parser.add_argument("--cert-type", default="IOS_DISTRIBUTION")
    parser.add_argument("--profile-name", default="Heen App Store")
    parser.add_argument("--p12-password", default=base64.b64encode(os.urandom(18)).decode())
    parser.add_argument("--force-new-cert", action="store_true",
                        help="issue a new certificate even though the team already has one")
    parser.add_argument("--set-github-secrets", action="store_true",
                        help="upload the results with `gh secret set`")
    args = parser.parse_args()

    try:
        asc.openssl()
    except asc.ASCError as error:
        sys.exit(str(error))
    os.makedirs(OUT, exist_ok=True)

    external_key = bool(args.key_path)
    key_path = os.path.abspath(args.key_path) if external_key else os.path.join(OUT, "private_key.pem")
    if external_key and not os.path.exists(key_path):
        sys.exit(f"--key-path does not exist: {key_path}")
    csr_path = os.path.join(OUT, "request.csr")
    p12_path = os.path.join(OUT, "distribution.p12")

    remote_cert = existing_certificate(args.cert_type, key_path)
    have_key = os.path.exists(key_path)

    if remote_cert and have_key and not args.force_new_cert:
        print(f"Reusing certificate {remote_cert['id']} with the key in {OUT}")
        cert = remote_cert
    else:
        if external_key:
            sys.exit(
                f"No {args.cert_type} certificate on the team matches {key_path}. "
                "Drop --key-path to create a new certificate with a fresh key in "
                f"{OUT} (that uses one of the team's certificate slots)."
            )
        if remote_cert and not args.force_new_cert:
            sys.exit(
                f"The team already has a {args.cert_type} certificate "
                f"({remote_cert['attributes'].get('name', remote_cert['id'])}) but its "
                f"private key is not in {OUT}, so it cannot be used here.\n"
                "Apple caps distribution certificates per team — revoking the old one "
                "breaks anything still signed with it. Re-run with --force-new-cert "
                "once you are sure the old certificate is unused."
            )
        print("Generating a private key and CSR locally...")
        csr = make_csr(key_path, csr_path, f"Heen ({args.bundle_id})")
        print("Asking App Store Connect to issue the certificate...")
        cert = create_certificate(csr, args.cert_type)
        print(f"  issued {cert['id']}")

    cert_der = base64.b64decode(cert["attributes"]["certificateContent"])
    build_p12(key_path, cert_der, p12_path, args.p12_password)
    print(f"Built {p12_path}")

    try:
        bundle_ref = bundle_id_resource(args.bundle_id)
    except asc.ASCError:
        if not args.register_bundle_id:
            raise
        print(f"Registering bundle id {args.bundle_id}...")
        bundle_ref = register_bundle_id(args.bundle_id, args.app_name)
    if ensure_capability(bundle_ref["id"], "PUSH_NOTIFICATIONS"):
        print("  enabled Push Notifications on the bundle id")

    print("Creating the App Store provisioning profile...")
    profile = create_profile(args.profile_name, bundle_ref["id"], cert["id"])
    profile_content = profile["attributes"]["profileContent"]
    profile_path = os.path.join(OUT, "Heen_AppStore.mobileprovision")
    with open(profile_path, "wb") as handle:
        handle.write(base64.b64decode(profile_content))
    print(f"  {profile['attributes']['name']} -> {profile_path}")

    with open(p12_path, "rb") as handle:
        p12_b64 = base64.b64encode(handle.read()).decode()

    secrets = {
        "IOS_DIST_P12_BASE64": p12_b64,
        "IOS_DIST_P12_PASSWORD": args.p12_password,
        "IOS_PROVISIONING_PROFILE_BASE64": profile_content,
    }

    if args.set_github_secrets:
        print("\nUploading GitHub secrets...")
        set_github_secrets(secrets)
    else:
        print("\nAdd these repository secrets (Settings > Secrets > Actions):")
        for name, value in secrets.items():
            preview = value if len(value) < 60 else value[:57] + "..."
            print(f"  {name} = {preview}")
        print(f"\nFull values are in {OUT} — re-run with --set-github-secrets to upload them.")

    print(
        f"\nKeep {key_path} safe and off GitHub: losing it means burning another "
        "of the team's certificate slots."
    )


if __name__ == "__main__":
    main()
