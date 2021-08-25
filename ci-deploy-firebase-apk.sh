#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy a single Firebase application.
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

NODE_MODULES_BIN=$(realpath node_modules/.bin) ||
  fatal "node modules are not installed"

CI_FIREBASE="${NODE_MODULES_BIN}/firebase"

CI_FIREBASE_TOKEN=$(head -n 1 ".ci/credentials/Firebase/token.txt") ||
  fatal "could not read firebase token from credentials repository"

START_DIRECTORY=$(pwd) ||
  fatal "could not retrieve starting directory"
cd "${PROJECT}" ||
  fatal "could not switch to project directory"

CI_FIREBASE_APK=$(head -n 1 "firebase-apk.conf") ||
  fatal "could not read firebase-apk.conf"
CI_FIREBASE_APP_ID=$(head -n 1 "firebase-app-id.conf") ||
  fatal "could not read firebase-app-id.conf"
CI_FIREBASE_GROUPS=$(head -n 1 "firebase-groups.conf") ||
  fatal "could not read firebase-groups.conf"
CI_FIREBASE_APK=$(realpath "${CI_FIREBASE_APK}") ||
  fatal "could not resolve APK"

info "firebase: APK:    ${CI_FIREBASE_APK}"
info "firebase: app:    ${CI_FIREBASE_APP_ID}"
info "firebase: groups: ${CI_FIREBASE_GROUPS}"

CI_FIREBASE_APK_SIZE=$(wc -c "${CI_FIREBASE_APK}" | cut -d' ' -f1) ||
  fatal "could not determine APK size"
if [ "${CI_FIREBASE_APK_SIZE}" == "0" ]
then
  fatal "attempted to submit a zero-size APK file"
fi

ci-changelog.sh "${START_DIRECTORY}/changelog.jar" "${START_DIRECTORY}/README-CHANGES.xml" > changes.txt ||
  fatal "could not generate changelog"

exec "${CI_FIREBASE}" appdistribution:distribute \
  --token "${CI_FIREBASE_TOKEN}" \
  --release-notes-file changes.txt \
  --app "${CI_FIREBASE_APP_ID}" \
  --groups "${CI_FIREBASE_GROUPS}" \
  "${CI_FIREBASE_APK}"
