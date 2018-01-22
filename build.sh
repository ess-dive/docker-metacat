#!/usr/bin/env bash

set -e

if [ -z $1 ] ;
  then
    echo "Usage: $0 <version>"
    exit
fi


VERSION=$1
VERSION_MAJOR_MINOR=${VERSION%.*}

if [ ! -d $BUILD_DIR ];
then
    echo "$BUILD_DIR does not exist"
    exit
fi

# Get Metacat
METACAT=metacat-bin-${VERSION}
ARCHIVE=${METACAT}.tar.gz
wget  -c http://knb.ecoinformatics.org/software/dist/${ARCHIVE} -O ${VERSION_MAJOR_MINOR}/${ARCHIVE}

docker build --build-arg METACAT_VERSION=$VERSION -t metacat:$VERSION $VERSION_MAJOR_MINOR
