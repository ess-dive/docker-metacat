#!/usr/bin/env bash
set -e

if [ -z $1 ] ;
  then
    echo "Usage: $0 <version> (<uid> <gid>)"
    exit
fi
SOLR_VERSION=8.11.1
BUILD_ARGS="${BUILD_ARGS} --build-arg SOLR_VERSION=$SOLR_VERSION"

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



DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#Read the split words into an array based on space delimiter
VERSION=$1
IFS='.' read -a version_array <<< "${VERSION}"

if [ ${#version_array[*]} -lt 3 ];
then
  echo "ERROR: Version ${VERSION} must be three numbers it is ${#version_array[*]}"
  exit
fi
version_major=${version_array[0]}
version_minor=${version_array[1]}
echo "INFO: Metacat major:$version_major minor:$version_minor"


# Check the version number
# Continue if form Metacat 2.13 and greater
if [ $version_major -eq 2 ] && [ $version_minor -ge 13 ] || [ $version_major -ge 3 ];
then

  # Get Metacat
  METACAT=metacat-bin-${VERSION}
  ARCHIVE=${METACAT}.tar.gz

  BUILD_ARGS="${BUILD_ARGS} --build-arg METACAT_VERSION=${VERSION}"

  # Get the metacat distribution
  if [ ! -f  "$DIR/${ARCHIVE}" ];
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

  rm -rf $DIR/metacat-index.war $DIR/metacat.war $DIR/solr/WEB-INF "$DIR/style/skins/metacatui/eml-2/eml-dataset.xsl" "$DIR/WEB-INF/classes/solr-home/conf/schema.xml"

  # Get the solr config from the index war file for solr image
  tar -xvf  $DIR/${ARCHIVE} --directory $DIR metacat-index.war
  tar -xvf  $DIR/${ARCHIVE} --directory $DIR metacat.war
  unzip "$DIR/metacat-index.war" "WEB-INF/classes/solr-home/conf/*" -d "$DIR/solr"
  unzip "$DIR/metacat-index.war" "WEB-INF/classes/solr-home/conf/schema.xml" -d "$DIR"
  # Customize the Metacat Solr Schema
  patch -N $DIR/WEB-INF/classes/solr-home/conf/schema.xml  $DIR/solr/schema.xml.patch -o $DIR/solr/WEB-INF/classes/solr-home/conf/schema.xml

  # Patch eml-dataset.xsl with eml-dataset.xsl.patch for the current release
  unzip "$DIR/metacat.war" "style/skins/metacatui/eml-2/eml-dataset.xsl"   -d "$DIR"
  [ ! -f "$DIR/metacat/skins/metacatui/eml-2/" ] && mkdir -pv "$DIR/metacat/skins/metacatui/eml-2/"
  # Customize the EML XSL Template
  patch -N $DIR/style/skins/metacatui/eml-2/eml-dataset.xsl  $DIR/metacat/eml-dataset.xsl.patch -o $DIR/metacat/skins/metacatui/eml-2/eml-dataset.xsl

  echo "docker build ${DOCKER_BUILD_OPTIONS} -f $DIR/metacat/Dockerfile -t ${IMAGE_NAME} $BUILD_ARGS $DIR/"
  docker build ${DOCKER_BUILD_OPTIONS} -f $DIR/metacat/Dockerfile -t ${IMAGE_NAME} $BUILD_ARGS $DIR/

  # create the docker tag
  DOCKER_TAG="${VERSION}-${SOLR_VERSION}-p$(cd $DIR; git rev-list HEAD --count)"

  # Determine if there is an image registry
  IMAGE_NAME="metacat-solr:${DOCKER_TAG}"
  if [ "${REGISTRY_SPIN}" != "" ];
  then
    # There is a spin registry
    IMAGE_NAME="${REGISTRY_SPIN}/${IMAGE_NAME}"
  fi

  echo "docker build ${DOCKER_BUILD_OPTIONS} -f $DIR/solr/Dockerfile -t ${IMAGE_NAME} $BUILD_ARGS $DIR/"
  docker pull solr:${SOLR_VERSION}
  docker build ${DOCKER_BUILD_OPTIONS} -f $DIR/solr/Dockerfile -t ${IMAGE_NAME} $BUILD_ARGS $DIR/
else

  echo "ERROR: Metacat Version $VERSION not supported anymore. Please use Metacat>=2.13.0"

fi

