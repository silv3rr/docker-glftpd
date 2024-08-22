# Variables

Build: can be used as env vars, set in `docker-build.sh`, `docker build` or compose

Runtime: can be used as env vars, set in `docker-run.sh`, `docker run` or compose

All build arguments:

```
GLFTPD_URL="<https://...>         url to download gl
GLFTPD_SHA="<abc123def>"          sha512 hash for downloaded file
INSTALL_ZS=1                      uses etc/pzs-ng/zsconfig.h
INSTALL_BOT=1                     install eggdrop and ngBot
INSTALL_WEBUI=1                   install web interface
```

All runtime options:

```
GLFTPD_CONF=1                     mount glftpd/glftpd.conf from host
GLFTPD_PERM_UDB=1                 use permanent userdb
GLFTPD_PASSWD="<Passw0rd>"        set user 'glftpd' <passwd> (needs PERM_UDB)
GLFTPD_SITE=1                     mount host dir ./glftpd/site /glftpd/site
GLFTPD_PORT="<1234>"              change listen <port> (default is 1337)
GLFTPD_PASV_PORTS="<5000-5100>"   set passive <ports range>, set GLFTPD_CONF=1
GLFTPD_PASV_ADDR="<1.2.3.4>"      set passive <address>, add "1" for internal
                                  NAT e.g. "10.0.1.2 1"; needs GLFTPD_CONF=1
IRC_SERVERS="<irc.foo.com:6667>"  set bot irc server(s), space delimited
IRC_CHANNELS="<#mychan>"          set bot irc channels(s), space delimited
USE_FULL=1                        use 'docker-glftpd:full' image
FORCE=1                           remove any existing container first
```
