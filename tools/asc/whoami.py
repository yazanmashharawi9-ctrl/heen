#!/usr/bin/env python3
"""Confirm the App Store Connect credentials work, and show what they can see.

    python tools/asc/whoami.py
"""

import sys

import asc


def main() -> None:
    try:
        apps = asc.get_all("/v1/apps?limit=200")
    except asc.ASCError as error:
        sys.exit(f"Could not reach App Store Connect:\n{error}")

    if not apps:
        print("Authenticated, but this key can't see any apps.")
        print("Check the key's role (App Manager or Admin) in Users and Access.")
        return

    print(f"Authenticated. {len(apps)} app(s) visible:\n")
    for app in apps:
        attrs = app["attributes"]
        print(f"  {attrs.get('name')}")
        print(f"    bundle id : {attrs.get('bundleId')}")
        print(f"    sku       : {attrs.get('sku')}")
        print(f"    locale    : {attrs.get('primaryLocale')}")
        print(f"    id        : {app['id']}\n")

    try:
        certs = asc.get_all("/v1/certificates?limit=200")
        print(f"Certificates on the team: {len(certs)}")
        for cert in certs:
            a = cert["attributes"]
            print(f"  {a.get('certificateType'):<22} {a.get('name')}  expires {a.get('expirationDate', '?')[:10]}")
    except asc.ASCError as error:
        print(f"(could not list certificates: {error})")


if __name__ == "__main__":
    main()
