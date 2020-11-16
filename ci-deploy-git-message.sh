#!/bin/bash

#------------------------------------------------------------------------
# A script to generate a git commit message.
#

#------------------------------------------------------------------------
# Utility methods

fatal()
{
  echo "ci-deploy-git-message.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-git-message.sh: info: $1" 1>&2
}

if [ $# -ne 1 ]
then
  fatal "usage: version.properties
  Where: version.properties is a Java properties file containing a versionCode property
"
fi

VERSION_FILE="$1"
shift

GIT_SOURCE_REPOS=$(head -n 1 ".ci-local/deploy-git-binary-source.conf") ||
  fatal "could not read .ci-local/deploy-git-source.conf"
GP_GIT_COMMIT=$(git rev-list --max-count=1 HEAD) ||
  fatal "could not determine git commit"
VERSION_CODE=$(grep versionCode "${VERSION_FILE}" | sed 's/versionCode=//g') ||
  fatal "could not determine version code"

cat <<EOF
Build of ${GP_GIT_COMMIT}
Git commit: ${GP_GIT_COMMIT}
Version code: ${VERSION_CODE}
Commit link: ${GIT_SOURCE_REPOS}/commit/${GP_GIT_COMMIT}
EOF