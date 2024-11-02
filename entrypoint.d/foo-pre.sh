#!/bin/sh

if [ -d /custom/foo-pre ]; then
    if [ -s /custom/foo-pre/foo-pre ]; then
      cp -u -v -r /custom/foo-pre /glftpd/bin
      chmod 4711 /glftpd/bin/foo-pre
    fi
    if [ ! -s /glftpd/etc/pre.cfg ] && [ -s /custom/foo-pre/pre.cfg ]; then
        cp -u -v /custom/pre.cfg /glftpd/etc
    fi
    for i in pre-head.txt pre-tail.txt; do
        if [ -f /custom/foo-pre/$i ]; then
            cp -u -v  /custom/foo-pre/$i /glftpd/ftp-data/misc
        fi
    done
    if ! grep -Eq "^site_cmd.*/bin/foo-pre" glftpd/glftpd.conf; then
      cat <<-'_EOF_' >>glftpd/glftpd.conf
	### foo-pre:start ###############################################################
    site_cmd PRE EXEC /bin/foo-pre"
    custom-pre *"
    creditcheck /site/private* 0
    nostats /site/private/* *
	### foo-pre:end #################################################################
_EOF_
    fi
fi
