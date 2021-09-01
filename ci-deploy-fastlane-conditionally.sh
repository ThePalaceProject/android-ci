#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy to Fastlane (conditionally) to various locations.
#

#------------------------------------------------------------------------
# Utility methods

fatal()
{
  echo "ci-deploy-fastlane-conditionally.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-fastlane-conditionally.sh: info: $1" 1>&2
}

export PATH="${PATH}:.ci:."

#------------------------------------------------------------------------
# Run Fastlane if configured.
#

if [ -f ".ci-local/deploy-fastlane-apps.conf" ]
then
  FASTLANE_APPLICATIONS=$(egrep -v '^#' ".ci-local/deploy-fastlane-apps.conf") ||
    fatal "could not list fastlane applications"
  ci-deploy-fastlane.sh "${FASTLANE_APPLICATIONS}" ||
    fatal "could not deploy fastlane builds"
fi
