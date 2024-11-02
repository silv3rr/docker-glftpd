#!/bin/sh

if [ -s /custom//pzs-ng/bin/zipscript-c ]; then
  cp -u -v /custom//pzs-ng/bin/zipscript -c /glftpd/bin
fi

# audiosort cleanup datacleaner dl_speedtest ng-chown ng-deldir ng-undupe passchk postdel postunnuke racestats rescan showlog sitewho zipscript-c
#if [ -d /custom/pzs-ng/bin ]; then
#  cp -u -v -r /custom/pzs-ng/bin /glftpd/bin
#fi

#if [ -s /custom/ngBot.conf.dist ] && [ ! -s /glftpd/sitebot/pzs-ng/ngBot.conf ]; then
#  cp ngBot.conf.dist /glftpd/sitebot/pzs-ng/ngBot.conf
#fi

#if [ -s /custom/sitebot/pzs-ng/ngBot.conf ]; then
#  cp -u -v ngBot.conf /glftpd/sitebot/pzs-ng
#fi
#
#for i in plugins themes modules; do
#  if [ -d /custom/sitebot/pzs-ng/$i ]; then
#    cp -u -v -r /custom/sitebot/pzs-ng/$i /glftpd/sitebot/pzs-ng/$i
#  fi
#done
