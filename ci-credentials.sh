#!/bin/bash

#------------------------------------------------------------------------
# A script to clone the Credentials repository and check that the required
# secrets are present and working.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-credentials.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-credentials.sh: info: $1" 1>&2
}

error()
{
  echo "ci-credentials.sh: error: $1" 1>&2
}

#------------------------------------------------------------------------
# Check environment
#

FAILED=0
if [ -z "${MAVEN_CENTRAL_USERNAME}" ]
then
  error "MAVEN_CENTRAL_USERNAME is not defined"
  FAILED=1
fi
if [ -z "${MAVEN_CENTRAL_PASSWORD}" ]
then
  error "MAVEN_CENTRAL_PASSWORD is not defined"
  FAILED=1
fi
if [ -z "${MAVEN_CENTRAL_STAGING_PROFILE_ID}" ]
then
  error "MAVEN_CENTRAL_STAGING_PROFILE_ID is not defined"
  FAILED=1
fi
if [ -z "${MAVEN_CENTRAL_SIGNING_KEY_ID}" ]
then
  error "MAVEN_CENTRAL_SIGNING_KEY_ID is not defined"
  FAILED=1
fi
if [ -z "${CI_GITHUB_ACCESS_TOKEN}" ]
then
  error "CI_GITHUB_ACCESS_TOKEN is not defined"
  FAILED=1
fi

if [ ${FAILED} -eq 1 ]
then
  fatal "One or more required variables are not defined."
fi

#------------------------------------------------------------------------
# Clone credentials repos
#

info "Cloning credentials"

git clone \
  --depth 1 \
  "https://${CI_GITHUB_ACCESS_TOKEN}@github.com/ThePalaceProject/mobile-certificates" \
  ".ci/credentials" || fatal "Could not clone credentials"

#------------------------------------------------------------------------
# Import the PGP key for signing Central releases, and try to sign a test
# file to check that the key hasn't expired.
#

info "Importing GPG key"
gpg --import ".ci/credentials/APK Signing/thePalaceProject.asc" || fatal "Could not import GPG key"

info "Signing test file"
echo "Test" > hello.txt || fatal "Could not create test file"
gpg --sign -a hello.txt || fatal "Could not produce test signature"

#------------------------------------------------------------------------
# Download jreleaser if necessary.
#

ci-install-jreleaser.sh || fatal "Failed to install jreleaser"

#------------------------------------------------------------------------
# Download changelog if necessary.
#

ci-install-changelog.sh || fatal "Failed to install changelog"

#------------------------------------------------------------------------
# Run local credentials hooks if present.
#

if [ -f .ci-local/credentials.sh ]
then
  .ci-local/credentials.sh || fatal "local credentials hook failed"
fi
