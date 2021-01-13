#!/bin/bash

#------------------------------------------------------------------------
# A script to generate changelogs.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-changelog.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-changelog.sh: info: $1" 1>&2
}

#------------------------------------------------------------------------

if [ $# -ne 2 ]
then
  fatal "usage: changelog.jar README_CHANGES.xml"
fi

JAR_NAME="$1"
shift
CHANGE_FILE="$1"
shift

cat <<EOF
Changes since the last production release:

EOF

exec java -jar "${JAR_NAME}" write-plain --file "${CHANGE_FILE}" | egrep -v '^Release: ' | sed 's/^Change: /* /g'