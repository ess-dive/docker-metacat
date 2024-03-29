#!/bin/bash
set -eo pipefail

# Function to Clean up testing artifacts
function finish {
  echo "Cleaning up testing artifacts:"
  docker rm -vf $mnid  $dbid $cid
  docker network rm metacat-test-network
  rm $test_file
}

# Remove container afterwards
trap finish EXIT

[ "$DEBUG" ] && set -x

# Set current working directory
cd "$(dirname "$0")"

dockerImage=$1

if ! docker inspect "$dockerImage" &> /dev/null; then
    echo $'\timage does not exist!'
    false
fi

# Create an instance of the container-under-test
cid="$(docker run -d "$dockerImage")"


#Run Tests
pwd=/usr/local/tomcat
TEST_PWD="$(docker exec "$cid" pwd )"
[ "$TEST_PWD" == "$pwd" ] || (echo "Incorrect pwd $TEST_PWD it should be $pwd" && exit 1)

# Is the metacat Application directory there
[ $(docker exec $cid ls webapps/metacat.war 2>&1 | grep 'cannot' | wc -l) -ne 1  ] || \
    (echo "Metacat application missing" && exit 1)

# Give time to start up
sleep 5

#Check for added catalina properties
[ $(docker exec $cid cat ./conf/catalina.properties | grep 'ALLOW_' | wc -l) -ne 0 ] || (echo "Catalina properties not configured" && exit 1)


#Check for Solr configuration in the logs
[ $(docker logs $cid  | grep 'INFO SOLR_CONF_LOCATION /var/metacat-fast/solr-home' | wc -l) -ne 0 ] || (echo "Solr configuration was not copied" && exit 1)


# Test the full application
docker network create metacat-test-network > /dev/null

dbid=$(docker run  \
       -p 5432:5432 \
       -e POSTGRES_PASSWORD=metacat \
       -e POSTGRES_USER=metacat \
       --name testdb  \
       --network=metacat-test-network -d \
       -it postgres:alpine)


# Give DB time to startup
sleep 5

test_file=${PWD}/test.properties
echo "configutil.propertiesConfigured=true" > $test_file
echo "configutil.authConfigured=true" >> $test_file
echo "configutil.skinsConfigured=true" >> $test_file
echo "configutil.databaseConfigured=true" >> $test_file
echo "configutil.geoserverConfigured=bypassed" >> $test_file
echo "configutil.dataoneConfigured=bypassed" >> $test_file
echo "configutil.ezidConfigured=bypassed" >> $test_file
echo "server.name=localhost" >> $test_file
echo "server.httpPort=8080" >> $test_file
echo "server.httpSSLPort=8443" >> $test_file
echo "application.deployDir=/usr/local/tomcat/webapps" >> $test_file
echo "application.context=\${METACAT_APP_CONTEXT}" >> $test_file
echo "database.connectionURI=jdbc:postgresql://testdb/metacat" >> $test_file
echo "database.user=metacat" >> $test_file
echo "database.password=metacat" >> $test_file
echo "database.type=postgres" >> $test_file
echo "database.driver=org.postgresql.Driver" >> $test_file
echo "database.adapter=edu.ucsb.nceas.dbadapter.PostgresqlAdapter" >> $test_file
echo "auth.administrators=metacat-admin@localhost" >> $test_file
echo "replication.logdir=/var/metacat/logs" >> $test_file
echo "solr.homeDir=/var/metacat-fast/solr-home" >> $test_file

mnid=$(docker run  \
       -v ${test_file}:/config/app.properties   \
       -p 8080:8080    \
       -e ADMIN=metacat-admin@localhost   \
       -e ADMINPASS=metacat-admin    \
       -e METACAT_APP_CONTEXT=foobar \
       -d \
       --network=metacat-test-network  \
       -it $dockerImage)


# Waiting for startup
sleep 20

[ $(docker logs $mnid | grep 'Merged /config/app.properties with' | wc -l) -ne 0 ] || \
    (echo "Properties not merged!" && exit 1)

[ $(docker logs $mnid | grep 'Added administrator to passwords file' | wc -l) -ne 0 ] || \
    (echo "Administrator user not added!" && exit 1)

[ $(docker logs $mnid | grep 'Upgraded/Initialized the metacat DB' | wc -l) -ne 0 ] || \
    (echo "DB not initialized!" && exit 1)

#Check for modified web.xml
[ $(docker exec $mnid cat ./webapps/metacat-index/WEB-INF/web.xml | grep 'foobar' | wc -l) -ne 0 ] || (echo "Application context not changed in metacat-index web.xml" && exit 1)


echo
echo "SUCCESS!!"
echo