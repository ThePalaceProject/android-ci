#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy binaries to various locations.
#

#------------------------------------------------------------------------
# Utility methods

fatal()
{
  echo "ci-deploy.sh: fatal: $1" 1>&2
  exit 1
}

FAILED=0

error()
{
  echo "ci-deploy.sh: error: $1" 1>&2
  FAILED=1
}

info()
{
  echo "ci-deploy.sh: info: $1" 1>&2
}

export PATH="${PATH}:.ci:."

#------------------------------------------------------------------------
# Determine version and whether or not this is a snapshot.
#

VERSION_NAME=$(ci-version.sh) || fatal "Could not determine project version"
VERSION_TYPE=none

echo "${VERSION_NAME}" | grep -E -- '-SNAPSHOT$'
if [ $? -eq 0 ]
then
  VERSION_TYPE=snapshot
else
  VERSION_TAG=$(git describe --tags HEAD --exact-match 2>/dev/null)
  if [ -n "${VERSION_TAG}" ]
  then
    VERSION_TYPE=tag
  fi
fi

info "Version to be deployed is ${VERSION_NAME}"

#------------------------------------------------------------------------
# Publish the built artifacts to wherever they need to go.
#

case ${VERSION_TYPE} in
  none)
    info "Current version is not a snapshot, and there is no tag"
    ;;
  snapshot)
    ci-deploy-central-snapshot.sh "${VERSION_NAME}" ||
      error "could not deploy snapshot"
    ci-deploy-git-binaries.sh ||
      error "could not deploy git binaries"
    ;;
  tag)
    ci-deploy-central-release.sh "${VERSION_NAME}" ||
      error "could not deploy release"
    ci-deploy-git-binaries.sh ||
      error "could not deploy git binaries"
    ci-deploy-fastlane-conditionally.sh ||
      error "could not deploy to Fastlane"
    ;;
esac

ci-deploy-firebase-conditionally.sh "${FIREBASE_APPLICATIONS}" ||
  error "could not deploy Firebase builds"

#------------------------------------------------------------------------
# Check if any of the above failed, and give up if they did.

if [ ${FAILED} -eq 1 ]
then
  fatal "one or more deployment steps failed"
fi

#------------------------------------------------------------------------
# Run local deploy hooks if present.
#

if [ -f .ci-local/deploy.sh ]
then
  .ci-local/deploy.sh || fatal "local deploy hook failed"
fi
