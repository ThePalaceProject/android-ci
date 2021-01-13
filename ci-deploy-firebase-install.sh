#!/bin/bash

#------------------------------------------------------------------------
# A script to install Firebase.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-deploy-firebase-install.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-firebase-install.sh: info: $1" 1>&2
}

#------------------------------------------------------------------------

info "installing node modules"

npm install firebase-tools ||
  fatal "could not install node modules"

CI_FIREBASE_TOKEN=$(head -n 1 ".ci/credentials/Firebase/token.txt") ||
  fatal "could not read firebase token from credentials repository"
