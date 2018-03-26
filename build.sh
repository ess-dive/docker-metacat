#!/usr/bin/env bash

set -e

if [ -z $1 ] ;
  then
    echo "Usage: $0 <version> (<uid> <gid>)"
    exit
fi

BUILD_ARGS=""
if [ ! -z $2 ] ;
then

    BUILD_ARGS="${BUILD_ARGS} --build-arg METACAT_UID=$2"
fi

if [ ! -z $3 ] ;
then

    BUILD_ARGS="${BUILD_ARGS} --build-arg METACAT_GID=$3"
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

BUILD_ARGS="${BUILD_ARGS} --build-arg METACAT_VERSION=${VERSION}"

if [ ! -f  ${VERSION_MAJOR_MINOR}/${ARCHIVE} ];
then

    wget  -c http://knb.ecoinformatics.org/software/dist/${ARCHIVE} -O ${VERSION_MAJOR_MINOR}/${ARCHIVE}
fi

echo "docker build ${BUILD_ARGS} -t metacat:$VERSION $VERSION_MAJOR_MINOR"
docker pull tomcat:7.0-jre8
docker build ${BUILD_ARGS} -t metacat:${VERSION} ${VERSION_MAJOR_MINOR}
