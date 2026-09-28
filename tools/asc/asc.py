"""Minimal App Store Connect API client.

Standard library + the `openssl` CLI only — no pip installs, so the same code
runs here on Windows and on the macOS CI runner without a bootstrap step.

Credentials come from the environment (see tools/asc/README.md):
  ASC_KEY_ID     the 10-character key ID
  ASC_ISSUER_ID  the team's issuer UUID
  ASC_KEY_PATH   path to the AuthKey_<id>.p8 file, or
  ASC_KEY_B64    the .p8 contents, base64-encoded (used in CI)
"""

from __future__ import annotations

import base64
import json
import os
import shutil
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://api.appstoreconnect.apple.com"

_ENV_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")


def _load_env_file() -> None:
    """Read tools/asc/.env so the credentials don't have to be exported every
    time, in every shell. Real environment variables still win."""
    if not os.path.exists(_ENV_FILE):
        return
    with open(_ENV_FILE, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip("'\""))


_load_env_file()


def openssl() -> str:
    """Locate the openssl binary.

    Git for Windows ships openssl but does not add it to PATH, so a bare
    "openssl" works in Git Bash and dies in PowerShell with a FileNotFoundError
    that never mentions what was actually missing.
    """
    found = shutil.which("openssl")
    if found:
        return found

    candidates = [
        "C:/Program Files/Git/usr/bin/openssl.exe",
        "C:/Program Files (x86)/Git/usr/bin/openssl.exe",
        "C:/Program Files/OpenSSL-Win64/bin/openssl.exe",
    ]
    for candidate in candidates:
        if os.path.exists(candidate):
            return candidate

    raise ASCError(
        "openssl was not found on PATH. Git for Windows ships it at "
        "'C:/Program Files/Git/usr/bin/openssl.exe' — add that folder to PATH, "
        "or run these tools from Git Bash."
    )


class ASCError(RuntimeError):
    """An error response from App Store Connect, with Apple's detail text."""


def _b64url(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def _der_to_raw(der: bytes, size: int = 32) -> bytes:
    """Convert an OpenSSL ECDSA signature (DER SEQUENCE) to JOSE r||s form."""
    if der[0] != 0x30:
        raise ValueError("signature is not a DER SEQUENCE")
    idx = 2 + (der[1] & 0x7F if der[1] & 0x80 else 0)

    def read_int(i: int) -> tuple[bytes, int]:
        if der[i] != 0x02:
            raise ValueError("expected a DER INTEGER in the signature")
        length = der[i + 1]
        value = der[i + 2 : i + 2 + length]
        return value.lstrip(b"\x00").rjust(size, b"\x00"), i + 2 + length

    r, idx = read_int(idx)
    s, _ = read_int(idx)
    return r + s


def _key_path() -> str:
    """Resolve the .p8 private key, materializing ASC_KEY_B64 if that's what we got."""
    path = os.environ.get("ASC_KEY_PATH")
    if path:
        if not os.path.exists(path):
            raise ASCError(f"ASC_KEY_PATH points at a file that doesn't exist: {path}")
        return path

    encoded = os.environ.get("ASC_KEY_B64")
    if not encoded:
        raise ASCError("set ASC_KEY_PATH or ASC_KEY_B64 (see tools/asc/README.md)")

    handle = tempfile.NamedTemporaryFile(suffix=".p8", delete=False)
    handle.write(base64.b64decode(encoded))
    handle.close()
    os.chmod(handle.name, 0o600)
    return handle.name


def make_jwt(ttl_seconds: int = 900) -> str:
    """Build an ES256 JWT.

    Apple rejects any token whose `exp` is more than 20 minutes ahead of *its*
    clock, so asking for the full 20 fails as soon as the local clock runs even
    a few seconds fast. We ask for 15 and backdate `iat` by a minute, which
    absorbs ordinary skew in both directions.
    """
    key_id = os.environ.get("ASC_KEY_ID")
    issuer_id = os.environ.get("ASC_ISSUER_ID")
    if not key_id or not issuer_id:
        raise ASCError("set ASC_KEY_ID and ASC_ISSUER_ID (see tools/asc/README.md)")

    now = int(time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {
        "iss": issuer_id,
        "iat": now - 60,
        "exp": now + ttl_seconds,
        "aud": "appstoreconnect-v1",
    }
    signing_input = (
        _b64url(json.dumps(header, separators=(",", ":")).encode())
        + "."
        + _b64url(json.dumps(payload, separators=(",", ":")).encode())
    ).encode()

    signed = subprocess.run(
        [openssl(), "dgst", "-sha256", "-sign", _key_path(), "-binary"],
        input=signing_input,
        capture_output=True,
        check=True,
    )
    return signing_input.decode() + "." + _b64url(_der_to_raw(signed.stdout))


def request(method: str, path: str, body: dict | None = None, *, raw: bool = False):
    """Call the App Store Connect API. `path` may be a bare path or a full URL."""
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", "Bearer " + make_jwt())
    if data:
        req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req) as response:
            payload = response.read()
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")
        try:
            errors = json.loads(detail).get("errors", [])
            detail = "\n".join(
                f"  - {e.get('title', '?')}: {e.get('detail', '')}" for e in errors
            ) or detail
        except json.JSONDecodeError:
            pass
        raise ASCError(f"{method} {url} -> HTTP {error.code}\n{detail}") from None

    if raw:
        return payload
    return json.loads(payload) if payload else {}


def get_all(path: str) -> list[dict]:
    """GET a collection, following Apple's cursor pagination to the end."""
    items: list[dict] = []
    url = path
    while url:
        page = request("GET", url)
        items.extend(page.get("data", []))
        url = page.get("links", {}).get("next")
    return items


def find_app(bundle_id: str) -> dict:
    """Look up the app record by bundle identifier."""
    query = urllib.parse.urlencode({"filter[bundleId]": bundle_id, "limit": 200})
    apps = get_all(f"/v1/apps?{query}")
    if not apps:
        raise ASCError(
            f"no app in App Store Connect with bundle id {bundle_id!r}. "
            "Check that the key's team owns the app record."
        )
    return apps[0]
