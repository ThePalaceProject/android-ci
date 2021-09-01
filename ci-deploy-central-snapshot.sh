#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy snapshots to Sonatype Snapshots.
#

#------------------------------------------------------------------------
# Utility methods

fatal()
{
  echo "ci-deploy-central-snapshot.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-central-snapshot.sh: info: $1" 1>&2
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

info "Executing snapshot deployment"
./gradlew \
  -PmavenCentralUsername="${MAVEN_CENTRAL_USERNAME}" \
  -PmavenCentralPassword="${MAVEN_CENTRAL_PASSWORD}" \
  -Psigning.gnupg.executable=gpg \
  -Psigning.gnupg.useLegacyGpg=false \
  -Psigning.gnupg.keyName="${MAVEN_CENTRAL_SIGNING_KEY_ID}" \
  -Dorg.gradle.internal.publish.checksums.insecure=true \
  publish || fatal "Could not publish snapshot"
