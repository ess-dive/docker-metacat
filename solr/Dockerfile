FROM solr:8.9

ADD image_version.yml image_version.yml
ADD solr/WEB-INF/classes/solr-home/conf /tmp/conf
ADD solr/configure_metacat_solrcore.sh /docker-entrypoint-initdb.d
