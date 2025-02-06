#!/bin/sh -x
VERSION=V5
###################################################################   ####  # ##
# >> DOCKER-BUILD-PZSNG
###################################################################   ####  # ##
#
# (re)compiles pzs-ng in 'zs-artifacts' target image and copy to local dir
#
# DEST="<path>"     output files to path (default "./custom/pzs-ng")
# ALT_METHOD=1|2    set for older docker versions without '--output'
#
###################################################################   ####  # ##

ARGS="--build-arg INSTALL_ZS=1 --build-arg REBUILD_ZS=1 --target zs-artifacts ."
#ARGS="$ARGS --progress=plain "
#ARGS="$ARGS --no-cache "
DEST="./custom/pzs-ng"
#ALT_METMOD=1

if [ ! -s zsconfig.h ]; then
    echo "ERROR: zsconfig.h not found"
    exit 1
fi

# check for --output option (needs recent docker)
if docker build --help | grep -q '\--output'; then
    docker build $ARGS --output=type=local,dest="$DEST"
else
    echo "ERROR: docker build missing -o option"
    exit 1
fi

# alt methods, for older docker
if [ "${ALT_METMOD:-0}" -eq 1 ]; then
    docker build --tag zs-bins . && \
        docker create --name zs-export zs-bins && \
        docker cp zs-export:/glftpd/bin "$DEST" && \
        docker rm zs-export
fi
if [ "${ALT_METMOD:-0}" -eq 2 ]; then
    docker build --tag zs-bins . && \
    docker run --rm zs-bins tar -cC /glftpd . | tar -xC "$DEST"
fi
