#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy all Fastlane applications.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-deploy-firebase.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-firebase.sh: info: $1" 1>&2
}

#------------------------------------------------------------------------

if [ $# -lt 1 ]
then
  fatal "usage: project [project ...]"
fi

PROJECT_LIST="$1"

CI_BIN_DIRECTORY=$(realpath .ci) ||
  fatal "could not determine bin directory"

export GEM_HOME="${HOME}/gem"

info "installing gems to ${GEM_HOME}"

mkdir -p "${GEM_HOME}/bin" ||
  fatal "could not create gems directory"

export PATH="${PATH}:${CI_BIN_DIRECTORY}:${GEM_HOME}/bin:."

info "deploying ${PROJECT_LIST}"

for PROJECT in ${PROJECT_LIST}
do
  info "deploying ${PROJECT}"

  ci-deploy-fastlane-install.sh "${PROJECT}"

  if [ -f "${PROJECT}/fastlane-aab.conf" ]
  then
    ci-deploy-fastlane-aab.sh "${PROJECT}" ||
      fatal "could not deploy ${PROJECT} AAB to Fastlane"
  elif [ -f "${PROJECT}/fastlane-apk.conf" ]
  then
    ci-deploy-fastlane-apk.sh "${PROJECT}" ||
      fatal "could not deploy ${PROJECT} APK to Fastlane"
  fi
done
