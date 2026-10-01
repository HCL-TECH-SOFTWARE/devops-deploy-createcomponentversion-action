#!/bin/bash
# Use udclient to add files to a component version
#
# The following environment variables are REQUIRED to be set prior to invocation of the script:
# JAVA_HOME
# DS_AUTH_TOKEN or DS_USERNAME/DS_PASSWORD
# DS_WEB_URL
# FILES_CMD
# FILES_COMPONENTNAME
# FILES_VERSIONNAME
# FILES_BASE
#
# The following environment variables can be OPTIONALLY set prior to invocation of the script:
# FILES_OFFSET
# FILES_INCLUDE (new-line separated patterns)
# FILES_EXCLUDE (new-line separated patterns)
# FILES_SAVEEXECUTEBITS

#set -x

# Create the command to execute
if [ -z "$FILES_CMD" ]
then
  echo "udclient command not specified.  Exiting."
  exit 1
fi
cmd=("$FILES_CMD" addVersionFiles)

# Specify component name
if [ -z "$FILES_COMPONENTNAME" ]
then
  echo "Component name not specified.  Exiting."
  exit 1
fi
cmd+=(-component "$FILES_COMPONENTNAME")

# Specify component version name
if [ -z "$FILES_VERSIONNAME" ]
then
  echo "Version name not specified.  Exiting."
  exit 1
fi
cmd+=(-version "$FILES_VERSIONNAME")

# Specify local path
if [ -z "$FILES_BASE" ]
then
  echo "No base files specified. Exiting."
  exit 1
fi
cmd+=(-base "$FILES_BASE")

# Specify target path
if [ -n "$FILES_OFFSET" ]
then
  cmd+=(-offset "$FILES_OFFSET")
fi

# Specify include pattern(s), one per line
while IFS= read -r pattern
do
  if [ -n "$pattern" ]
  then
    cmd+=(-include "$pattern")
  fi
done <<< "$FILES_INCLUDE"

# Specify exclude pattern(s), one per line
while IFS= read -r pattern
do
  if [ -n "$pattern" ]
  then
    cmd+=(-exclude "$pattern")
  fi
done <<< "$FILES_EXCLUDE"

# Specify whether or not to save execute bits on the files
if [ -n "$FILES_SAVEEXECUTEBITS" ]
then
  cmd+=(-saveExecuteBits "$FILES_SAVEEXECUTEBITS")
fi

# Invoke the udclient to add version files to the component version
"${cmd[@]}"
