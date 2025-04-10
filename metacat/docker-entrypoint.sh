#!/usr/bin/env bash

set -e
DEBUG=${DEBUG:0}

sed -i.bak "s/^rootLogger.level=.*/rootLogger.level=INFO/" /usr/local/tomcat/webapps/metacat/WEB-INF/classes/log4j2.properties

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
    echo "Waiting for Solr to start "
    echo '**************************************'
    echo
    while ! nc -z "${DB_SOLR_HOST:-db-solr}" "${DB_SOLR_PORT:-8983}"; do
      sleep 0.1
    done

    echo
    echo '**************************************'
    echo "Logrotating catalina.out"
    echo '**************************************'
    echo
    /usr/sbin/logrotate -s /usr/local/tomcat/logs/logrotate-status.log /etc/logrotate.d/metacat.conf &

    METACAT_DEFAULT_DIR="/usr/local/tomcat/webapps/metacat"
    METACAT_DIR="/usr/local/tomcat/webapps/${METACAT_APP_CONTEXT}"
    METACATUI_BASE_SKIN_PATH="/usr/local/tomcat/webapps/catalog/style/skins/metacatui"

    # The following constant defines the last version before the metacat version that supports the upgrade status
    # ability in metacat node capabilities. This is used to enable the script to learn when to use the node capability
    UPGRADE_STATUS_ABILITY_PRE_VERSION=2.12.2

    # Check the context
    if [ "${METACAT_DIR}" != "${METACAT_DEFAULT_DIR}" ] ;
    then
        # Move the application to match the context
        echo "Changing context to ${METACAT_APP_CONTEXT}"
        mv $METACAT_DEFAULT_DIR $METACAT_DIR

    fi

    DEFAULT_PROPERTIES_FILE=/var/metacat/config/metacat-site.properties
    APP_PROPERTIES_FILE=${APP_PROPERTIES_FILE:-/config/app.properties}
    METACATUI_CUSTOM_SKINS_PATH=/tmp/skins


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

                cp -Rv ${skin_path} ${METACAT_DIR}/style/skins/

                if [ ! -f ${METACAT_DIR}/style/skins/${skin_name}/${skin_name}.properties ]; then
                  cat $METACATUI_BASE_SKIN_PATH/metacatui.properties >> ${METACAT_DIR}/style/skins/${skin_name}/${skin_name}.properties
                fi

                if [ ! -f ${METACAT_DIR}/style/skins/${skin_name}/${skin_name}.properties.metadata.xml ]; then
                  cp -v $METACATUI_BASE_SKIN_PATH/metacatui.properties.metadata.xml ${METACAT_DIR}/style/skins/${skin_name}/${skin_name}.properties.metadata.xml
                fi

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

    # Look for the osti elink username file
    if [  ! -z "$OSTI_ELINK_USERNAME_FILE"  ] && [ -s $OSTI_ELINK_USERNAME_FILE ];then
        export OSTI_ELINK_USERNAME=`cat $OSTI_ELINK_USERNAME_FILE`
    fi

    # Look for the osti elink password file
    if [  ! -z "$OSTI_ELINK_PASSWORD_FILE"  ] && [ -s $OSTI_ELINK_PASSWORD_FILE ];then
        export OSTI_ELINK_PASSWORD=`cat $OSTI_ELINK_PASSWORD_FILE`
    fi

    # Make sure all default directories are available and owned by metacat
    [ `stat -c '%U:%G' /var/metacat`      = 'metacat:metacat' ] || chown metacat:metacat /var/metacat

    mkdir -p /var/metacat/data \
        /var/metacat/inline-data \
        /var/metacat/documents \
        /var/metacat/temporary \
        /var/metacat/logs \
        /var/metacat/solr-temp \
        /var/metacat/config
    touch /var/metacat/config/metacat-site.properties

    # Look for the properties file
    if [ -s $APP_PROPERTIES_FILE ];
    then
        # check md5sum of the files before copying overwriting the file with cp
        if [ `envsubst < $APP_PROPERTIES_FILE | md5sum | awk '{ print $1 }'` == `md5sum "$DEFAULT_PROPERTIES_FILE" | awk '{ print $1 }'` ];
        then
            echo
            echo '**********************************************************'
            echo "The application properties file ($APP_PROPERTIES_FILE) is the same as "
            echo 'default metacat.properties'
            echo '***********************************************************'
            echo
        else
            # Overwrite properties file with the default properties file
            echo
            echo '**********************************************************'
            echo "Overwriting with /var/metacat/config/metacat-site.properties"
            echo 'with ${APP_PROPERTIES_FILE} '
            echo '***********************************************************'
            echo

            # create a timestamped backup of the default properties file
            cp -v $DEFAULT_PROPERTIES_FILE ${DEFAULT_PROPERTIES_FILE}_`date +%Y%m%d%H%M%S`
            # perform variable substitution on the properties file and copy it to the default properties file
            envsubst < $APP_PROPERTIES_FILE > $DEFAULT_PROPERTIES_FILE
        fi


    elif [ "$APP_PROPERTIES_FILE" != "/config/app.properties" ];
    then

        echo "ERROR: The application properties file ($APP_PROPERTIES_FILE) was empty"
        echo "   or does not exist. Please check the $APP_PROPERTIES_FILE is"
        echo "   exists in the container filesystem."
        exit -2
    fi



    # Look for Tomcat Configuration to copy
    if [ -d /config/conf ];
    then
        for f in /config/conf/*;
        do
            echo "Copying $f to /usr/local/tomcat/conf"
            cp $f /usr/local/tomcat/conf
        done
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


fi

exec tail -f /usr/local/tomcat/logs/catalina.out


