ARG SOLR_VERSION=8.4.1
FROM solr:${SOLR_VERSION}

ADD image_version.yml image_version.yml
ADD solr/WEB-INF/classes/solr-home/conf /tmp/conf
ADD solr/configure_metacat_solrcore.sh /docker-entrypoint-initdb.d

USER root
# Make the configuration files read-only by all
RUN chmod -R 775 /tmp/conf

# Make the script executable by all
RUN chmod 775 /docker-entrypoint-initdb.d/configure_metacat_solrcore.sh
USER solr
