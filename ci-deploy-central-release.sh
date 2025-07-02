#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy releases to Maven Central.
#

#------------------------------------------------------------------------
# Utility methods

fatal()
{
  echo "ci-deploy-central-release.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-central-release.sh: info: $1" 1>&2
}

if [ $# -ne 1 ]
then
  fatal "usage: version"
fi

if [ ! -f ".ci-local/deploy-maven-central.conf" ]
then
  info ".ci-local/deploy-maven-central.conf does not exist, will not deploy binaries"
  exit 0
fi

if [ ! -f "jreleaser.toml" ]
then
  info "jreleaser.toml does not exist"
  exit 1
fi

#------------------------------------------------------------------------
# Publish the built artifacts to wherever they need to go.
#

DEPLOY_DIRECTORY="$(pwd)/build/maven"
info "Artifacts will temporarily be deployed to ${DEPLOY_DIRECTORY}"
rm -rf "${DEPLOY_DIRECTORY}" || fatal "Could not ensure temporary directory is clean"
mkdir -p "${DEPLOY_DIRECTORY}" || fatal "Could not create a temporary directory"

info "Executing tagged release deployment"
./gradlew \
  -PmavenCentralUsername="${MAVEN_CENTRAL_USERNAME}" \
  -PmavenCentralPassword="${MAVEN_CENTRAL_PASSWORD}" \
  -Psigning.gnupg.executable=gpg \
  -Psigning.gnupg.useLegacyGpg=false \
  -Psigning.gnupg.keyName="${MAVEN_CENTRAL_SIGNING_KEY_ID}" \
  -Porg.librarysimplified.directory.publish="${DEPLOY_DIRECTORY}" \
  -Dorg.gradle.internal.publish.checksums.insecure=true \
  publish || fatal "Could not publish"

info "Checking signatures were created"
SIGNATURE_COUNT=$(find "${DEPLOY_DIRECTORY}" -type f -name '*.asc' | wc -l) || fatal "Could not list signatures"
info "Generated ${SIGNATURE_COUNT} signatures"
if [ "${SIGNATURE_COUNT}" -lt 2 ]
then
  fatal "Too few signatures were produced! check the Gradle/PGP setup!"
fi

#------------------------------------------------------------------------
# Create a staging repository on Maven Central.
#

info "Executing jreleaser"

env \
JRELEASER_MAVENCENTRAL_USERNAME="${MAVEN_CENTRAL_USERNAME}" \
JRELEASER_MAVENCENTRAL_PASSWORD="${MAVEN_CENTRAL_PASSWORD}" \
./jreleaser deploy --config-file=jreleaser.toml ||
  fatal "jreleaser failed"
