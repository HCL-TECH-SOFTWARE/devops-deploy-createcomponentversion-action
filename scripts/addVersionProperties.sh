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
# All lines are checked before any property is set, so a mistake leaves the version unchanged.
# Error messages name the property and line but never print the value, which may be a secret.
names=()
values=()
secures=()
line_number=0
while IFS= read -r line
do
    line_number=$((line_number + 1))
    # Ignore Windows line endings
    line="${line%$'\r'}"
    # Skip blank lines
    if [[ "$line" =~ ^[[:space:]]*$ ]]
    then
      continue
    fi
    key="${line%%:*}"
    secure="${line##*:}"
    value="${line#*:}"
    value="${value%:*}"
    if [ -z "$key" ]
    then
      echo "::error::The property on line $line_number has no name. Each line must be in the format name:value:secure."
      exit 1
    fi
    # Fewer than two ':' separators means the value or the secure setting is missing
    if [ "$key" = "$line" ] || [ "$value" = "${line#*:}" ]
    then
      echo "::error::Property '$key' (line $line_number) must be in the format name:value:secure. If the value comes from a multi-line expression such as a commit message, use only its first line."
      exit 1
    fi
    if [ -z "$value" ]
    then
      echo "::error::Property '$key' (line $line_number) has an empty value."
      exit 1
    fi
    if [ "$secure" != "true" ] && [ "$secure" != "false" ]
    then
      echo "::error::Property '$key' (line $line_number) must end with :true or :false (the secure setting)."
      exit 1
    fi
    names+=("$key")
    values+=("$value")
    secures+=("$secure")
done <<< "$VERSION_PROPERTIES"

for i in "${!names[@]}"
do
    "${base_cmd[@]}" -name "${names[$i]}" -value "${values[$i]}" -isSecure "${secures[$i]}" || exit 1
done
