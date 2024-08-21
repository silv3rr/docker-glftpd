# Files

| Path                               | Description                         |Owner, mode|
|:-----------------------------------|:------------------------------------|:----------|
| docker-build.sh                    | (re)build images                    |           |
| docker-run.sh                      | start container, manage config      |           |
| customizer.sh                      | used by docker-run.sh               |           |
|||                                                                        |
| etc/.gotty                         | browser terminal cfg                |           |
| etc/xinetd*                        | init                                |           |
|||                                                                        |
| bin/gltool.sh                      | handles user/group mgmt for webui   |           |
| bin/hashgen.c                      | generates gl passwd hash            |           |
| bin/passwd.sh                      |                                     |           |
| test/*.sh                          | test ftp using lftp                 |           |
|||
| **Config templates** ||
| etc/glftpd/glftpd.conf.gz          | glftpd/glftpd.conf                  |           |
| etc/glftpd/udb-skel.tar.gz         | glftpd/etc/passwd                   |           |
|                                    | glftpd/etc/ftp-data/{users,groups}  |           |
| etc/eggdrop.conf.gz                | glftpd/eggdrop.conf                 | 999, 660  | 
| etc/pzs-ng/ngBot-skel.tar.gz       | glftpd/sitebot/pzs-ng/              |           |
| etc/pzs-ng/ngBot.conf.gz           | glftpd/sitebot/pzs-ng/ngBot.conf    | 999, XXX  |
|||
| **Generated**||
| userfile created by docker         | glftpd/sitebot/LamestBot.user       | 999, 660  |
| chanfile created by eggdrop        | glftpd/sitebot/LamestBot.chan       | 999, XXX  |
| etc/pzs-ng/zsconfig.h              | copied by docker, changes need rebuild |        |
|||
| **Glftpd dirs**||
| glftpd/site                        | container dir (default) or bind mount |  XXX, 777  |
| glftpd/scripts                     | contents get copied to glftpd bin                |           |
|||
| **3rd party scripts** || 
| entrypoint.d/*.sh                  | custom commands                     |           |
| custom                             | custom files                        |           |
|||
| **Web** ||
|                                    | nginx cfg, html, css and js for webui             |           |
|||
