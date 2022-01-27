FROM tomcat:9.0-jdk8

# Debian Tomcat UID
ARG METACAT_UID=108

# Debian Tomcat GID
ARG METACAT_GID=121

ENV METACAT_APP_CONTEXT=metacat
ENV DB_HOST=db
ENV DB_PORT=5432
ENV DB_SOLR_HOST=db-solr
ENV DB_SOLR_PORT=8983
ARG METACAT_VERSION=2.8.7
ADD metacat-bin-${METACAT_VERSION}.tar.gz /tmp/
ADD metacat/catalina.properties /tmp/
ADD metacat/server.xml.patch /tmp/
ADD metacat/skins /tmp/skins
ADD image_version.yml image_version.yml


RUN apt-get update && apt-get install -y --no-install-recommends \
        patch \
        python3-bcrypt \
        vim \
        netcat \
        libxml2-utils \
        net-tools \
        telnetd \
        procps \
        logrotate \
    && rm -rf /var/lib/apt/lists/* \
    && unzip /tmp/metacat-index.war -d /usr/local/tomcat/webapps/metacat-index \
    && unzip /tmp/metacat.war -d /usr/local/tomcat/webapps/metacat \
    && cat /tmp/catalina.properties >> /usr/local/tomcat/conf/catalina.properties \
    && rm -rf /tmp/*.war

ADD metacat/metacat.conf /etc/logrotate.d/

COPY metacat/apply_config.py /usr/local/bin/
RUN ln -s usr/local/bin/apply_config.py / # backwards compat

COPY metacat/apply_context.py /usr/local/bin/
RUN ln -s usr/local/bin/apply_context.py / # backwards compat

COPY metacat/docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
RUN [ -L /usr/bin/python ] && unlink /usr/bin/python; \
    ln -s /usr/bin/python3 /usr/bin/python  # symbolic link to python
ENTRYPOINT ["docker-entrypoint.sh"]

# merge recommended settings for metacat into default configuration
RUN patch conf/server.xml /tmp/server.xml.patch

# create unprivileged user, create application directories, and ensure proper permissions
RUN groupadd -g ${METACAT_GID} metacat && \
    useradd -u ${METACAT_UID} -g ${METACAT_GID} -c 'Metacat User'  --no-create-home metacat && \
    mkdir -p /var/metacat && \
    chown -R metacat:metacat /tmp/skins && \
    chown -R metacat:metacat /var/metacat logs temp work && \
    chown -R metacat:metacat /usr/local/tomcat/conf && \
    chown -R metacat:metacat /usr/local/tomcat/webapps  && \
    chmod g+s  /usr/local/tomcat/webapps   && \
    chmod +r+g conf/* && \
    find . -name oa4mp-client-oauth1-3.3.war -delete

EXPOSE 8080
EXPOSE 8009
EXPOSE 8443

USER metacat

CMD ["bin/catalina.sh","start"]
