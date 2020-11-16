#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy releases to Maven Central.
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

#------------------------------------------------------------------------
# Publish the built artifacts to wherever they need to go.
#

DEPLOY_DIRECTORY="$(pwd)/deploy"
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

info "Creating a staging repository on Maven Central"

(cat <<EOF
create
--description
Simplified ${TIMESTAMP}
--stagingProfileId
${MAVEN_CENTRAL_STAGING_PROFILE_ID}
--user
${MAVEN_CENTRAL_USERNAME}
--password
${MAVEN_CENTRAL_PASSWORD}
EOF
) > args.txt || fatal "Could not write argument file"

MAVEN_CENTRAL_STAGING_REPOSITORY_ID=$(java -jar brooklime.jar @args.txt) || fatal "Could not create staging repository"

#------------------------------------------------------------------------
# Upload content to the staging repository on Maven Central.
#

info "Uploading content to repository ${MAVEN_CENTRAL_STAGING_REPOSITORY_ID}"

(cat <<EOF
upload
--stagingProfileId
${MAVEN_CENTRAL_STAGING_PROFILE_ID}
--user
${MAVEN_CENTRAL_USERNAME}
--password
${MAVEN_CENTRAL_PASSWORD}
--directory
${DEPLOY_DIRECTORY}
--repository
${MAVEN_CENTRAL_STAGING_REPOSITORY_ID}
--quiet
EOF
) > args.txt || fatal "Could not write argument file"

java -jar brooklime.jar @args.txt || fatal "Could not upload content"

#------------------------------------------------------------------------
# Close the staging repository.
#

info "Closing repository ${MAVEN_CENTRAL_STAGING_REPOSITORY_ID}. This can take a few minutes."

(cat <<EOF
close
--stagingProfileId
${MAVEN_CENTRAL_STAGING_PROFILE_ID}
--user
${MAVEN_CENTRAL_USERNAME}
--password
${MAVEN_CENTRAL_PASSWORD}
--repository
${MAVEN_CENTRAL_STAGING_REPOSITORY_ID}
EOF
) > args.txt || fatal "Could not write argument file"

java -jar brooklime.jar @args.txt || fatal "Could not close staging repository"

#------------------------------------------------------------------------
# Release the staging repository.
#

info "Releasing repository ${MAVEN_CENTRAL_STAGING_REPOSITORY_ID}"

(cat <<EOF
release
--stagingProfileId
${MAVEN_CENTRAL_STAGING_PROFILE_ID}
--user
${MAVEN_CENTRAL_USERNAME}
--password
${MAVEN_CENTRAL_PASSWORD}
--repository
${MAVEN_CENTRAL_STAGING_REPOSITORY_ID}
EOF
) > args.txt || fatal "Could not write argument file"

java -jar brooklime.jar @args.txt || fatal "Could not release staging repository"

info "Release completed"
