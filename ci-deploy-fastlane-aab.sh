#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy a single Fastlane application.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-deploy-fastlane-aab.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-fastlane-aab.sh: info: $1" 1>&2
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

CI_GEM_PATHS=$(gem environment gempaths | sed 's/:/ /g')
for CI_GEM_PATH in ${CI_GEM_PATHS}
do
  CI_EXTRA_BIN="${CI_GEM_PATH}/bin"
  info "adding ${CI_EXTRA_BIN} to PATH"
  export PATH="${PATH}:${CI_EXTRA_BIN}"
done

CI_FASTLANE_AAB=$(head -n 1 "fastlane-aab.conf") ||
  fatal "could not read fastlane-aab.conf"

CI_CHANGELOG_OUTPUT_DIRECTORY="fastlane/metadata/android/en-US/changelogs"
CI_CHANGELOG_OUTPUT_FILE="${CI_CHANGELOG_OUTPUT_DIRECTORY}/default.txt"

mkdir -p ${CI_CHANGELOG_OUTPUT_DIRECTORY} ||
  fatal "could not create directory"

ci-changelog.sh "${START_DIRECTORY}/changelog.jar" "${START_DIRECTORY}/README-CHANGES.xml" > "${CI_CHANGELOG_OUTPUT_FILE}" ||
  fatal "could not generate changelog"

bundle exec fastlane supply --aab "${CI_FASTLANE_AAB}" --track alpha < /dev/null ||
  fatal "could not upload AAB"
