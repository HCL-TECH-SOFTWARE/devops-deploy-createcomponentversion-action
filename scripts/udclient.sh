#!/bin/bash
# Run the udclient with the given arguments
#
# The following environment variables are REQUIRED to be set prior to invocation of the script:
# JAVA_HOME
# UDCLIENT_HOME
# DS_AUTH_TOKEN or DS_USERNAME/DS_PASSWORD
# DS_WEB_URL

# Unset empty credential variables so udclient only sees the authentication method that was provided
for var in DS_AUTH_TOKEN DS_USERNAME DS_PASSWORD
do
  if [ -z "${!var}" ]
  then
    unset "$var"
  fi
done

exec "$UDCLIENT_HOME/udclient" "$@"
