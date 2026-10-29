# lifeos.com.tr download mirror and browser version

`kupler_sync_downloads.py` copies the GitHub `test-build` release to
`https://lifeos.com.tr/kupler/indir/` so visitors download from lifeos.com.tr,
and puts the browser version from the same release
(`LifeOS-Kupler-Web.zip`) online at `https://lifeos.com.tr/kupler/oyna/`.
It runs as the site user `lifeos` from cron every 10 minutes and logs only
when something changed.

Install (as root on the server):

```bash
install -d -m 755 /opt/kupler-sync
install -m 755 kupler_sync_downloads.py /opt/kupler-sync/
install -o lifeos -g psaserv -m 644 /dev/null /var/log/kupler-sync.log
echo '*/10 * * * * lifeos /usr/bin/python3 /opt/kupler-sync/kupler_sync_downloads.py >> /var/log/kupler-sync.log 2>&1' > /etc/cron.d/kupler-sync
sudo -u lifeos /usr/bin/python3 /opt/kupler-sync/kupler_sync_downloads.py   # first copy
install -o lifeos -g psaserv -m 644 indir.htaccess /var/www/vhosts/lifeos.com.tr/httpdocs/kupler/indir/.htaccess
install -o lifeos -g psaserv -m 644 oyna.htaccess /var/www/vhosts/lifeos.com.tr/httpdocs/kupler/oyna/.htaccess
```

`indir.htaccess` keeps the script's lock and half-downloaded files private
and stops browsers from caching `latest.json` and `version.json`.

## Browser version (`oyna/`)

CI builds it with `flutter build web --release --base-href /kupler/oyna/`.
Flutter's files (`main.dart.js`, `flutter_bootstrap.js`, `assets/`...) keep
their names from build to build, and Cloudflare keeps static files for four
hours, so overwriting them in place would hand some visitors an old
`main.dart.js` with new assets. Instead every build gets a folder of its own:

```
oyna/
  .htaccess                  oyna.htaccess: index.html is never cached
  index.html                 <base href="/kupler/oyna/v1.0.0-45-1a2b3c4d/">
  v1.0.0-45-1a2b3c4d/        the live build (version and zip checksum)
  v1.0.0-44-9f8e7d6c/        up to three earlier builds, for pages opened
  ...                        before the switch
```

The script unpacks the zip into a hidden staging folder in `oyna/`, renames
it to its final name and only then replaces `oyna/index.html`, which points
the page's `<base href>` at that folder. That replace is the switch: a
browser gets either the old page with the old build or the new page with
the new build. Files in a build folder never change, so Cloudflare and
browsers may cache them as long as they like.

Every request reaches Apache, which hands static files to nginx
(`X-Accel-Redirect`), so the `Cache-Control` rules of the `.htaccess` files
do reach the visitor; the ETag is nginx's own. Cloudflare's *Browser Cache
TTL* (four hours by default) raises any lower `max-age`, so a Cache Rule for
`/kupler/indir/*` sets the browser TTL to *respect origin*; `no-cache`
(`latest.json`, `oyna/index.html`) passes unchanged. To see what the server
itself sends, skip Cloudflare:
`curl -sI --resolve lifeos.com.tr:443:185.223.77.31 https://lifeos.com.tr/kupler/indir/latest.json`.
The folder per build does not depend on any of this; a browser that keeps an
old `index.html` for a while still finds that build's folder.

`latest.json` in `indir/` records the live build under `web`.

`version.json` in `indir/` is written by CI and comes with the release like
the downloads: `latest` (the version with dots, `1.0.0.72`), and for each
platform its address under `downloads` and `name`, `size` and `sha256` under
`files`, the shape of Gate's, TV's and AnyWhere's. LifeOS's `lifeos-kupler`
package follows new releases with it. It keeps its name (older copies of
this script saved it as `version.json-<version>` too, beside the link).

If the repository becomes private, create a fine-grained GitHub token with
read-only *Contents* access to this repository and save it as
`/var/www/vhosts/lifeos.com.tr/.config/kupler-sync/token` (owner `lifeos`,
mode 600).
