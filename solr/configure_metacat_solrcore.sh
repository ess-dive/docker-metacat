#!/bin/bash
set -e

 # Prepare index
 if [ ! -d ${SOLR_HOME}/dataone/conf ];
 then
   echo "INFO Configuring metacat solr core ..."

   # Create a solr core
   precreate-core dataone

   # Copy Metacat dataone conf to the newly created
   #    dataone solr core
   cp -rv /tmp/conf $SOLR_HOME/dataone/

   echo "Metacat solr index prepared"
else
  echo "INFO Solr core already configured."
fi