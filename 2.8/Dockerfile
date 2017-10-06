FROM tomcat:7.0-jre8

ARG METACAT_VERSION=2.8.4
ADD /metacat-bin-${METACAT_VERSION}.tar.gz /tmp

RUN apt-get update && apt-get install -y --no-install-recommends \
        vim \
        python-bcrypt \
    && rm -rf /var/lib/apt/lists/* \
    && cp /tmp/metacat.war /tmp/metacat-index.war /usr/local/tomcat/webapps \
    && /usr/local/tomcat/bin/catalina.sh start \
    && sleep 10 \
    && chmod +x /usr/local/tomcat/webapps/metacat/WEB-INF/scripts/bash/*.sh

# Directory for persistent data
RUN mkdir -p /var/metacat

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 8080
CMD ["catalina.sh","start"]



