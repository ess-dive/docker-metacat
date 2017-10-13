# Metacat
<img src="https://knb.ecoinformatics.org/knb/docs/_images/metacat-logo-darkgray.png" 
alt="metacat" height="75" width="65"/>

*The official metacat docker image, made in a collaboration between NCEAS and LBNL*

## What is metacat?

*from [www.dataone.org/software-tools/metacat](https://www.dataone.org/software-tools/metacat)*

Metacat is a flexible, open source metadata catalog and data repository 
that targets scientific data, particularly from ecology and environmental 
science. Metacat accepts XML as a common syntax for representing the large 
number of metadata content standards that are relevant to ecology and other 
sciences. Thus, Metacat is a generic XML database that allows storage, query, 
and retrieval of arbitrary XML documents without prior knowledge of the XML schema.

Metacat is designed and implemented as a Java servlet application that utilizes 
a relational database management system to store XML and associated meta-level 
information. Installation of Metacat recommends the use of Apache Tomcat for 
servlet management and PostgreSQL as the underlying RDBMS, although other 
configurations are possible. Metacat provides a rich client Application 
Programming Interface (API) and supports a variety of languages, including 
Java, Python, and Perl.

Metacat is being used extensively throughout the world to manage environmental 
data. It is a key infrastructure component for the NCEAS data catalog, the 
Knowledge Network for Biocomplexity (KNB) data catalog, and for the DataONE 
system, among others.

## Usage
The Metacat docker image requires an existing database.  This 
example will start and link a postgres database and Metacat member node.
It is a very minimal example. Please refer to the 
[Metacat administration](https://knb.ecoinformatics.org/knb/docs/)
documentation for more information on how to configure a Metacat member node.


    docker network create metacat-network
    
    DB_USER=metacat
    DB_PASSWORD=metacat
    docker run  \
       -p 5432:5432 \
       -e POSTGRES_PASSWORD=$DB_PASSWORD \
       -e POSTGRES_USER=$DB_USER \
       --network metacat-network -d \
       --name db  -it postgres:alpine 


# How to use this image

## Image Environment Variables
The following environment variables are optional:

**ADMIN:** the administrator username.  Please note that this must match the 
`auth.administrator` value in `metacat.properties`.

**ADMINPASS:** The password for the admin user

**ADMINPASS_FILE:**  A file that contains the admin user password.  This file 
must be mountied inside the container.

**APP_PROPERTIES_FILE:** The file path where the local application property files 
are mounted in the container.


Build the docker metacat image:

    VERSION_MAJOR_MINOR=2.8
    VERSION_PATCH=5
    ./build.sh $VERSION_MAJOR_MINOR $VERSION_PATCH

Create a file named `app.properties` with the content below:
    
    ######## Configuration utility section  ################
    
    configutil.propertiesConfigured=true
    configutil.authConfigured=true
    configutil.skinsConfigured=true
    configutil.databaseConfigured=true
    configutil.geoserverConfigured=bypassed
    configutil.dataoneConfigured=bypassed
    configutil.ezidConfigured=bypassed
    
    ############### Server Values #################
    
    server.name=localhost
    server.httpPort=8080
    server.httpSSLPort=8443
    
    ############### Application Values ############

    ## one of the few places where we use ANT tokens
    application.metacatVersion=<version>
    application.deployDir=/usr/local/tomcat/webapps
    ## This is autodiscovered and populated by the config utility
    application.context=metacat

    ############### Database Values ###############
    
    database.connectionURI=jdbc:postgresql://db/metacat
    database.user=metacat
    database.password=metacat
    database.type=postgres
    database.driver=org.postgresql.Driver
    database.adapter=edu.ucsb.nceas.dbadapter.PostgresqlAdapter
    
    ######## Authentication  ##############################################
    auth.administrators=metacat-admin@localhost
    
    
    ######## Replication properties  #########################################
    replication.logdir=/var/metacat/logs


Run the docker container 
    
    docker run  \
           -v ${PWD}/app.properties:/config/metacat.properties   \
           -p 8080:8080    \
           -e ADMIN=metacat-admin@localhost   \
           -e ADMINPASS=metacat-admin    \
           -e APP_PROPERTIES_FILE=/config/metacat.properties \
           --name mn  -d\
           --network=metacat-network  \
           -it metacat:$VERSION 
           

The metacat REST API should be able to be accessed at `http://localhost:8080/metacat/d1/mn`



# License

TBD

# Supported Docker versions

This image is officially supported on Docker version 17.09.0.


# People

Current Project Team Members:

 * [@vchendrix](https://github.com/vchendrix)
