# Docker Compose

Includes `docker-compose.yml` which replaces docker-build.sh and docker-run.sh scripts.

Run pre-made images from github:

`docker compose up --detach`

`docker compose --profile full up --detach web`

Build and run local images:

`docker compose --profile local up --build --detach local-glftpd`

`docker compose --profile local up --build --detach local-web`

(web starts both gl and webui containers)

Edit docker-compose.yml to set build `args` and options under `environment`. Also you'll have to manage `volumes` (bind mounts) yourself, instead of having docker-run.sh doing it for you.

The customizer script can be run to modify gl/bot config files.

**Example**:

```
# run 'full' permanent glftpd and webui with compose (edit docker-compose.yml first)

GLFTPD_PERM_UDB=1 GLFTPD_CONF=1 GLFTPD_SITE=1 ZS_STATUS=1 BOT_STATUS=1 \
IRC_SERVERS="irc.efnet.org:6667 irc2.example.org:6697" IRC_CHANNELS="#pzs #pzs-staff" \
USE_FULL=1 WEBUI=1 ./customizer.sh && \
docker compose --profile full up --detach web
```
