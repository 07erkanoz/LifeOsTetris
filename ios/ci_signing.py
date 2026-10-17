#!/usr/bin/env python3
"""App Store signing for CI without a Mac or stored certificates.

`setup` signs with one Apple Distribution certificate kept between runs:
its private key and certificate sit in ~/ios-signing (the workflow caches
that folder) as a .p12 locked with a password made from the API key, so only
a run holding the API key can open it. When there is none yet (or it has
expired or been revoked) it creates one through the App Store Connect API;
when Apple's limit of certificates is reached it first revokes the oldest
one this workflow made. It then finds or makes the App Store profile, installs
both on the runner and switches the Runner target to manual signing.
`cleanup` only removes them from the runner. The certificate is never
revoked after a build: that would make the builds signed with it invalid
(TestFlight expires them, App Review rejects them with ITMS-90035).

Needs ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH (the .p8 file). Only the
Python standard library and the system openssl/security tools are used.
"""

import base64
import datetime
import hashlib
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
# The kept certificate, between runs (the workflow caches this folder).
KEEP = pathlib.Path.home() / 'ios-signing'
# The common name of the certificates this workflow makes.
CI_NAME = 'LifeOS Kupler CI'


class ApiError(Exception):
    def __init__(self, code: int, text: str):
        super().__init__(f'{code} {text}')
        self.code = code


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


def api(method: str, path: str, body=None, check=True):
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
        text = e.read().decode()
        if not check:
            raise ApiError(e.code, text)
        sys.exit(f'App Store Connect API {method} {path} failed: {e.code} {text}')


def run(*cmd, **kw):
    return subprocess.run(cmd, check=True, **kw)


def ci_profiles():
    """The App Store profiles this workflow made, with their certificates."""
    profiles = api('GET', '/profiles?filter[profileType]=IOS_APP_STORE&include=certificates&limit=200')['data']
    return [p for p in profiles if p['attributes']['name'].startswith(CI_NAME)]


def profile_certs(p):
    return {c['id'] for c in (p.get('relationships', {}).get('certificates', {}).get('data') or [])}


def ci_certificates():
    """The distribution certificates this workflow made (they are the ones
    its profiles hold; Apple names the certificates itself), oldest first."""
    ours = set().union(*[profile_certs(p) for p in ci_profiles()])
    certs = api('GET', '/certificates?filter[certificateType]=DISTRIBUTION&limit=200')['data']
    print(f'Distribution certificates: {len(certs)}, made here: {len([c for c in certs if c["id"] in ours])}')
    return sorted([c for c in certs if c['id'] in ours], key=lambda c: c['attributes']['expirationDate'])


def password() -> str:
    """The password of the kept certificate: from the API key, so only a run
    that has the key can open it."""
    return hashlib.sha256(pathlib.Path(os.environ['ASC_KEY_PATH']).read_bytes() + b'/kupler-signing').hexdigest()


def kept():
    """The kept certificate's id and its .p12, when it is still valid."""
    meta, p12 = KEEP / 'cert.json', KEEP / 'dist.p12'
    if not meta.exists() or not p12.exists():
        print('No kept certificate yet')
        return None
    cert_id = json.loads(meta.read_text())['id']
    try:
        cert = api('GET', f'/certificates/{cert_id}', check=False)['data']
    except ApiError as e:
        print(f'The kept certificate {cert_id} is gone ({e.code})')
        return None
    expires = datetime.datetime.fromisoformat(cert['attributes']['expirationDate'].replace('Z', '+00:00'))
    if expires - datetime.datetime.now(datetime.timezone.utc) < datetime.timedelta(days=14):
        print(f'The kept certificate {cert_id} expires soon ({expires:%Y-%m-%d})')
        return None
    print(f'Signing with the kept certificate {cert_id} (until {expires:%Y-%m-%d})')
    return cert, p12


def fresh():
    """A new certificate, kept for the next runs."""
    key, csr = WORK / 'dist.key', WORK / 'dist.csr'
    run(OPENSSL, 'req', '-new', '-newkey', 'rsa:2048', '-nodes', '-keyout', str(key), '-out', str(csr),
        '-subj', f'/CN={CI_NAME}/C=TR')
    csr_text = ''.join(l for l in csr.read_text().splitlines() if 'CERTIFICATE REQUEST' not in l)

    def create():
        return api('POST', '/certificates', {'data': {'type': 'certificates', 'attributes': {
            'certificateType': 'DISTRIBUTION', 'csrContent': csr_text}}}, check=False)['data']

    try:
        cert = create()
    except ApiError as e:
        # Apple allows only a few distribution certificates: make room by
        # revoking the oldest one made here.
        old = ci_certificates()
        if e.code != 409 or not old:
            sys.exit(f'Could not create a distribution certificate (none made here to make room): {e}')
        revoke(old[0])
        cert = create()
    # The .p12 is itself encrypted with the password: it is what is kept.
    KEEP.mkdir(parents=True, exist_ok=True)
    der, pem, p12 = WORK / 'dist.cer', WORK / 'dist.pem', KEEP / 'dist.p12'
    der.write_bytes(base64.b64decode(cert['attributes']['certificateContent']))
    run(OPENSSL, 'x509', '-inform', 'DER', '-in', str(der), '-out', str(pem))
    run(OPENSSL, 'pkcs12', '-export', '-inkey', str(key), '-in', str(pem), '-out', str(p12), '-passout', f'pass:{password()}')
    (KEEP / 'cert.json').write_text(json.dumps({'id': cert['id']}))
    key.unlink()
    print(f'New certificate {cert["id"]}, kept for the next runs')
    return cert, p12


def revoke(cert):
    """Revokes [cert] and deletes the App Store profiles made with it."""
    profiles = api('GET', '/profiles?filter[profileType]=IOS_APP_STORE&include=certificates&limit=200')['data']
    for p in profiles:
        certs = p.get('relationships', {}).get('certificates', {}).get('data') or []
        if p['attributes']['name'].startswith(CI_NAME) and any(c['id'] == cert['id'] for c in certs):
            api('DELETE', f'/profiles/{p["id"]}')
    api('DELETE', f'/certificates/{cert["id"]}')
    print(f'Revoked the oldest CI certificate {cert["id"]} (expires {cert["attributes"]["expirationDate"][:10]})')


def setup():
    WORK.mkdir(parents=True, exist_ok=True)
    cert, p12 = kept() or fresh()
    p12_pass = password()
    state = {'certificate': cert['id']}
    STATE.write_text(json.dumps(state))

    # Signing identity in a throwaway keychain.
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

    # The profile: one made here for this certificate, or a new one.
    profile = next((p for p in ci_profiles() if p['attributes'].get('profileState') == 'ACTIVE' and profile_certs(p) == {cert['id']}), None)
    if profile is None:
        bundles = api('GET', f'/bundleIds?filter[identifier]={BUNDLE_ID}')['data']
        bundle = next(b for b in bundles if b['attributes']['identifier'] == BUNDLE_ID)
        profile = api('POST', '/profiles', {'data': {
            'type': 'profiles',
            'attributes': {'name': f'{CI_NAME} {int(time.time())}', 'profileType': 'IOS_APP_STORE'},
            'relationships': {
                'bundleId': {'data': {'type': 'bundleIds', 'id': bundle['id']}},
                'certificates': {'data': [{'type': 'certificates', 'id': cert['id']}]},
            },
        }})['data']
    name = profile['attributes']['name']
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
    """Removes the signing identity from the runner. The certificate and the
    profile stay on the account: the uploaded build is signed with them."""
    if not STATE.exists():
        return
    state = json.loads(STATE.read_text())
    if 'keychain' in state:
        subprocess.run(['security', 'delete-keychain', state['keychain']], check=False)
    subprocess.run(['rm', '-rf', str(WORK)], check=False)
    print('Signing identity removed from the runner')


if __name__ == '__main__':
    {'setup': setup, 'cleanup': cleanup}[sys.argv[1]]()
