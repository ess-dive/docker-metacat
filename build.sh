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

if [ ! -z $ESSDIVE_UID ];
then
  BUILD_ARGS="${BUILD_ARGS} --build-arg METACAT_UID=$ESSDIVE_UID"
fi

if [ ! -z $ESSDIVE_GID ];
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

# create the docker tag
DOCKER_TAG="${VERSION}-p$(cd $DIR; git rev-list HEAD --count)"

# CREATE image_version.yml
echo "****************************"
echo "BUILDING image_version"
echo "****************************"
IMAGE_VERSION_CONTENT="$(cd $DIR && git log -n 1 --pretty="commit_count:  $(git rev-list HEAD --count)%ncommit_hash:   %h%nsubject:       %s%ncommitter:     %cN <%ce>%ncommiter_date: %ci%nauthor:        %aN <%ae>%nauthor_date:   %ai%nref_names:     %D" )"
echo "$IMAGE_VERSION_CONTENT" > $DIR/image_version.yml
cat $DIR/image_version.yml


# Determine if there is an image registry
IMAGE_NAME="metacat:${DOCKER_TAG}"
if [ "${REGISTRY_SPIN}" != "" ];
then
  # There is a spin registry
  IMAGE_NAME="${REGISTRY_SPIN}/${IMAGE_NAME}"
fi

echo "docker build --no-cache  -t ${IMAGE_NAME} $BUILD_ARGS $DIR"
docker pull tomcat:7.0-jre8
docker build ${DOCKER_BUILD_OPTIONS}  -t ${IMAGE_NAME} $BUILD_ARGS $DIR