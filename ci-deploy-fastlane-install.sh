#!/bin/bash

#------------------------------------------------------------------------
# A script to install Fastlane.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-deploy-fastlane-install.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-fastlane-install.sh: info: $1" 1>&2
}

#------------------------------------------------------------------------

if [ -z "${GEM_HOME}" ]
then
  fatal "GEM_HOME is not defined"
fi

if [ $# -ne 1 ]
then
  fatal "usage: project"
fi

PROJECT="$1"
shift

cd "${PROJECT}" ||
  fatal "could not move to ${PROJECT}"

info "installing fastlane"

gem install --user-install bundler ||
  fatal "could not install bundler"
bundle install ||
  fatal "could not install fastlane"
bundle exec fastlane supply init < /dev/null ||
  fatal "could not initialize fastlane supply"
