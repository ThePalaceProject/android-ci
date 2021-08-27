#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy a single Fastlane application.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-deploy-firebase-apk.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-firebase-apk.sh: info: $1" 1>&2
}

#------------------------------------------------------------------------

if [ $# -ne 1 ]
then
  fatal "usage: project"
fi

PROJECT="$1"
shift

CI_BIN_DIRECTORY=$(realpath .ci) ||
  fatal "could not determine bin directory"

export PATH="${PATH}:${CI_BIN_DIRECTORY}:."

START_DIRECTORY=$(pwd) ||
  fatal "could not retrieve starting directory"
cd "${PROJECT}" ||
  fatal "could not switch to project directory"
