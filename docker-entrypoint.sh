#!/usr/bin/env bash

set -e

if [ $DEBUG -eq 1 ];
then
    set -x
fi

if [ "$1" = 'bin/catalina.sh' ]; then

    echo
    echo '**************************************'
    echo "Waiting for Postgress to start "
    echo '**************************************'
    echo
    while ! nc -z "${DB_HOST:-db}" "${DB_PORT:-5432}"; do
      sleep 0.1
    done

    echo
    echo '**************************************'
    echo "Logrotating catalina.out"
    echo '**************************************'
    echo
    /usr/sbin/logrotate -s /usr/local/tomcat/logs/logrotate-status.log /etc/logrotate.d/metacat.conf

    METACAT_DEFAULT_WAR=/usr/local/tomcat/webapps/metacat.war
    METACAT_DIR=/usr/local/tomcat/webapps/${METACAT_APP_CONTEXT}
    METACAT_WAR=${METACAT_DIR}.war
    METACATUI_BASE_SKIN_PATH=/usr/local/tomcat/webapps/catalog/style/skins/metacatui

    # The following constant defines the last version before the metacat version that supports the upgrade status
    # ability in metacat node capabilities. This is used to enable the script to learn when to use the node capability
    UPGRADE_STATUS_ABILITY_PRE_VERSION=2.12.2

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
    apply_context.py metacat ${METACAT_APP_CONTEXT}

    DEFAULT_PROPERTIES_FILE=${METACAT_DIR}/WEB-INF/metacat.properties
    APP_PROPERTIES_FILE=${APP_PROPERTIES_FILE:-/config/app.properties}
    METACATUI_CUSTOM_SKINS_PATH=/config/skins
    METACAT_VERSION_CONFIGURED=`grep application.metacatVersion $DEFAULT_PROPERTIES_FILE | sed 's/[^:]*=//'`


    # Look for the metacat ui skin directory
    if [ -d ${METACATUI_CUSTOM_SKINS_PATH} ];
    then

        echo
        echo '**********************************************************'
        echo "Synchronizing skins from  ${METACATUI_CUSTOM_SKINS_PATH}  "
        echo '***********************************************************'
        echo

        for skin_path in ${METACATUI_CUSTOM_SKINS_PATH}/*/ # list skins paths
            do

                skin_path=${skin_path%*/}      # remove the trailing "/"
                skin_name=$(basename "$skin_path")

                echo
                echo '**********************************************************'
                echo "Copying base metacat skin properties files into ${skin_path}"
                echo '***********************************************************'
                echo

                cp -Rv ${skin_path} ${METACAT_DIR}/style/skins/

                cat $METACATUI_BASE_SKIN_PATH/metacatui.properties >> ${METACAT_DIR}/style/skins/${skin_name}/${skin_name}.properties
                cp -v $METACATUI_BASE_SKIN_PATH/metacatui.properties.metadata.xml ${METACAT_DIR}/style/skins/${skin_name}/${skin_name}.properties.metadata.xml

                echo
                echo '**********************************************************'
                echo "Finished syncing skin: ${skin_name}"
                echo '***********************************************************'
                echo
            done


        echo
        echo '**********************************************************'
        echo "Synchronized all skins from ${METACATUI_CUSTOM_SKINS_PATH}"
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

    # Make sure all default directories are available and owned by metacat
    [ `stat -c '%U:%G' /var/metacat`      = 'metacat:metacat' ] || chown metacat:metacat /var/metacat
    [ `stat -c '%U:%G' /var/metacat-fast` = 'metacat:metacat' ] || chown metacat:metacat /var/metacat-fast

    mkdir -p /var/metacat/data \
        /var/metacat/inline-data \
        /var/metacat/documents \
        /var/metacat/temporary \
        /var/metacat/logs

    # Look for Tomcat Configuration to copy
    if [ -d /config/conf ];
    then
        for f in /config/conf/*;
        do
            echo "Copying $f to /usr/local/tomcat/conf"
            cp $f /usr/local/tomcat/conf
        done
    fi


    # Initialize the solr home directory
    SOLR_CONF_LOCATION=/var/metacat-fast/solr-home
    if [ ! -d ${SOLR_CONF_LOCATION} ];
    then

        # Setup env for Here Document
        SOLR_CONF_DEFAULT_LOCATION=/usr/local/tomcat/webapps/metacat-index/WEB-INF/classes/solr-home
        USER_PWFILE="/var/metacat/users/password.xml"
        SOLR_CONF_FILES=`bash -c "cd ${SOLR_CONF_DEFAULT_LOCATION} && find ."`

        echo "INFO SOLR_CONF_LOCATION ${SOLR_CONF_LOCATION}"
        bash -c "mkdir -p $SOLR_CONF_LOCATION"

        for SOLR_FILE in ${SOLR_CONF_FILES[@]}
        do
        NEW_DIR=$(dirname $SOLR_CONF_LOCATION/$SOLR_FILE)

        mkdir -p $NEW_DIR
        if [ -f $SOLR_CONF_DEFAULT_LOCATION/$SOLR_FILE ] && [ ! -f $SOLR_CONF_LOCATION/$SOLR_FILE ];
        then
            echo "cp ${SOLR_CONF_DEFAULT_LOCATION}/$SOLR_FILE $SOLR_CONF_LOCATION/$SOLR_FILE"
            cp ${SOLR_CONF_DEFAULT_LOCATION}/$SOLR_FILE $SOLR_CONF_LOCATION/$SOLR_FILE
        fi
        done
    fi

    # If there is an admin/password set and it does not exist in the passwords file
    # set it
    if [ ! -z "$ADMIN" ];
    then

        if [ -z "$ADMINPASS" ];
        then
            echo "ERROR: The admin user (ADMIN) was set but no password value was set."
            echo "   You may use ADMINPASS or ADMINPASS_FILE to set the administrator password"
            exit -1
        fi

        echo
        echo '**************************************'
        echo 'Adding administrator to passwords file'
        echo '**************************************'
        echo

        # look specifically for the user password file, as it is expected if the configuration is completed
        if [ ! -s $USER_PWFILE ] || [ ! -f /var/metacat/users/password.xml ] || [ $(grep $ADMIN /var/metacat/users/password.xml | wc -l) -eq 0  ]; then

            echo "cd ${METACAT_DIR}/WEB-INF/scripts/bash"
            cd ${METACAT_DIR}/WEB-INF/scripts/bash

            ## Note: the Java bcrypt library only supports '2a' format hashes, so override the default python behavior
            ## so that the hases created start with '2a' rather than '2b'
            bash ./authFileManager.sh useradd \
                -h "`python -c "import bcrypt; print bcrypt.hashpw('$ADMINPASS', bcrypt.gensalt(10,prefix='2a'))"`" \
                -dn "$ADMIN"
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
    echo "Setting umask"
    echo '**************************************'
    echo
    umask 0007
    umask

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
    while ! nc -z localhost 8080; do
      sleep 0.1
    done


    # Login to Metacat Admin and start a session (cookie.txt)
    echo
    echo '**************************************'
    echo "Login to Metacat Admin and start a "
    echo "session (cookie.txt)"
    echo '**************************************'
    echo

    # Login to Metacat Admin and start a session (cookie.txt)
    curl -v -X POST \
        --data "loginAction=Login&configureType=login&processForm=true&password=${ADMINPASS}&username=${ADMIN}" \
        --cookie-jar /tmp/cookie.txt http://localhost:8080/${METACAT_APP_CONTEXT}/admin > /tmp/login_result.txt 2>&1


    # Test the the admin logged in successfully
	    [ -f /tmp/login_result.txt ] && [ $(grep "User logged in as:" /tmp/login_result.txt| wc -l) -eq 1 ] || (echo "Administrator not logged in!!" && [ ! $DEBUG -eq 1 ] &&  grep "<message>" /tmp/login_result.txt && exit -4)

    echo
    echo '**************************************'
    echo "Logged in to Metacat"
    echo '**************************************'
    echo


    if [ "${MANUAL_UPGRADE}" != 1 ] ; then

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



            # Check if configured version is 2.12.3 or above as it's the starting version that supports
            #  upgrade_status field.
            if [  "$METACAT_VERSION_CONFIGURED" = "`echo -e "$METACAT_VERSION_CONFIGURED\n$UPGRADE_STATUS_ABILITY_PRE_VERSION" | \
            sort --version-sort | tail -n1`" ] && \
            [ "$METACAT_VERSION_CONFIGURED" != "$UPGRADE_STATUS_ABILITY_PRE_VERSION" ]; then

                # Wait until the upgrade is done.
                NEXT_WAIT_TIME=0
                UPGRADED=0
                until [ $UPGRADED -eq 1 ]; do

                   sleep $(( NEXT_WAIT_TIME++ ))

                   # Wait for total of 5 minutes (Sigma 24) seconds before timeout and
                   # increase wait time every time gradually.
                   if  [ $NEXT_WAIT_TIME -eq 24 ]; then
                        echo "****************************************************************************"
                        echo "******************************** ERROR *************************************"
                        echo "ERROR: The metacat upgrade is taking too long."
                        echo "   You may try to pass the MANUAL_UPGRADE variable in the docker-compose with 1 to upgrade "
                        echo "   metacat manually"
                        echo "****************************************************************************"
                        echo "****************************************************************************"
                        exit -1
                   fi

                   # Get Node capabilities from metacat
                   NODE_CAPABILITIES_XML=`curl --insecure -X GET http://localhost:8080/catalog/d1/mn/v2/node`
                   UPGRADE_STATUS=`xmllint --xpath '//property[@key="upgrade_status"]/text()' - <<< $NODE_CAPABILITIES_XML`
                   CURRENT_METACAT_VERSION=`xmllint --xpath '//property[@key="metacat_version"]/text()' - <<< $NODE_CAPABILITIES_XML`

                   if  [ "$UPGRADE_STATUS" = "success" ]; then
                        echo "***************************************************************************"
                        echo "************************* Upgrade successful ******************************"
                        echo "Metacat now finished the upgrade."
                        echo " Metacat upgraded version is ${CURRENT_METACAT_VERSION} "
                        echo "****************************************************************************"
                        echo "****************************************************************************"
                        UPGRADED=1
                   fi
                done

            else

               # if this is an older version than 2.12.3, sleep for 10 seconds until the upgrade finishes
               sleep 10

            fi


            echo
            echo '**************************************'
            echo "Waiting for Tomcat to stop "
            echo "after upgrade/initialization"
            echo '**************************************'
            echo

            # Shutdown tomcat background process taking hold of port 8080 and put it in the background
            # Saving tomcat PID in a file to be read by the shutdown script
            echo `ps h -C java -o "%p:%a" | grep catalina | cut -d: -f1` > /tmp/tomcat.pid
            CATALINA_PID=/tmp/tomcat.pid ./bin/catalina.sh stop 120 -force > /dev/null 2>&1 &

            echo
            echo '**************************************'
            echo "Waiting for ports 8080,8009,5701 to be released..."
            echo '**************************************'

            # Wait for ports  to be released (metacat, hazelcast and apr )
            #   NOTE: This does not perfectly tell us that tomcat is down but
            #   it is our best guess.  The catalina.sh script does not stop the
            #   tomcat process which makes it difficult to determine when tomcat is down.
            while nc -z localhost 8080 || nc -z localhost 8009 || nc -z localhost 5701; do
               sleep 0.1
            done

            echo
            echo '***********************************'
            echo "Upgraded/Initialized the metacat DB"
            echo "      RESTART the CONTAINER        "
            echo '***********************************'
            echo
            exit
        else
            echo
            echo '**************************************'
            echo "Metacat is already configured"
            echo '**************************************'
            echo
        fi

    else

        echo
        echo '**************************************'
        echo '**************************************'
        echo "Metacat is configured to be upgraded manually"
        echo "Please go to http://localhost:8080/${METACAT_APP_CONTEXT}/admin to upgrade metacat"
        echo '**************************************'
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


