#!/usr/bin/env bash

set -e

if [ -z $1 ] || [ -z $2 ];
  then
    echo "Usage: $0 <metacat_version> <build_dir>"
    exit
fi


METACAT_VERSION=$1
BUILD_DIR=$2

if [ ! -d $BUILD_DIR ];
then
    echo "$BUILD_DIR does not exist"
    exit
fi

# Get Metacat
METACAT=metacat-bin-${METACAT_VERSION}
ARCHIVE=${METACAT}.tar.gz
wget  -c http://knb.ecoinformatics.org/software/dist/${ARCHIVE} -O ${BUILD_DIR}/${ARCHIVE}
