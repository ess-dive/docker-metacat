FROM tomcat:7.0-jre8

# Debian Tomcat UID
ARG METACAT_UID=108

# Debian Tomcat GID
ARG METACAT_GID=121

ENV METACAT_APP_CONTEXT=metacat
ARG METACAT_VERSION=2.8.4
ADD /metacat-bin-${METACAT_VERSION}.tar.gz /tmp
ADD catalina.properties /tmp/


RUN apt-get update && apt-get install -y --no-install-recommends \
        vim \
        python-bcrypt \
    && rm -rf /var/lib/apt/lists/* \
    && cp /tmp/metacat.war /tmp/metacat-index.war /usr/local/tomcat/webapps \
    && cat /tmp/catalina.properties >> /usr/local/tomcat/conf/catalina.properties



COPY apply_config.py /usr/local/bin/
RUN ln -s usr/local/bin/apply_config.py / # backwards compat

COPY apply_context.py /usr/local/bin/
RUN ln -s usr/local/bin/apply_context.py / # backwards compat

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

# create unprivileged user
RUN groupadd -g ${METACAT_GID}  metacat && \
    useradd -u ${METACAT_UID} -g ${METACAT_GID} -c 'Metacat User'  --no-create-home metacat && \
    mkdir -p /var/metacat

EXPOSE 8080
EXPOSE 8009
EXPOSE 8443

CMD ["bin/catalina.sh","start"]



