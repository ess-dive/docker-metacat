ARG SOLR_VERSION=8.4.1
FROM solr:${SOLR_VERSION}

USER root

RUN apt-get update; \
  apt-get -y install zip; \
  find / -name log4j-core-*.jar | xargs -n 1 -I {} zip -q -d {} org/apache/logging/log4j/core/lookup/JndiLookup.class;

USER $SOLR_USER

ADD image_version.yml image_version.yml
ADD solr/WEB-INF/classes/solr-home/conf /tmp/conf
ADD solr/configure_metacat_solrcore.sh /docker-entrypoint-initdb.d


