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

#------------------------------------------------------------------------
# Check environment
#

if [ -z "${MAVEN_CENTRAL_USERNAME}" ]
then
  fatal "MAVEN_CENTRAL_USERNAME is not defined"
fi
if [ -z "${MAVEN_CENTRAL_PASSWORD}" ]
then
  fatal "MAVEN_CENTRAL_PASSWORD is not defined"
fi
if [ -z "${MAVEN_CENTRAL_STAGING_PROFILE_ID}" ]
then
  fatal "MAVEN_CENTRAL_STAGING_PROFILE_ID is not defined"
fi
if [ -z "${MAVEN_CENTRAL_SIGNING_KEY_ID}" ]
then
  fatal "MAVEN_CENTRAL_SIGNING_KEY_ID is not defined"
fi
if [ -z "${CI_GITHUB_ACCESS_TOKEN}" ]
then
  fatal "CI_GITHUB_ACCESS_TOKEN is not defined"
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
# Download Brooklime if necessary.
#

BROOKLIME_URL="https://repo1.maven.org/maven2/com/io7m/brooklime/com.io7m.brooklime.cmdline/2.0.1/com.io7m.brooklime.cmdline-2.0.1-main.jar"
BROOKLIME_SHA256_EXPECTED="eb77e7459f3ece239f68e0b634be6cf9f8b57d6c18f0a2bce1cd6a06c611a3ff"

wget -O "brooklime.jar.tmp" "${BROOKLIME_URL}" || fatal "Could not download brooklime"
mv "brooklime.jar.tmp" "brooklime.jar" || fatal "Could not rename brooklime"

BROOKLIME_SHA256_RECEIVED=$(openssl sha256 "brooklime.jar" | awk '{print $NF}') || fatal "Could not checksum brooklime.jar"

if [ "${BROOKLIME_SHA256_EXPECTED}" != "${BROOKLIME_SHA256_RECEIVED}" ]
then
  fatal "brooklime.jar checksum does not match.
  Expected: ${BROOKLIME_SHA256_EXPECTED}
  Received: ${BROOKLIME_SHA256_RECEIVED}"
fi

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
