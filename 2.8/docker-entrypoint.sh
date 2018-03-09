#!/usr/bin/env bash

set -e

if [ "$1" = 'bin/catalina.sh' ]; then


    METACAT_DEFAULT_WAR=/usr/local/tomcat/webapps/metacat.war
    METACAT_DIR=/usr/local/tomcat/webapps/${METACAT_APP_CONTEXT}
    METACAT_WAR=${METACAT_DIR}.war

    # Expand the metacat-index.war
    if [ ! -d webapps/metacat-index ];
    then
      unzip webapps/metacat-index.war -d webapps/metacat-index
    fi

    # Check the context
    if [ "${METACAT_WAR}" != "${METACAT_DEFAULT_WAR}" ] &&
       [ -f $METACAT_DEFAULT_WAR ];
    then
        # Move the application to match the context
        echo "Changing context to ${METACAT_APP_CONTEXT}"
        mv $METACAT_DEFAULT_WAR $METACAT_WAR

    fi

    # Expand the WAR file
    if [ ! -d $METACAT_DIR ];
    then
        unzip  $METACAT_WAR -d $METACAT_DIR
    fi

    # change the context in the web.xml file
    apply_context.py $METACAT_DIR/WEB-INF/web.xml metacat ${METACAT_APP_CONTEXT}

    DEFAULT_PROPERTIES_FILE=${METACAT_DIR}/WEB-INF/metacat.properties
    APP_PROPERTIES_FILE=${APP_PROPERTIES_FILE:-/config/app.properties}
    METACATUI_SKIN_PATH=${METACATUI_SKIN_PATH:-/config/skin}


    # Look for the metacat ui skin directory
    if [ -d ${METACATUI_SKIN_PATH} ];
    then
        echo
        echo '**********************************************************'
        echo "Copying skin files from  ${METACATUI_SKIN_PATH}  "
        echo '***********************************************************'
        echo
        # copy skin files in the MetacatUI skins directory
        find ${METACATUI_SKIN_PATH} -type f | sed "s|${METACATUI_SKIN_PATH}||" \
            | xargs -I '{}' cp -vf /config/skin/'{}'  $METACAT_DIR/style/skins/metacatui/'{}'

        echo
        echo '**********************************************************'
        echo "Copied skin files ${METACATUI_SKIN_PATH}  "
        echo '***********************************************************'
        echo

    fi

    # Look for dbpassword file
    if [  ! -z "$DB_PASSWORD_FILE"  ] && [ -s $DB_PASSWORD_FILE ];
    then
        export DB_PASSWORD=`cat $DB_PASSWORD_FILE`
    fi

    # Look for the password file
    if [  ! -z "$ADMINPASS_FILE"  ] && [ -s $ADMINPASS_FILE ];then
        ADMINPASS=`cat $ADMINPASS_FILE`
    fi


    # Look for the properties file
    if [ -s $APP_PROPERTIES_FILE ];
    then
        apply_config.py $APP_PROPERTIES_FILE $DEFAULT_PROPERTIES_FILE

        echo
        echo '**********************************************************'
        echo "Merged $APP_PROPERTIES_FILE with "
        echo 'default metacat.properties'
        echo '***********************************************************'
        echo
    elif [ "$APP_PROPERTIES_FILE" != "/config/app.properties" ];
    then

        echo "ERROR: The application properties file ($APP_PROPERTIES_FILE) was empty"
        echo "   or does not exist. Please check the $APP_PROPERTIES_FILE is"
        echo "   exists in the container filesystem."
        exit -2
    fi

    # Set the metacat user as the owner of webapps, logs, temp and work
    chown -R :metacat /usr/local/tomcat/conf
    chmod +r+g conf/*
    chown -R metacat:metacat webapps logs temp work

    ## Using Here document to create directories as metacat
    su metacat <<EOSU
    #Make sure all default directories are available
    mkdir -p /var/metacat/data \
        /var/metacat/inline-data \
        /var/metacat/documents \
        /var/metacat/temporary \
        /var/metacat/logs


    # Initialize the solr home directory
    if [ ! -d /var/metacat/solr-home ];
    then
        mkdir -p /var/metacat/solr-home

        # Copy the default solr conf files
        SOLR_CONF_DEFAULT_LOCATION=./webapps/metacat-index/WEB-INF/classes/solr-home/
        SOLR_CONF_LOCATION=/var/metacat/solr-home
        SOLR_CONF_FILES=`cd ${SOLR_CONF_DEFAULT_LOCATION} && find . `
        for f in ${SOLR_CONF_FILES[@]};
        do
            if [ ! -f $SOLR_CONF_LOCATION/$f ] && [ -f $f ];
            then
                echo "Copying Solr configuraiton file: $SOLR_CONF_LOCATION/$f"
                mkdir -p $SOLR_CONF_LOCATION/$NEW_DIR
                cp ${SOLR_CONF_DEFAULT_LOCATION}/$f $SOLR_CONF_LOCATION/$f
            fi

        done
    fi


    # If there is an admin/password set and it does not exist in the passwords file
    # set it
    if [ ! -z "$ADMIN" ];
    then
        USER_PWFILE="/var/metacat/users/password.xml"

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
            cd ${METACAT_DIR}/WEB-INF/scripts/bash
            PASS=`python -c "import bcrypt; print bcrypt.hashpw('$ADMINPASS', bcrypt.gensalt(10,prefix='2a'))"`
            bash ./authFileManager.sh useradd -h $PASS -dn  "$ADMIN"
            cd /usr/local/tomcat

            echo
            echo '*************************************'
            echo 'Added administrator to passwords file'
            echo '*************************************'
            echo

        fi
    fi

    echo
    echo '**************************************'
    echo "Starting Tomcat"
    echo '**************************************'
    echo

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

EOSU

    # Login to Metacat Admin and start a session (cookie.txt)
    echo
    echo '**************************************'
    echo "Login to Metacat Admin and start a "
    echo "session (cookie.txt)"
    echo '**************************************'
    echo

    curl -X POST \
        --data "loginAction=Login&configureType=login&processForm=true&password=${ADMINPASS}&username=${ADMIN}" \
        --cookie-jar /tmp/cookie.txt http://localhost:8080/${METACAT_APP_CONTEXT}/admin > /tmp/login_result.txt 2>&1

    # Test the the admin logged in successfully
    [ $(grep "User logged in as:" login_result.txt| wc -l) -eq 0 ] || (echo "Administrator not logged in!!" && exit -4)

    echo
    echo '**************************************'
    echo "Logged in to Metacat"
    echo '**************************************'
    echo

    ## If the DB needs to be updated run the migration scripts
    DB_CONFIGURED=`grep "configureType=database" /tmp/login_result.txt | wc -l`
    if [ $DB_CONFIGURED -ne 0 ];
    then

        # Run the database initialization to create or upgrade tables
        # /${METACAT_APP_CONTEXT}/admin?configureType=database must have an authenticated session, then run
        curl -X POST --cookie /tmp/cookie.txt \
            --data "configureType=database&processForm=true" \
            http://localhost:8080/${METACAT_APP_CONTEXT}/admin > /dev/null 2>&1

        # Validate the database should be configured
        curl -X POST --cookie /tmp/cookie.txt \
            --data "configureType=configure&processForm=false" \
            http://localhost:8080/${METACAT_APP_CONTEXT}/admin > /dev/null 2>&1

        echo
        echo '***********************************'
        echo "Upgraded/Initialized the metacat DB"
        echo '***********************************'
        echo
    else
        echo
        echo '**************************************'
        echo "Metacat is already configured"
        echo '**************************************'
        echo
    fi

    # Remove the session cookie
    rm -f /tmp/cookie.txt /tmp/login_result.txt
    echo
    echo '**************************************'
    echo "END"
    echo '**************************************'
    echo

fi

exec tail -f /usr/local/tomcat/logs/catalina.out


