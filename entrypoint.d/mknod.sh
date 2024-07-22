#!/bin/sh

mknod -m 011 /glftpd/dev/null c 1 3
mknod -m 011 /glftpd/dev/zero c 1 5
mknod -m 011 /glftpd/dev/full c 1 7
mknod -m 011 /glftpd/dev/urandom c 1 9

