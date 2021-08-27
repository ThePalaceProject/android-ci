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

if [ $# -ne 1 ]
then
  fatal "usage: project"
fi

PROJECT="$1"
shift

cd "${PROJECT}" ||
  fatal "could not move to ${PROJECT}"

info "installing fastlane"

CI_GEM_PATHS=$(gem environment gempaths | sed 's/:/ /g')

for CI_GEM_PATH in ${CI_GEM_PATHS}
do
  CI_EXTRA_BIN="${CI_GEM_PATH}/bin"
  info "adding ${CI_EXTRA_BIN} to PATH"
  export PATH="${PATH}:${CI_EXTRA_BIN}"
done

gem install --user-install bundler ||
  fatal "could not install bundler"

bundle install ||
  fatal "could not install fastlane"
bundle exec fastlane supply init --track alpha < /dev/null ||
  fatal "could not initialize fastlane supply"
