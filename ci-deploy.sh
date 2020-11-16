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
    info "Current version is not a snapshot, and there is no tag. Exiting."
    exit 0
    ;;
  snapshot)
    ci-deploy-central-snapshot.sh "${VERSION_NAME}"
    ci-deploy-git-binaries.sh
    ;;
  tag)
    ci-deploy-central-release.sh "${VERSION_NAME}"
    ci-deploy-git-binaries.sh
    ;;
esac
