#!/usr/bin/env python3
"""App Store signing for CI without a Mac or stored certificates.

`setup` creates a short-lived Apple Distribution certificate and an App Store
provisioning profile through the App Store Connect API, installs both on the
runner and switches the Runner target to manual signing with them.
`cleanup` deletes the profile and revokes the certificate again; builds that
were already uploaded are not affected (the App Store re-signs them).

Needs ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH (the .p8 file). Only the
Python standard library and the system openssl/security tools are used.
"""

import base64
import json
import os
import pathlib
import plistlib
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.request

API = 'https://api.appstoreconnect.apple.com/v1'
BUNDLE_ID = 'com.erkanoz.kupler'
TEAM_ID = '8PYZ45XP74'
OPENSSL = '/usr/bin/openssl'
WORK = pathlib.Path(os.environ.get('RUNNER_TEMP', '/tmp')) / 'signing'
STATE = WORK / 'state.json'


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def der_to_raw(sig: bytes) -> bytes:
    """ECDSA DER signature → 64-byte r||s, as JWT ES256 wants."""
    assert sig[0] == 0x30
    i = 2
    parts = []
    for _ in range(2):
        assert sig[i] == 0x02
        n = sig[i + 1]
        parts.append(sig[i + 2:i + 2 + n].lstrip(b'\0').rjust(32, b'\0'))
        i += 2 + n
    return parts[0] + parts[1]


def token() -> str:
    header = {'alg': 'ES256', 'kid': os.environ['ASC_KEY_ID'], 'typ': 'JWT'}
    now = int(time.time())
    claims = {'iss': os.environ['ASC_ISSUER_ID'], 'iat': now, 'exp': now + 1200, 'aud': 'appstoreconnect-v1'}
    signing_input = f'{b64url(json.dumps(header).encode())}.{b64url(json.dumps(claims).encode())}'.encode()
    sig = subprocess.run(
        [OPENSSL, 'dgst', '-sha256', '-sign', os.environ['ASC_KEY_PATH']],
        input=signing_input, capture_output=True, check=True,
    ).stdout
    return f'{signing_input.decode()}.{b64url(der_to_raw(sig))}'


def api(method: str, path: str, body=None):
    req = urllib.request.Request(
        API + path,
        method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={'Authorization': f'Bearer {token()}', 'Content-Type': 'application/json'},
    )
    try:
        with urllib.request.urlopen(req) as res:
            raw = res.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        sys.exit(f'App Store Connect API {method} {path} failed: {e.code} {e.read().decode()}')


def run(*cmd, **kw):
    return subprocess.run(cmd, check=True, **kw)


def setup():
    WORK.mkdir(parents=True, exist_ok=True)
    key, csr = WORK / 'dist.key', WORK / 'dist.csr'
    run(OPENSSL, 'req', '-new', '-newkey', 'rsa:2048', '-nodes', '-keyout', str(key), '-out', str(csr),
        '-subj', '/CN=LifeOS Kupler CI/C=TR')
    csr_text = ''.join(l for l in csr.read_text().splitlines() if 'CERTIFICATE REQUEST' not in l)

    cert = api('POST', '/certificates', {'data': {'type': 'certificates', 'attributes': {
        'certificateType': 'DISTRIBUTION', 'csrContent': csr_text}}})['data']
    state = {'certificate': cert['id']}
    STATE.write_text(json.dumps(state))
    der = WORK / 'dist.cer'
    der.write_bytes(base64.b64decode(cert['attributes']['certificateContent']))

    # Signing identity in a throwaway keychain.
    pem, p12 = WORK / 'dist.pem', WORK / 'dist.p12'
    run(OPENSSL, 'x509', '-inform', 'DER', '-in', str(der), '-out', str(pem))
    p12_pass = secrets.token_hex(12)
    run(OPENSSL, 'pkcs12', '-export', '-inkey', str(key), '-in', str(pem), '-out', str(p12), '-passout', f'pass:{p12_pass}')
    keychain = str(WORK / 'ci.keychain-db')
    kc_pass = secrets.token_hex(12)
    run('security', 'create-keychain', '-p', kc_pass, keychain)
    run('security', 'set-keychain-settings', '-lut', '21600', keychain)
    run('security', 'unlock-keychain', '-p', kc_pass, keychain)
    existing = subprocess.run(['security', 'list-keychains', '-d', 'user'], capture_output=True, text=True, check=True).stdout
    run('security', 'list-keychains', '-d', 'user', '-s', keychain, *[k.strip().strip('"') for k in existing.split()])
    run('security', 'import', str(p12), '-k', keychain, '-P', p12_pass, '-T', '/usr/bin/codesign', '-T', '/usr/bin/security')
    run('security', 'set-key-partition-list', '-S', 'apple-tool:,apple:,codesign:', '-s', '-k', kc_pass, keychain,
        stdout=subprocess.DEVNULL)
    state['keychain'] = keychain
    STATE.write_text(json.dumps(state))

    bundles = api('GET', f'/bundleIds?filter[identifier]={BUNDLE_ID}')['data']
    bundle = next(b for b in bundles if b['attributes']['identifier'] == BUNDLE_ID)
    name = f'LifeOS Kupler CI {int(time.time())}'
    profile = api('POST', '/profiles', {'data': {
        'type': 'profiles',
        'attributes': {'name': name, 'profileType': 'IOS_APP_STORE'},
        'relationships': {
            'bundleId': {'data': {'type': 'bundleIds', 'id': bundle['id']}},
            'certificates': {'data': [{'type': 'certificates', 'id': cert['id']}]},
        },
    }})['data']
    state['profile'] = profile['id']
    STATE.write_text(json.dumps(state))
    content = base64.b64decode(profile['attributes']['profileContent'])
    uuid = profile['attributes']['uuid']
    home = pathlib.Path.home()
    for folder in (home / 'Library/MobileDevice/Provisioning Profiles', home / 'Library/Developer/Xcode/UserData/Provisioning Profiles'):
        folder.mkdir(parents=True, exist_ok=True)
        (folder / f'{uuid}.mobileprovision').write_bytes(content)

    # Manual signing for the Runner target only (the plugin frameworks are
    # re-signed when they are embedded).
    pbx = pathlib.Path('ios/Runner.xcodeproj/project.pbxproj')
    line = f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};\n'
    text = pbx.read_text()
    assert text.count(line) == 3, 'Runner build configurations not found'
    pbx.write_text(text.replace(line, line + (
        '\t\t\t\tCODE_SIGN_STYLE = Manual;\n'
        '\t\t\t\tCODE_SIGN_IDENTITY = "Apple Distribution";\n'
        '\t\t\t\t"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";\n'
        f'\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "{name}";\n'
    )))

    export = WORK / 'ExportOptions.plist'
    export.write_bytes(plistlib.dumps({
        'method': 'app-store-connect',
        'destination': 'upload',
        'teamID': TEAM_ID,
        'signingStyle': 'manual',
        'signingCertificate': 'Apple Distribution',
        'provisioningProfiles': {BUNDLE_ID: name},
        'uploadSymbols': True,
        'manageAppVersionAndBuildNumber': False,
    }))
    with open(os.environ['GITHUB_ENV'], 'a') as env:
        env.write(f'EXPORT_OPTIONS={export}\n')
    print(f'Signing ready: certificate {cert["id"]}, profile "{name}"')


def cleanup():
    if not STATE.exists():
        return
    state = json.loads(STATE.read_text())
    if 'profile' in state:
        api('DELETE', f'/profiles/{state["profile"]}')
    if 'certificate' in state:
        api('DELETE', f'/certificates/{state["certificate"]}')
    if 'keychain' in state:
        subprocess.run(['security', 'delete-keychain', state['keychain']], check=False)
    subprocess.run(['rm', '-rf', str(WORK)], check=False)
    print('Temporary certificate and profile removed')


if __name__ == '__main__':
    {'setup': setup, 'cleanup': cleanup}[sys.argv[1]]()
