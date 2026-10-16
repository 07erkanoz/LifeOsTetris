#!/usr/bin/env python3
"""App Store listing and TestFlight setup from ios/metadata/, through the API.

  status                  builds, TestFlight groups and the version being prepared
  sync                    texts, categories, age rating, price, availability,
                          screenshots, review contact and the build of the version
  testflight [--build N]  TestFlight test info, the public-link group with the
                          newest build (or build N, waiting for it to finish
                          processing) and a beta review submission when needed

Same environment as ci_signing.py (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH).
The review contact comes from ASC_CONTACT_EMAIL and ASC_CONTACT_PHONE (GitHub
secrets, so they stay out of the repository). Every step reports on its own:
one failing step does not hide the others, and the command fails at the end.
"""

import hashlib
import json
import os
import pathlib
import re
import sys
import time
import urllib.error
import urllib.request

import ci_signing
from ci_signing import BUNDLE_ID

API = 'https://api.appstoreconnect.apple.com'
HERE = pathlib.Path(__file__).resolve().parent
META = json.loads((HERE / 'metadata/store.json').read_text(encoding='utf-8'))
SHOTS = HERE / 'metadata/screenshots'
# File name prefix → App Store Connect slot (iPhone 6.9", iPad 13").
DISPLAY_TYPES = {'iphone': 'APP_IPHONE_67', 'ipad': 'APP_IPAD_PRO_3GEN_129'}
EDITABLE = {'PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED', 'INVALID_BINARY'}
# What App Review reads first (ios/metadata/store.json, reviewNotes).
REVIEW_NOTES = META.get('reviewNotes') or 'No account or sign-in. Every mode opens from the main menu; the game works offline and collects no data.'


class ApiError(Exception):
    pass


def call(method, path, body=None):
    req = urllib.request.Request(
        API + path,
        method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={'Authorization': f'Bearer {ci_signing.token()}', 'Content-Type': 'application/json'},
    )
    try:
        with urllib.request.urlopen(req) as res:
            raw = res.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        detail = e.read().decode()
        try:
            detail = '; '.join(f'{x.get("title")}: {x.get("detail")}' for x in json.loads(detail)['errors'])
        except (ValueError, KeyError, TypeError):
            pass
        raise ApiError(f'{method} {path.split("?")[0]} → {e.code} {detail}') from None


def rel(kind, id):
    return {'data': {'type': kind, 'id': id}}


def upsert(existing, kind, attributes, parent_key, parent):
    """PATCHes the existing resource or POSTs a new one under [parent]."""
    if existing:
        call('PATCH', f'/v1/{kind}/{existing["id"]}', {'data': {'type': kind, 'id': existing['id'], 'attributes': attributes}})
    else:
        call('POST', f'/v1/{kind}', {'data': {'type': kind, 'attributes': attributes, 'relationships': {parent_key: rel(*parent)}}})


results = []


def step(name, fn, *args):
    try:
        note = fn(*args)
        results.append((name, None))
        print(f'✓ {name}' + (f': {note}' if note else ''), flush=True)
    except Exception as e:  # noqa: BLE001 - every step reports on its own
        results.append((name, e))
        print(f'✗ {name}: {e}', flush=True)


def finish():
    failed = [n for n, e in results if e]
    if failed:
        sys.exit(f'\n{len(failed)} step(s) failed: {", ".join(failed)}')


def the_app():
    apps = call('GET', f'/v1/apps?filter[bundleId]={BUNDLE_ID}')['data']
    if not apps:
        sys.exit(f'No App Store Connect app with bundle id {BUNDLE_ID}')
    return apps[0]


def app_version():
    """Marketing version from pubspec.yaml (1.0.0+1 → 1.0.0)."""
    text = (HERE.parent / 'pubspec.yaml').read_text(encoding='utf-8')
    return re.search(r'^version:\s*([^+\s]+)', text, re.M).group(1)


def editable_app_info(app):
    infos = call('GET', f'/v1/apps/{app["id"]}/appInfos')['data']
    live = {'READY_FOR_DISTRIBUTION', 'READY_FOR_SALE', 'REPLACED_WITH_NEW_INFO'}
    return next((i for i in infos if (i['attributes'].get('state') or i['attributes'].get('appStoreState')) not in live), infos[0])


def editable_version(app, create=False):
    versions = call('GET', f'/v1/apps/{app["id"]}/appStoreVersions?filter[platform]=IOS&limit=20')['data']
    for v in versions:
        if (v['attributes'].get('appVersionState') or v['attributes'].get('appStoreState')) in EDITABLE:
            return v
    if not create:
        return None
    return call('POST', '/v1/appStoreVersions', {'data': {
        'type': 'appStoreVersions',
        'attributes': {'platform': 'IOS', 'versionString': app_version()},
        'relationships': {'app': rel('apps', app['id'])},
    }})['data']


def by_locale(items):
    return {i['attributes']['locale']: i for i in items}


# ---------------------------------------------------------------- listing --

def categories(info):
    sub = META['subcategories']
    relationships = {'primaryCategory': rel('appCategories', META['primaryCategory'])}
    for key, cat in zip(['primarySubcategoryOne', 'primarySubcategoryTwo'], sub):
        relationships[key] = rel('appCategories', cat)

    def patch(rels):
        call('PATCH', f'/v1/appInfos/{info["id"]}', {'data': {'type': 'appInfos', 'id': info['id'], 'relationships': rels}})

    try:
        patch(relationships)
    except ApiError:
        # Find the relationship Apple refuses and list the ids it accepts.
        refused = []
        for key, value in relationships.items():
            try:
                patch({key: value})
            except ApiError as e:
                refused.append(f'{key}={value["data"]["id"]} ({e})')
        if refused:
            valid = [c['id'] for c in call('GET', f'/v1/appCategories/{META["primaryCategory"]}/subcategories?limit=50')['data']]
            raise ApiError(f'refused: {"; ".join(refused)}. Subcategories of {META["primaryCategory"]}: {", ".join(valid)}')
    return f'{META["primaryCategory"]} / {", ".join(sub)}'


def app_info_texts(info):
    existing = by_locale(call('GET', f'/v1/appInfos/{info["id"]}/appInfoLocalizations')['data'])
    for locale, t in META['locales'].items():
        attrs = {'name': t['name'], 'subtitle': t['subtitle'], 'privacyPolicyUrl': META['privacyPolicyUrl']}
        if locale not in existing:
            attrs['locale'] = locale
        upsert(existing.get(locale), 'appInfoLocalizations', attrs, 'appInfo', ('appInfos', info['id']))
    return ', '.join(META['locales'])


def content_rights(app):
    # The music and fonts are third-party (licensed) content.
    call('PATCH', f'/v1/apps/{app["id"]}', {'data': {'type': 'apps', 'id': app['id'], 'attributes': {
        'contentRightsDeclaration': 'USES_THIRD_PARTY_CONTENT'}}})


AGE_LEVELS = [
    'alcoholTobaccoOrDrugUseOrReferences', 'contests', 'gamblingSimulated', 'gunsOrOtherWeapons', 'horrorOrFearThemes',
    'matureOrSuggestiveThemes', 'medicalOrTreatmentInformation', 'profanityOrCrudeHumor', 'sexualContentGraphicAndNudity',
    'sexualContentOrNudity', 'violenceCartoonOrFantasy', 'violenceRealistic', 'violenceRealisticProlongedGraphicOrSadistic',
]
AGE_FLAGS = [
    'gambling', 'lootBox', 'unrestrictedWebAccess', 'messagingAndChat', 'parentalControls', 'ageAssurance',
    'userGeneratedContent', 'advertising', 'healthOrWellnessTopics',
]


def age_rating(info):
    """Answers every age rating question with "none" / "no": a block game
    without ads, chat, web views or user content."""
    decl = call('GET', f'/v1/appInfos/{info["id"]}/ageRatingDeclaration')['data']
    present = decl['attributes']
    answers = {k: 'NONE' for k in AGE_LEVELS if k in present} | {k: False for k in AGE_FLAGS if k in present}
    try:
        call('PATCH', f'/v1/ageRatingDeclarations/{decl["id"]}', {'data': {'type': 'ageRatingDeclarations', 'id': decl['id'], 'attributes': answers}})
        return f'{len(answers)} answers'
    except ApiError:
        # One unknown question would reject them all: answer one by one.
        failed = []
        for k, v in answers.items():
            try:
                call('PATCH', f'/v1/ageRatingDeclarations/{decl["id"]}', {'data': {'type': 'ageRatingDeclarations', 'id': decl['id'], 'attributes': {k: v}}})
            except ApiError:
                failed.append(k)
        if failed:
            raise ApiError(f'not accepted: {", ".join(failed)}')
        return f'{len(answers)} answers (one by one)'


def free_price(app):
    try:
        prices = call('GET', f'/v1/apps/{app["id"]}/appPriceSchedule/manualPrices?limit=1')['data']
        if prices:
            return 'already set'
    except ApiError:
        pass
    points = call('GET', f'/v1/apps/{app["id"]}/appPricePoints?filter[territory]=USA&limit=200')['data']
    free = next(p for p in points if float(p['attributes']['customerPrice']) == 0)
    call('POST', '/v1/appPriceSchedules', {
        'data': {'type': 'appPriceSchedules', 'relationships': {
            'app': rel('apps', app['id']),
            'baseTerritory': rel('territories', 'USA'),
            'manualPrices': {'data': [{'type': 'appPrices', 'id': '${free}'}]},
        }},
        'included': [{'type': 'appPrices', 'id': '${free}', 'attributes': {'startDate': None},
                      'relationships': {'appPricePoint': rel('appPricePoints', free['id'])}}],
    })
    return 'free'


def availability(app):
    try:
        call('GET', f'/v1/apps/{app["id"]}/appAvailabilityV2')
        return 'already set'
    except ApiError as e:
        if '404' not in str(e):
            raise
    territories = call('GET', '/v1/territories?limit=200')['data']
    call('POST', '/v2/appAvailabilities', {
        'data': {'type': 'appAvailabilities', 'attributes': {'availableInNewTerritories': True}, 'relationships': {
            'app': rel('apps', app['id']),
            'territoryAvailabilities': {'data': [{'type': 'territoryAvailabilities', 'id': f'${{{t["id"]}}}'} for t in territories]},
        }},
        'included': [{'type': 'territoryAvailabilities', 'id': f'${{{t["id"]}}}', 'attributes': {'available': True},
                      'relationships': {'territory': rel('territories', t['id'])}} for t in territories],
    })
    return f'{len(territories)} countries'


def version_info(version):
    want = app_version()
    attrs = {'copyright': META['copyright']}
    if version['attributes']['versionString'] != want:
        attrs['versionString'] = want
    call('PATCH', f'/v1/appStoreVersions/{version["id"]}', {'data': {'type': 'appStoreVersions', 'id': version['id'], 'attributes': attrs}})
    return f'version {want}'


def version_texts(version):
    existing = by_locale(call('GET', f'/v1/appStoreVersions/{version["id"]}/appStoreVersionLocalizations')['data'])
    for locale, t in META['locales'].items():
        attrs = {k: t[k] for k in ('description', 'keywords', 'promotionalText')}
        attrs |= {'supportUrl': META['supportUrl'], 'marketingUrl': META['marketingUrl']}
        if locale not in existing:
            attrs['locale'] = locale
        upsert(existing.get(locale), 'appStoreVersionLocalizations', attrs, 'appStoreVersion', ('appStoreVersions', version['id']))
    return ', '.join(META['locales'])


def upload_screenshot(set_id, path):
    data = path.read_bytes()
    shot = call('POST', '/v1/appScreenshots', {'data': {
        'type': 'appScreenshots',
        'attributes': {'fileName': path.name, 'fileSize': len(data)},
        'relationships': {'appScreenshotSet': rel('appScreenshotSets', set_id)},
    }})['data']
    for op in shot['attributes']['uploadOperations']:
        chunk = data[op['offset']:op['offset'] + op['length']]
        headers = {h['name']: h['value'] for h in op.get('requestHeaders') or []}
        urllib.request.urlopen(urllib.request.Request(op['url'], data=chunk, method=op['method'], headers=headers)).read()
    call('PATCH', f'/v1/appScreenshots/{shot["id"]}', {'data': {'type': 'appScreenshots', 'id': shot['id'], 'attributes': {
        'uploaded': True, 'sourceFileChecksum': hashlib.md5(data).hexdigest()}}})


def screenshots(version):
    """Replaces a slot's screenshots when the local files differ from it."""
    locs = by_locale(call('GET', f'/v1/appStoreVersions/{version["id"]}/appStoreVersionLocalizations')['data'])
    uploaded, kept, sets = 0, 0, []
    for locale in META['locales']:
        loc = locs[locale]
        res = call('GET', f'/v1/appStoreVersionLocalizations/{loc["id"]}/appScreenshotSets?include=appScreenshots&limit=50')
        shots = {i['id']: i['attributes'] for i in res.get('included', []) if i['type'] == 'appScreenshots'}
        by_type = {s['attributes']['screenshotDisplayType']: s for s in res['data']}
        for prefix, display in DISPLAY_TYPES.items():
            files = sorted((SHOTS / locale).glob(f'{prefix}-*.png'))
            if not files:
                continue
            want = [(f.name, hashlib.md5(f.read_bytes()).hexdigest()) for f in files]
            current = by_type.get(display)
            ids = [d['id'] for d in (current or {}).get('relationships', {}).get('appScreenshots', {}).get('data', [])]
            if current and [(shots[i]['fileName'], shots[i].get('sourceFileChecksum')) for i in ids if i in shots] == want:
                kept += len(files)
                continue
            if current is None:
                current = call('POST', '/v1/appScreenshotSets', {'data': {
                    'type': 'appScreenshotSets',
                    'attributes': {'screenshotDisplayType': display},
                    'relationships': {'appStoreVersionLocalization': rel('appStoreVersionLocalizations', loc['id'])},
                }})['data']
            for i in ids:
                call('DELETE', f'/v1/appScreenshots/{i}')
            for f in files:
                upload_screenshot(current['id'], f)
                uploaded += 1
            sets.append((f'{locale} {prefix}', current['id']))
    # Apple checks each image after the upload: report the ones it refused.
    for _ in range(12):
        states = {}
        for name, set_id in sets:
            for s in call('GET', f'/v1/appScreenshotSets/{set_id}/appScreenshots')['data']:
                d = s['attributes'].get('assetDeliveryState') or {}
                states[f'{name} {s["attributes"]["fileName"]}'] = d
        if all(d.get('state') in ('COMPLETE', 'FAILED') for d in states.values()):
            break
        time.sleep(10)
    bad = [f'{n}: {d.get("errors")}' for n, d in states.items() if d.get('state') == 'FAILED'] if sets else []
    if bad:
        raise ApiError('refused: ' + '; '.join(bad))
    return f'{uploaded} uploaded, {kept} unchanged'


def contact():
    email, phone = os.environ.get('ASC_CONTACT_EMAIL'), os.environ.get('ASC_CONTACT_PHONE')
    if not email or not phone:
        raise ApiError('add the ASC_CONTACT_EMAIL and ASC_CONTACT_PHONE secrets (phone like +90 5xx xxx xx xx)')
    c = META['reviewContact']
    return {'contactFirstName': c['firstName'], 'contactLastName': c['lastName'], 'contactEmail': email, 'contactPhone': phone}


def review_contact(version):
    attrs = contact() | {'demoAccountRequired': False, 'notes': REVIEW_NOTES}
    try:
        existing = call('GET', f'/v1/appStoreVersions/{version["id"]}/appStoreReviewDetail')['data']
    except ApiError:
        existing = None
    upsert(existing, 'appStoreReviewDetails', attrs, 'appStoreVersion', ('appStoreVersions', version['id']))


def version_build(app, version):
    want = app_version()
    builds = call('GET', f'/v1/builds?filter[app]={app["id"]}&filter[preReleaseVersion.version]={want}'
                         '&filter[processingState]=VALID&sort=-uploadedDate&limit=1')['data']
    if not builds:
        raise ApiError(f'no processed build of {want} yet')
    b = builds[0]
    call('PATCH', f'/v1/appStoreVersions/{version["id"]}/relationships/build', rel('builds', b['id']))
    return f'build {b["attributes"]["version"]}'


def sync():
    app = the_app()
    info = editable_app_info(app)
    step('Categories', categories, info)
    step('Name, subtitle, privacy URL', app_info_texts, info)
    step('Content rights', content_rights, app)
    step('Age rating', age_rating, info)
    step('Price', free_price, app)
    step('Availability', availability, app)
    version = editable_version(app, create=True)
    step('Version', version_info, version)
    step('Description, keywords, URLs', version_texts, version)
    step('Screenshots', screenshots, version)
    step('Review contact', review_contact, version)
    step('Build for the version', version_build, app, version)
    print('\nStill to do on appstoreconnect.apple.com (no API for these): App Privacy →'
          ' "Data Not Collected", then Add for Review once everything above is ✓.')


# ------------------------------------------------------------- testflight --

def beta_texts(app):
    existing = by_locale(call('GET', f'/v1/apps/{app["id"]}/betaAppLocalizations')['data'])
    email = os.environ.get('ASC_CONTACT_EMAIL')
    for locale, t in META['locales'].items():
        attrs = {'description': t['betaDescription'], 'marketingUrl': META['marketingUrl'], 'privacyPolicyUrl': META['privacyPolicyUrl']}
        if email:
            attrs['feedbackEmail'] = email
        if locale not in existing:
            attrs['locale'] = locale
        upsert(existing.get(locale), 'betaAppLocalizations', attrs, 'app', ('apps', app['id']))


def beta_contact(app):
    detail = call('GET', f'/v1/apps/{app["id"]}/betaAppReviewDetail')['data']
    attrs = contact() | {'demoAccountRequired': False, 'notes': REVIEW_NOTES}
    call('PATCH', f'/v1/betaAppReviewDetails/{detail["id"]}', {'data': {'type': 'betaAppReviewDetails', 'id': detail['id'], 'attributes': attrs}})


def find_build(app, number=None, wait=0):
    """The newest processed build, or build [number] once it has processed."""
    query = f'/v1/builds?filter[app]={app["id"]}&sort=-uploadedDate&limit=1&include=buildBetaDetail'
    if number:
        query += f'&filter[version]={number}'
    deadline = time.time() + wait
    while True:
        res = call('GET', query + ('' if number else '&filter[processingState]=VALID'))
        if res['data']:
            b = res['data'][0]
            state = b['attributes']['processingState']
            if state == 'VALID':
                beta = next((i for i in res.get('included', []) if i['type'] == 'buildBetaDetails'), None)
                return b, beta
            if state in ('FAILED', 'INVALID'):
                sys.exit(f'Build {b["attributes"]["version"]} is {state}: check the e-mail from App Store Connect')
        if time.time() > deadline:
            sys.exit(f'Build {number or ""} has not finished processing')
        print('Waiting for Apple to process the build…', flush=True)
        time.sleep(60)


def what_to_test(build):
    existing = by_locale(call('GET', f'/v1/builds/{build["id"]}/betaBuildLocalizations')['data'])
    for locale, t in META['locales'].items():
        attrs = {'whatsNew': t['whatToTest']}
        if locale not in existing:
            attrs['locale'] = locale
        upsert(existing.get(locale), 'betaBuildLocalizations', attrs, 'build', ('builds', build['id']))


def public_group(app, build):
    groups = call('GET', f'/v1/apps/{app["id"]}/betaGroups?limit=50')['data']
    group = next((g for g in groups if g['attributes']['name'] == META['publicGroup']), None)
    if group is None:
        group = call('POST', '/v1/betaGroups', {'data': {
            'type': 'betaGroups',
            'attributes': {'name': META['publicGroup'], 'publicLinkEnabled': True, 'publicLinkLimitEnabled': False, 'feedbackEnabled': True},
            'relationships': {'app': rel('apps', app['id'])},
        }})['data']
    elif not group['attributes'].get('publicLinkEnabled'):
        call('PATCH', f'/v1/betaGroups/{group["id"]}', {'data': {'type': 'betaGroups', 'id': group['id'], 'attributes': {'publicLinkEnabled': True}}})
    call('POST', f'/v1/betaGroups/{group["id"]}/relationships/builds', {'data': [{'type': 'builds', 'id': build['id']}]})
    return group


def beta_review(build, beta):
    state = (beta or {}).get('attributes', {}).get('externalBuildState')
    if state == 'READY_FOR_BETA_SUBMISSION':
        call('POST', '/v1/betaAppReviewSubmissions', {'data': {'type': 'betaAppReviewSubmissions', 'relationships': {'build': rel('builds', build['id'])}}})
        return 'submitted to Apple (usually reviewed within a day)'
    return f'state {state}'


def testflight(number=None):
    app = the_app()
    step('Test information', beta_texts, app)
    step('Beta review contact', beta_contact, app)
    build, beta = find_build(app, number, wait=45 * 60 if number else 0)
    label = f'build {build["attributes"]["version"]}'
    step(f'What to Test ({label})', what_to_test, build)
    holder = {}
    step(f'Public group "{META["publicGroup"]}" with {label}', lambda: holder.setdefault('g', public_group(app, build)) and None)
    step('Beta review', beta_review, build, beta)
    if 'g' in holder:
        g = call('GET', f'/v1/betaGroups/{holder["g"]["id"]}')['data']['attributes']
        link = g.get('publicLink')
        print(f'\nPublic TestFlight link: {link or "(appears after the first beta review is approved)"}')
        if link:
            summary = os.environ.get('GITHUB_STEP_SUMMARY')
            if summary:
                with open(summary, 'a') as f:
                    f.write(f'### TestFlight\nPublic link: {link}\n')


# ----------------------------------------------------------------- status --

def status():
    app = the_app()
    print(f'App: {app["attributes"]["name"]} ({app["id"]}), version in pubspec: {app_version()}')
    res = call('GET', f'/v1/builds?filter[app]={app["id"]}&sort=-uploadedDate&limit=10&include=preReleaseVersion,buildBetaDetail')
    inc = {(i['type'], i['id']): i['attributes'] for i in res.get('included', [])}
    print('\nBuilds (newest first):')
    for b in res['data'] or []:
        a, r = b['attributes'], b['relationships']
        ver = inc.get(('preReleaseVersions', (r['preReleaseVersion'].get('data') or {}).get('id')), {}).get('version', '?')
        beta = inc.get(('buildBetaDetails', (r['buildBetaDetail'].get('data') or {}).get('id')), {})
        print(f'  {ver} ({a["version"]})  {a["uploadedDate"][:16]}  {a["processingState"]}'
              f'  internal={beta.get("internalBuildState")}  external={beta.get("externalBuildState")}')
    if not res['data']:
        print('  none yet')
    print('\nTestFlight groups:')
    for g in call('GET', f'/v1/apps/{app["id"]}/betaGroups?limit=50')['data']:
        a = g['attributes']
        testers = call('GET', f'/v1/betaGroups/{g["id"]}/betaTesters?limit=200')['data']
        kind = 'internal' if a.get('isInternalGroup') else 'external'
        print(f'  {a["name"]} ({kind}, {len(testers)} testers)  public link: {a.get("publicLink") or "-"}')
    v = editable_version(app)
    if v:
        a = v['attributes']
        print(f'\nApp Store version {a["versionString"]}: {a.get("appVersionState") or a.get("appStoreState")}')


if __name__ == '__main__':
    command = sys.argv[1] if len(sys.argv) > 1 else 'status'
    if command == 'sync':
        sync()
    elif command == 'testflight':
        number = sys.argv[sys.argv.index('--build') + 1] if '--build' in sys.argv else None
        testflight(number)
    else:
        status()
    finish()
