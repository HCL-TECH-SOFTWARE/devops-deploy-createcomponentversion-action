#!/bin/bash
# Use udclient to add properties to a component version
#
# The following environment variables are REQUIRED to be set prior to invocation of the script:
# JAVA_HOME
# DS_AUTH_TOKEN or DS_USERNAME/DS_PASSWORD
# DS_WEB_URL
# VERSION_PROPERTIES_CMD
# VERSION_PROPERTIES_COMPONENTNAME
# VERSION_PROPERTIES_VERSIONNAME
# VERSION_PROPERTIES

#set -x

# Create the command to execute
if [ -z "$VERSION_PROPERTIES_CMD" ]
then
  echo "udclient command not specified.  Exiting."
  exit 1
fi
base_cmd=("$VERSION_PROPERTIES_CMD" setVersionProperty)

# Specify component name
if [ -z "$VERSION_PROPERTIES_COMPONENTNAME" ]
then
  echo "Component name not specified.  Exiting."
  exit 1
fi
base_cmd+=(-component "$VERSION_PROPERTIES_COMPONENTNAME")

# Specify component version name
if [ -z "$VERSION_PROPERTIES_VERSIONNAME" ]
then
  echo "Version name not specified.  Exiting."
  exit 1
fi
base_cmd+=(-version "$VERSION_PROPERTIES_VERSIONNAME")

# Check to make sure that at least 1 version property was specified
if [ -z "$VERSION_PROPERTIES" ]
then
  echo "version properties not specified.  Exiting."
  exit 1
fi

# Loop through new-line delineated component version properties and invoke CLI for each property definition.
# Each line is name:value:secure. The name is everything before the first ':' and the secure setting is
# everything after the last ':', so the value itself may contain ':' (e.g. URLs).
while IFS= read -r line
do
    # Skip blank lines
    if [ -z "$line" ]
    then
      continue
    fi
    key="${line%%:*}"
    secure="${line##*:}"
    value="${line#*:}"
    value="${value%:*}"
    if [ -z "$key" ]
    then
      echo "Property name not specified.  Exiting."
      exit 1
    fi
    if [ "$key" = "$line" ] || [ "$value" = "${line#*:}" ] || [ -z "$value" ]
    then
      echo "Property value not specified for property '$key'.  Exiting."
      exit 1
    fi
    if [ "$secure" != "true" ] && [ "$secure" != "false" ]
    then
      echo "Property secure setting for property '$key' must be true or false.  Exiting."
      exit 1
    fi
    "${base_cmd[@]}" -name "$key" -value "$value" -isSecure "$secure" || exit 1
done <<< "$VERSION_PROPERTIES"
