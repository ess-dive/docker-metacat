FROM tomcat:7.0-jre8


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

# Directory for persistent data
RUN mkdir -p /var/metacat

COPY apply_config.py /usr/local/bin/
RUN ln -s usr/local/bin/apply_config.py / # backwards compat

COPY apply_context.py /usr/local/bin/
RUN ln -s usr/local/bin/apply_context.py / # backwards compat

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 8080
EXPOSE 8009
EXPOSE 8443
CMD ["catalina.sh","start"]



