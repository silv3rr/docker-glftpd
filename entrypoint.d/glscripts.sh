#!/bin/sh

if [ -d /custom/scripts ]; then
  if find /custom/scripts/* >/dev/null 2>&1; then
    cp -u -v /custom/scripts/* /glftpd/bin
  fi
fi
