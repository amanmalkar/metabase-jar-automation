#!/bin/bash

#config file has details required for initial setup and ssl cert generation
source config

#check if java installed on host
if type -p java; then
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    _java="$JAVA_HOME/bin/java"
else
    echo "java not found please install java 1.8 or higher to run metabase"
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    if [[ "$version" < "1.8" ]]; then
        echo "please install java 1.8 or higher to run metabase"
	exit 1
    else         
	java -jar metabase.jar >> output.log 2>&1 &
	Metabase_PID=$!
    fi
fi

#Check if metabase initialization complete
tail -f output.log | while read LOGLINE
do
   [[ "${LOGLINE}" == *"Metabase Initialization COMPLETE"* ]] && pkill -P $$ tail
done

#Grab token required for initial setup
token=$(curl -s -X GET -H "Content-Type: application/json" http://localhost:3000/api/session/properties | python2.7 -c 'import sys, json; print json.load(sys.stdin)["setup_token"]' | tail -1)

#Initial setup api
curl -X POST -H "Content-Type: application/json" -d '{ "token": "'$token'","database": {"name": "metabasedb", "engine": "postgres", "details": {"host": "localhost", "port": "5432", "dbname": "postgres", "user": "<your-username>", "password": "<your-password>", "ssl": false}, "is_full_sync": true, "is_on_demand": false}, "user": {"first_name": "'$first_name'", "last_name": "'$last_name'", "email": "'$email'", "password": "'$password'"},"prefs": {"allow_tracking": false, "site_name": "'$site_name'"}}' http://localhost:3000/api/setup

#generate self signed ssl certificate for https
keytool -genkey -dname "cn="'$name'", ou="'$business_unit'", o="'$organization'",c="'$country'"" -alias "'$domain'" -storepass "'$storepass'" -keyalg RSA -keystore tempCert.jks -keysize 2048 -keypass "'$keypass'"

export MB_JETTY_SSL="true"
export MB_JETTY_SSL_Port="8443"
export MB_JETTY_SSL_Keystore="tempCert.jks"
export MB_JETTY_SSL_Keystore_Password="'$storepass'"

#restart metabase on https
kill $Metabase_PID

export MB_DB_TYPE=postgres
export MB_DB_DBNAME=postgres
export MB_DB_PORT=5432
export MB_DB_USER=sensei
export MB_DB_PASS=aman7030
export MB_DB_HOST=localhost

java -jar metabase.jar >> output.log 2>&1 &
Metabase_PID=$!
echo "Metabase is running : go to https://localhost:8443 to login!"
echo "type kill ${Metabase_PID} in the terminal to terminate Metabase"
