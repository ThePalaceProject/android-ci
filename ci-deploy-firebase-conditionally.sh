#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy to Firebase (conditionally) to various locations.
#

#------------------------------------------------------------------------
# Utility methods

fatal()
{
  echo "ci-deploy-firebase-conditionally.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-firebase-conditionally.sh: info: $1" 1>&2
}

export PATH="${PATH}:.ci:."

#------------------------------------------------------------------------
# Run Firebase if configured.
#

if [ -f ".ci-local/deploy-firebase-apps.conf" ]
then
  FIREBASE_APPLICATIONS=$(egrep -v '^#' ".ci-local/deploy-firebase-apps.conf") ||
    fatal "could not list firebase applications"
  ci-deploy-firebase.sh "${FIREBASE_APPLICATIONS}" ||
    fatal "could not deploy firebase builds"
fi
