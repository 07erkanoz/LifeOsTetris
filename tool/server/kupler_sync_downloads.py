#!/usr/bin/env python3
"""Mirrors the GitHub test-build release to lifeos.com.tr/kupler/indir/
and the browser version to lifeos.com.tr/kupler/oyna/.

GitHub Actions builds the game and publishes it on the "test-build"
release; visitors download from lifeos.com.tr only. This script runs on the
server from cron (every 10 minutes), downloads whatever changed and writes
indir/latest.json, which the web page reads for the sizes and the date.

    python3 kupler_sync_downloads.py [--force]

Only the standard library. Safe to run often: unchanged files are skipped,
each file is downloaded next to its final name, checked against the size
GitHub reports and moved into place in one step, so a visitor never gets a
half-written APK. Files that leave the release are removed from the mirror.

The browser version (LifeOS-Kupler-Web.zip) is not offered for download: it
is unpacked into oyna/v<version>-<sha>/, a folder of its own whose files
never change, and oyna/index.html, the only file that keeps its name, is
then pointed at it in one step. A browser therefore loads either the old
build or the new one, never a mix, however long Cloudflare or the browser
keep main.dart.js and the rest.

If the repository becomes private, put a read-only GitHub token (contents:
read) in ~/.config/kupler-sync/token of the user that runs the script.
"""

import fcntl
import hashlib
import json
import os
import pathlib
import re
import shutil
import sys
import time
import urllib.error
import urllib.request
import zipfile

REPO = '07erkanoz/LifeOsTetris'
TAG = 'test-build'
DEST = pathlib.Path(os.environ.get('KUPLER_DEST', '/var/www/vhosts/lifeos.com.tr/httpdocs/kupler/indir'))
PUBLIC = '/kupler/indir/'
TOKEN_FILE = pathlib.Path.home() / '.config/kupler-sync/token'
MANIFEST = DEST / 'latest.json'
WEB_ASSET = 'LifeOS-Kupler-Web.zip'
WEB_DEST = pathlib.Path(os.environ.get('KUPLER_WEB_DEST', DEST.parent / 'oyna'))
WEB_PUBLIC = '/kupler/oyna/'
# Builds kept in oyna/ besides the live one, for pages opened earlier.
WEB_KEEP = 3
# The first, hand-made upload put the build straight into oyna/.
WEB_LOOSE = {'.last_build_id', 'assets', 'canvaskit', 'icons', 'favicon.png', 'flutter.js', 'flutter_bootstrap.js',
             'flutter_service_worker.js', 'main.dart.js', 'manifest.json', 'version.json'}


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


def write_text(path, text):
    tmp = path.with_name(f'.{path.name}.part')
    tmp.write_text(text, encoding='utf-8')
    os.chmod(tmp, 0o644)
    os.replace(tmp, path)


def write_json(path, data):
    write_text(path, json.dumps(data, ensure_ascii=False, indent=1) + '\n')


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


def sync_web(asset, version, prev, force):
    """Puts the browser version online; returns its manifest entry and
    whether it changed."""
    index = WEB_DEST / 'index.html'
    if (not force and prev and prev.get('id') == asset['id'] and prev.get('updated_at') == asset['updated_at']
            and (WEB_DEST / prev['dir'] / 'index.html').exists() and index.exists()):
        return prev, False
    WEB_DEST.mkdir(parents=True, exist_ok=True)
    for f in WEB_DEST.glob('.*.part'):  # left over by a run that failed
        shutil.rmtree(f) if f.is_dir() else f.unlink()
    archive = WEB_DEST / '.web.zip'
    sha = download(asset, archive)
    name = f'v{version}-{sha[:8]}'
    folder = WEB_DEST / name
    staging = WEB_DEST / f'.{name}.part'
    try:
        with zipfile.ZipFile(archive) as z:
            for m in z.namelist():
                p = pathlib.PurePosixPath(m)
                if p.is_absolute() or '..' in p.parts or '\\' in m:
                    raise RuntimeError(f'{asset["name"]}: unsafe path {m!r}')
            z.extractall(staging)
    finally:
        archive.unlink()
    # Built with --base-href /kupler/oyna/; pointing the base at the folder
    # makes the build load its own files.
    html = (staging / 'index.html').read_text(encoding='utf-8')
    base = f'<base href="{WEB_PUBLIC}">'
    if html.count(base) != 1:
        raise RuntimeError(f'{asset["name"]}: index.html has no {base}')
    html = html.replace(base, f'<base href="{WEB_PUBLIC}{name}/">')
    (staging / 'index.html').write_text(html, encoding='utf-8')
    for root, dirs, files in os.walk(staging):
        os.chmod(root, 0o755)
        for f in files:
            os.chmod(os.path.join(root, f), 0o644)
    if folder.exists():  # the same build again (--force): already online
        shutil.rmtree(staging)
    else:
        os.replace(staging, folder)
    write_text(index, html)  # the switch
    os.utime(folder)  # the newest folder is the live one
    return {'name': asset['name'], 'dir': name, 'size': asset['size'], 'sha256': sha, 'updated_at': asset['updated_at'],
            'id': asset['id'], 'url': WEB_PUBLIC}, True


def prune_web(live):
    """Removes older builds and the loose files of the hand-made upload."""
    removed = []
    builds = sorted((d for d in WEB_DEST.iterdir() if d.is_dir() and d.name.startswith('v') and d.name != live),
                    key=lambda d: d.stat().st_mtime, reverse=True)
    for d in builds[WEB_KEEP:]:
        shutil.rmtree(d)
        removed.append(f'oyna/{d.name}')
    for name in sorted(WEB_LOOSE):
        f = WEB_DEST / name
        if f.is_dir():
            shutil.rmtree(f)
        elif f.exists():
            f.unlink()
        else:
            continue
        removed.append(f'oyna/{name}')
    return removed


def main(force=False):
    DEST.mkdir(parents=True, exist_ok=True)
    with open(DEST / '.sync.lock', 'w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return  # the previous run is still downloading
        try:
            manifest = json.loads(MANIFEST.read_text())
            old = {a['name']: a for a in manifest['assets']}
        except (OSError, ValueError, KeyError):
            manifest, old = {}, {}
        rel = release()
        version = version_of(rel)
        assets, changed, web = [], [], None
        for a in sorted(rel['assets'], key=lambda a: a['name']):
            if a['state'] != 'uploaded' or '/' in a['name'] or a['name'].startswith('.'):
                continue
            if a['name'] == WEB_ASSET:
                web = a
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
        # Without a web build in the release, oyna/ stays as it is.
        web_entry, web_error = manifest.get('web'), None
        if web:
            try:
                web_entry, web_changed = sync_web(web, version, web_entry, force)
                if web_changed:
                    changed.append(f'oyna/{web_entry["dir"]}')
                removed += prune_web(web_entry['dir'])
            except Exception as e:  # the downloads above still get listed
                web_error = e
        if changed or removed or not MANIFEST.exists():
            write_json(MANIFEST, {
                'release': rel.get('name'),
                'version': version,
                'commit': rel.get('target_commitish'),
                'updated': max((a['updated_at'] for a in assets), default=None),
                'synced': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                'assets': assets,
                'web': web_entry,
            })
            print(time.strftime('%F %T'), rel.get('name'), 'updated:', ', '.join(changed) or '-', 'removed:', ', '.join(removed) or '-', flush=True)
        if web_error:
            raise RuntimeError(f'oyna: {web_error}')



if __name__ == '__main__':
    try:
        main(force='--force' in sys.argv)
    except Exception as e:  # cron mails/logs this line; the old files stay online
        sys.exit(f'{time.strftime("%F %T")} kupler sync failed: {e}')
