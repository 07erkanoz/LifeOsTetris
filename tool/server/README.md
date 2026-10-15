# lifeos.com.tr download mirror

`kupler_sync_downloads.py` copies the GitHub `test-build` release to
`https://lifeos.com.tr/kupler/indir/` so visitors download from lifeos.com.tr.
It runs as the site user `lifeos` from cron every 10 minutes and logs only
when something changed.

Install (as root on the server):

```bash
install -d -m 755 /opt/kupler-sync
install -m 755 kupler_sync_downloads.py /opt/kupler-sync/
install -o lifeos -g psaserv -m 644 /dev/null /var/log/kupler-sync.log
echo '*/10 * * * * lifeos /usr/bin/python3 /opt/kupler-sync/kupler_sync_downloads.py >> /var/log/kupler-sync.log 2>&1' > /etc/cron.d/kupler-sync
sudo -u lifeos /usr/bin/python3 /opt/kupler-sync/kupler_sync_downloads.py   # first copy
```

If the repository becomes private, create a fine-grained GitHub token with
read-only *Contents* access to this repository and save it as
`/var/www/vhosts/lifeos.com.tr/.config/kupler-sync/token` (owner `lifeos`,
mode 600).
