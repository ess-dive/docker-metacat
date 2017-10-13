#!/usr/bin/env bash

set -e

if [ "$1" = 'catalina.sh' ]; then

    # Merge the application properties file and the metacat properties file
    if [ ! -z "$APP_PROPERTIES_FILE" ];
    then

        DEFAULT_PROPERTIES_FILE=/usr/local/tomcat/webapps/metacat/WEB-INF/metacat.properties
        cat $DEFAULT_PROPERTIES_FILE

        # Look for the properties file
        if [ -s $APP_PROPERTIES_FILE ];
        then
            apply_config.py $APP_PROPERTIES_FILE $DEFAULT_PROPERTIES_FILE

            echo
            echo '**********************************************************'
            echo 'Merged $APP_PROPERTIES_FILE with '
            echo 'default metacat.properties'
            echo '***********************************************************'
            echo
        else

            echo "ERROR: The application properties file (APP_PROPERTIES_FILE) was empty"
            echo "   or does not exist. Please check the $APP_PROPERTIES_FILE is"
            echo "   exists in the container filesystem."
            exit -2
        fi


    fi

    #Make sure all default directories are available
    mkdir -p /var/metacat/data \
        /var/metacat/inline-data \
        /var/metacat/documents \
        /var/metacat/temporary \
        /var/metacat/logs \
        /var/metacat/solr-home

    # Copy the default solr conf files
    SOLR_CONF_DEFAULT_LOCATION=./webapps/metacat-index/WEB-INF/classes/solr-home/
    SOLR_CONF_LOCATION=/var/metacat/solr-home
    SOLR_CONF_FILES=`find ${SOLR_CONF_DEFAULT_LOCATION}`
    for f in ${SOLR_CONF_FILES[@]};
    do
        NEW_FILE=${f#*${SOLR_CONF_DEFAULT_LOCATION}}
        if [ "$NEW_FILE" != "" ];
        then
            NEW_DIR=$(dirname $NEW_FILE)
            if [ ! -f $SOLR_CONF_LOCATION/$NEW_FILE ] && [ -f $f ];
            then
                echo "Copying Solr configuraiton file: $SOLR_CONF_LOCATION/$NEW_FILE"
                mkdir -p $SOLR_CONF_LOCATION/$NEW_DIR
                cp $f $SOLR_CONF_LOCATION/$NEW_FILE
            fi
        fi
    done


    # If there is an admin/password set and it does not exist in the passwords file
    # set it
    if [ ! -z "$ADMIN" ];
    then
        USER_PWFILE="/var/metacat/users/password.xml"

        # Look for the password file
        if [  ! -z "$ADMINPASS_FILE"  ] && [ -s $ADMINPASS_FILE ];then
            ADMINPASS=`cat $ADMINPASS_FILE`
        fi

        if [ -z "$ADMINPASS" ];
        then
            echo "ERROR: The admin user (ADMIN) was set but no password value was set."
            echo "   You may use ADMINPASS or ADMINPASS_FILE to set the administrator password"
            exit -1
        fi

        # look specifically for the user password file, as it is expected if the configuration is completed
        if [ ! -s $USER_PWFILE ] || [ $(grep $ADMIN /var/metacat/users/password.xml | wc -l) -eq 0  ]; then

            ## Note: the Java bcrypt library only supports '2a' format hashes, so override the default python behavior
            ## so that the hases created start with '2a' rather than '2y'
            cd /usr/local/tomcat/webapps/metacat/WEB-INF/scripts/bash
            PASS=`python -c "import bcrypt; print bcrypt.hashpw('$ADMINPASS', bcrypt.gensalt(10,prefix='2a'))"`
            ./authFileManager.sh useradd -h $PASS -dn  "$ADMIN"
            cd /usr/local/tomcat

            echo
            echo '*************************************'
            echo 'Added administrator to passwords file'
            echo '*************************************'
            echo

        fi
    fi

    # Start tomcat
    $@ > /dev/null 2>&1

    # Give time for tomcat to start
    echo
    echo '**************************************'
    echo "Waiting for Tomcat to start before"
    echo "checking upgrade/initialization status"
    echo '**************************************'
    echo
    sleep 5


    # Login to Metacat Admin and start a session (cookie.txt)
    curl -X POST \
        --data "loginAction=Login&configureType=login&processForm=true&password=${ADMINPASS}&username=${ADMIN}" \
        --cookie-jar ./cookie.txt http://localhost:8080/metacat/admin > login_result.txt 2>&1

    ## If the DB needs to be updated run the migration scripts
    DB_CONFIGURED=`grep "configureType=database" login_result.txt | wc -l`
    if [ $DB_CONFIGURED -ne 0 ];
    then

        # Run the database initialization to create or upgrade tables
        # /metacat/admin?configureType=database must have an authenticated session, then run
        curl -X POST --cookie ./cookie.txt \
            --data "configureType=database&processForm=true" \
            http://localhost:8080/metacat/admin > /dev/null 2>&1

        # Validate the database should be configured
        curl -X POST --cookie ./cookie.txt \
            --data "configureType=configure&processForm=false" \
            http://localhost:8080/metacat/admin > /dev/null 2>&1

        echo
        echo '***********************************'
        echo "Upgraded/Initialized the metacat DB"
        echo '***********************************'
        echo
    fi

    # Remove the session cookie
    rm cookie.txt login_result.txt

fi

exec tail -f /usr/local/tomcat/logs/catalina.out
