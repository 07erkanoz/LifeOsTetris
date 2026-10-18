#!/usr/bin/env python3
"""Google Play listing and releases from android/metadata/, through the API.

  status                         the tracks and their releases
  listing                        texts, video, icon, feature graphic and
                                 screenshots of every language
  release AAB [--track T] [--status S] [--notes TEXT]
                                 uploads the app bundle and puts it on track T
                                 (internal by default) with status S
                                 (completed; draft while the app is a draft)

Needs PLAY_SERVICE_ACCOUNT_JSON: the service account key (a GitHub secret),
whose account has access to the app in Play Console. Every step reports on
its own, like ios/app_store.py; changes go into one edit, committed at the end.
Only the standard library and the system openssl are used.
"""

import base64
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

PACKAGE = 'com.lifeos.lifeos_kupler'
API = f'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}'
UPLOAD = f'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACKAGE}'
HERE = pathlib.Path(__file__).resolve().parent
META = HERE / 'metadata'
LISTING = json.loads((META / 'listing.json').read_text(encoding='utf-8'))
# Play's locale names for ours.
LANGUAGES = {'tr': 'tr-TR', 'en-US': 'en-US'}
# Screenshot file prefix → Play's image type; Play takes eight of each.
SHOT_TYPES = {'phone': 'phoneScreenshots', 'tablet7': 'sevenInchScreenshots', 'tablet10': 'tenInchScreenshots'}
MAX_SHOTS = 8

_failed = []
_token = None


class ApiError(Exception):
    pass


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def token() -> str:
    """An access token for the service account (a signed JWT exchanged at
    Google's token endpoint), kept for the run."""
    global _token
    if _token:
        return _token
    key = json.loads(os.environ['PLAY_SERVICE_ACCOUNT_JSON'])
    now = int(time.time())
    header = {'alg': 'RS256', 'typ': 'JWT'}
    claims = {'iss': key['client_email'], 'scope': 'https://www.googleapis.com/auth/androidpublisher',
              'aud': key['token_uri'], 'iat': now, 'exp': now + 3600}
    signing_input = f'{b64url(json.dumps(header).encode())}.{b64url(json.dumps(claims).encode())}'.encode()
    with tempfile.NamedTemporaryFile('w', suffix='.pem', delete=False) as f:
        f.write(key['private_key'])
        pem = f.name
    try:
        os.chmod(pem, 0o600)
        sig = subprocess.run(['openssl', 'dgst', '-sha256', '-sign', pem], input=signing_input, capture_output=True, check=True).stdout
    finally:
        os.remove(pem)
    body = urllib.parse.urlencode({'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                                   'assertion': f'{signing_input.decode()}.{b64url(sig)}'}).encode()
    with urllib.request.urlopen(urllib.request.Request(key['token_uri'], data=body, method='POST')) as res:
        _token = json.loads(res.read())['access_token']
    return _token


def call(method, url, body=None, data=None, content_type='application/json'):
    req = urllib.request.Request(
        url if url.startswith('https://') else API + url,
        method=method,
        data=data if data is not None else (None if body is None else json.dumps(body).encode()),
        headers={'Authorization': f'Bearer {token()}', 'Content-Type': content_type},
    )
    try:
        with urllib.request.urlopen(req, timeout=600) as res:
            raw = res.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        detail = e.read().decode()
        try:
            detail = json.loads(detail)['error']['message']
        except (ValueError, KeyError, TypeError):
            pass
        raise ApiError(f'{method} {url.split(PACKAGE)[-1]} → {e.code} {detail}') from None


def step(name, fn, *args):
    try:
        note = fn(*args)
        print(f'✓ {name}' + (f': {note}' if note else ''), flush=True)
        return note
    except (ApiError, OSError, KeyError, ValueError) as e:
        print(f'✗ {name}: {e}', flush=True)
        _failed.append(name)
        return None


def finish():
    if _failed:
        sys.exit(f'{len(_failed)} step(s) failed: {", ".join(_failed)}')


class Edit:
    """One Play edit: everything changes inside it, then one commit."""

    def __init__(self):
        self.id = call('POST', '/edits', {})['id']

    def url(self, path=''):
        return f'/edits/{self.id}{path}'

    def upload_url(self, path):
        return f'{UPLOAD}/edits/{self.id}{path}?uploadType=media'

    def commit(self):
        try:
            call('POST', self.url(':commit'))
        except ApiError as e:
            # Some changes go to review on their own; Play then asks for this.
            if 'changesNotSentForReview' not in str(e):
                raise
            call('POST', self.url(':commit?changesNotSentForReview=true'))

    def abandon(self):
        try:
            call('DELETE', self.url())
        except ApiError:
            pass


def texts(edit, loc, play):
    t = LISTING['locales'][loc]
    body = {'language': play, 'title': t['title'], 'shortDescription': t['shortDescription'], 'fullDescription': t['fullDescription']}
    if t.get('video'):
        body['video'] = t['video']
    call('PUT', edit.url(f'/listings/{play}'), body)
    return f'{len(t["title"])}/30, {len(t["shortDescription"])}/80, {len(t["fullDescription"])}/4000' + (', video' if t.get('video') else '')


def images(edit, play, kind, files):
    """Replaces every image of [kind] in [play] with [files], in order."""
    call('DELETE', edit.url(f'/listings/{play}/{kind}'))
    for f in files:
        call('POST', edit.upload_url(f'/listings/{play}/{kind}'), data=f.read_bytes(), content_type='image/png')
    return f'{len(files)} uploaded'


def listing():
    edit = Edit()
    try:
        for loc, play in LANGUAGES.items():
            step(f'Texts ({play})', texts, edit, loc, play)
            step(f'Icon ({play})', images, edit, play, 'icon', [META / 'icon-512.png'])
            step(f'Feature graphic ({play})', images, edit, play, 'featureGraphic', [META / loc / 'feature-graphic.png'])
            shots = META / 'screenshots' / loc
            for prefix, kind in SHOT_TYPES.items():
                files = sorted(shots.glob(f'{prefix}-*.png'))[:MAX_SHOTS]
                step(f'Screenshots {prefix} ({play})', images, edit, play, kind, files)
        if _failed:
            edit.abandon()
            print('Nothing committed: fix the steps above and run again.')
        else:
            step('Commit', edit.commit)
    except ApiError as e:
        edit.abandon()
        print(f'✗ {e}')
        _failed.append('listing')
    finish()


def release(aab, track='internal', status='completed', notes=None):
    edit = Edit()
    try:
        bundle = call('POST', edit.upload_url('/bundles'), data=pathlib.Path(aab).read_bytes(), content_type='application/octet-stream')
        code = bundle['versionCode']
        print(f'✓ App bundle: version code {code}', flush=True)
        text = notes or 'Yeni test sürümü.'
        rel = {'versionCodes': [str(code)], 'status': status,
               'releaseNotes': [{'language': 'tr-TR', 'text': text}, {'language': 'en-US', 'text': notes or 'A new test build.'}]}
        call('PUT', edit.url(f'/tracks/{track}'), {'track': track, 'releases': [rel]})
        print(f'✓ Track {track}: {code} ({status})', flush=True)
        edit.commit()
        print('✓ Commit', flush=True)
    except ApiError as e:
        edit.abandon()
        print(f'✗ Release: {e}', flush=True)
        _failed.append('release')
    finish()


def status():
    edit = Edit()
    try:
        for t in call('GET', edit.url('/tracks')).get('tracks', []):
            releases = t.get('releases') or []
            line = ', '.join(f'{r.get("name", "?")} {r.get("versionCodes", [])} {r.get("status")}' for r in releases) or 'no release'
            print(f'  {t["track"]}: {line}')
        for loc, play in LANGUAGES.items():
            try:
                l = call('GET', edit.url(f'/listings/{play}'))
                print(f'  listing {play}: {l.get("title")}')
            except ApiError:
                print(f'  listing {play}: none')
    finally:
        edit.abandon()


if __name__ == '__main__':
    args = sys.argv[1:]
    if not args or args[0] not in {'status', 'listing', 'release'}:
        sys.exit(__doc__)
    if args[0] == 'status':
        status()
    elif args[0] == 'listing':
        listing()
    else:
        opts = {k.lstrip('-'): v for k, v in zip(args[2::2], args[3::2])}
        release(args[1], track=opts.get('track', 'internal'), status=opts.get('status', 'completed'), notes=opts.get('notes'))
