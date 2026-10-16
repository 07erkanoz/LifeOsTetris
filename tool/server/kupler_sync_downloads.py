#!/usr/bin/env python3
"""Mirrors the GitHub test-build release to lifeos.com.tr/kupler/indir/.

GitHub Actions builds the game and publishes it on the "test-build"
release; visitors download from lifeos.com.tr only. This script runs on the
server from cron (every 10 minutes), downloads whatever changed and writes
indir/latest.json, which the web page reads for the sizes and the date.

    python3 kupler_sync_downloads.py [--force]

Only the standard library. Safe to run often: unchanged files are skipped,
each file is downloaded next to its final name, checked against the size
GitHub reports and moved into place in one step, so a visitor never gets a
half-written APK. Files that leave the release are removed from the mirror.

If the repository becomes private, put a read-only GitHub token (contents:
read) in ~/.config/kupler-sync/token of the user that runs the script.
"""

import fcntl
import hashlib
import json
import os
import pathlib
import re
import sys
import time
import urllib.error
import urllib.request

REPO = '07erkanoz/LifeOsTetris'
TAG = 'test-build'
DEST = pathlib.Path(os.environ.get('KUPLER_DEST', '/var/www/vhosts/lifeos.com.tr/httpdocs/kupler/indir'))
PUBLIC = '/kupler/indir/'
TOKEN_FILE = pathlib.Path.home() / '.config/kupler-sync/token'
MANIFEST = DEST / 'latest.json'


def token():
    try:
        return TOKEN_FILE.read_text().strip() or None
    except OSError:
        return None


def headers(accept):
    h = {'Accept': accept, 'User-Agent': 'lifeos-kupler-sync', 'X-GitHub-Api-Version': '2022-11-28'}
    if t := token():
        h['Authorization'] = f'Bearer {t}'
    return h


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def release():
    url = f'https://api.github.com/repos/{REPO}/releases/tags/{TAG}'
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers('application/vnd.github+json')), timeout=30) as r:
        return json.load(r)


def download(asset, target):
    """Downloads one asset. The API answers with a redirect to a signed
    storage URL, which must be fetched without the GitHub token."""
    req = urllib.request.Request(asset['url'], headers=headers('application/octet-stream'))
    opener = urllib.request.build_opener(_NoRedirect)
    try:
        res = opener.open(req, timeout=60)
    except urllib.error.HTTPError as e:
        if e.code not in (301, 302, 303, 307, 308):
            raise
        res = urllib.request.urlopen(urllib.request.Request(e.headers['Location'], headers={'User-Agent': 'lifeos-kupler-sync'}), timeout=60)
    tmp = target.with_name(f'.{target.name}.part')
    sha = hashlib.sha256()
    size = 0
    with res, open(tmp, 'wb') as f:
        while chunk := res.read(1 << 20):
            f.write(chunk)
            sha.update(chunk)
            size += len(chunk)
    if size != asset['size']:
        tmp.unlink(missing_ok=True)
        raise RuntimeError(f'{asset["name"]}: got {size} bytes, GitHub says {asset["size"]}')
    os.chmod(tmp, 0o644)
    os.replace(tmp, target)
    return sha.hexdigest()


def write_json(path, data):
    tmp = path.with_name(f'.{path.name}.part')
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    os.chmod(tmp, 0o644)
    os.replace(tmp, path)


def version_of(rel):
    """"1.0.0-39" from a release named "Test sürümü 1.0.0-39 (abc1234)";
    the commit for older releases without a number."""
    name = rel.get('name') or ''
    m = re.search(r'(\d+\.\d+\.\d+-\d+)', name) or re.search(r'\(([0-9a-f]{7,})\)', name)
    return m.group(1) if m else (rel.get('target_commitish') or 'dev')[:7]


def versioned(name, version):
    """LifeOS-Kupler-arm64.apk -> LifeOS-Kupler-arm64-1.0.0-39.apk"""
    for ext in ('.tar.gz', '.apk', '.zip'):
        if name.endswith(ext):
            return f'{name[:-len(ext)]}-{version}{ext}'
    return f'{name}-{version}'


def link(src, alias):
    """Points the fixed name (README, PKGBUILD) at the newest file."""
    tmp = alias.with_name(f'.{alias.name}.link')
    tmp.unlink(missing_ok=True)
    os.link(src, tmp)
    os.replace(tmp, alias)


def main(force=False):
    DEST.mkdir(parents=True, exist_ok=True)
    with open(DEST / '.sync.lock', 'w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return  # the previous run is still downloading
        try:
            old = {a['name']: a for a in json.loads(MANIFEST.read_text())['assets']}
        except (OSError, ValueError, KeyError):
            old = {}
        rel = release()
        version = version_of(rel)
        assets, changed = [], []
        for a in sorted(rel['assets'], key=lambda a: a['name']):
            if a['state'] != 'uploaded' or '/' in a['name'] or a['name'].startswith('.'):
                continue
            # Every build is saved under its own name, so no cache (phone,
            # browser, Cloudflare) can hand out an older file in its place.
            file = versioned(a['name'], version)
            target = DEST / file
            prev = old.get(a['name'])
            if not force and prev and prev.get('id') == a['id'] and prev.get('updated_at') == a['updated_at'] and prev.get('file') == file and target.exists():
                sha = prev['sha256']
            else:
                sha = download(a, target)
                changed.append(file)
            link(target, DEST / a['name'])
            assets.append({'name': a['name'], 'file': file, 'size': a['size'], 'sha256': sha, 'updated_at': a['updated_at'],
                           'id': a['id'], 'url': PUBLIC + file})
        # Keep this build and the one before it (a page opened earlier may
        # still link to it); older builds go.
        keep = {a['file'] for a in assets} | {a.get('file') for a in old.values()} | {a['name'] for a in assets} | {'latest.json'}
        removed = []
        for f in DEST.iterdir():
            if f.name.startswith('.') or not f.is_file() or f.name in keep:
                continue
            if f.name.startswith('LifeOS-Kupler'):
                f.unlink()
                removed.append(f.name)
        if changed or removed or not MANIFEST.exists():
            write_json(MANIFEST, {
                'release': rel.get('name'),
                'version': version,
                'commit': rel.get('target_commitish'),
                'updated': max((a['updated_at'] for a in assets), default=None),
                'synced': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                'assets': assets,
            })
            print(time.strftime('%F %T'), rel.get('name'), 'updated:', ', '.join(changed) or '-', 'removed:', ', '.join(removed) or '-', flush=True)



if __name__ == '__main__':
    try:
        main(force='--force' in sys.argv)
    except Exception as e:  # cron mails/logs this line; the old files stay online
        sys.exit(f'{time.strftime("%F %T")} kupler sync failed: {e}')
