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
    ESSIDIVE_UID=$2
fi

if [ ! -z $3 ] ;
then
    ESSIDIVE_GID=$3
fi

if [ ! -z $METACAT_UID ];
then
  BUILD_ARGS="${BUILD_ARGS} --build-arg METACAT_UID=$ESSDIVE_UID"
fi

if [ ! -z $METACAT_GID ];
then
  BUILD_ARGS="${BUILD_ARGS} --build-arg METACAT_GID=$ESSDIVE_GID"
fi


VERSION=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"


# Get Metacat
METACAT=metacat-bin-${VERSION}
ARCHIVE=${METACAT}.tar.gz

BUILD_ARGS="${BUILD_ARGS} --build-arg METACAT_VERSION=${VERSION}"

if [ ! -f  $DIR/${ARCHIVE} ];
then

    wget  http://knb.ecoinformatics.org/software/dist/${ARCHIVE} -O $DIR/${ARCHIVE}
fi

echo "docker build ${BUILD_ARGS} -t metacat:$VERSION $DIR"
docker pull tomcat:7.0-jre8
docker build ${BUILD_ARGS} -t metacat:${VERSION} $DIR
docker tag metacat:${VERSION} metacat
