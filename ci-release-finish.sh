#!/bin/bash
#------------------------------------------------------------------------
# A script to finish the current development cycle.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-release-finish.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-release-finish.sh: info: $1" 1>&2
}

#------------------------------------------------------------------------

CI_BIN_DIRECTORY=$(realpath .ci) ||
  fatal "Could not determine bin directory"

export PATH="${PATH}:${CI_BIN_DIRECTORY}:."

#------------------------------------------------------------------------
# Download changelog if necessary.
#

ci-install-changelog.sh || fatal "Failed to install changelog"

CHANGELOG_JAR_NAME="changelog.jar"
CHANGE_FILE="README-CHANGES.xml"

#------------------------------------------------------------------------

git config --global user.email "palace.ci@thepalaceproject.org" ||
  fatal "Could not configure git"
git config --global user.name "Palace CI" ||
  fatal "Could not configure git"

PROJECT_VERSION_NAME_PATTERN='^([0-9]+\.[0-9]+\.[0-9]+)(-[a-z0-9]+)?$'
PROJECT_VERSION_NAME=$(ci-version.sh) ||
  fatal "Could not determine project version"

info "Project version: ${PROJECT_VERSION_NAME}"

# Check that the project version is in the permitted format.
if ! [[ "${PROJECT_VERSION_NAME}" =~ ${PROJECT_VERSION_NAME_PATTERN} ]]; then
  fatal "Unable to parse project version name ${PROJECT_VERSION_NAME}"
fi

# Break the version into the number and the qualifier, and reject -SNAPSHOT versions.
PROJECT_VERSION_NUMBER=${BASH_REMATCH[1]}
PROJECT_VERSION_QUALIFIER=${BASH_REMATCH[2]}

if [ "${PROJECT_VERSION_QUALIFIER}" = "-SNAPSHOT" ]
then
  fatal "${PROJECT_VERSION_QUALIFIER} is -SNAPSHOT; please set the proper release version in gradle.properties"
fi

# Check that the current branch is named correctly for the release.
if [ "$GITHUB_REF_TYPE" = "branch" ]; then
  RELEASE_BRANCH_NAME_PATTERN='^release/(.*)$'

  if [[ "$GITHUB_REF_NAME" =~ $RELEASE_BRANCH_NAME_PATTERN ]]; then
    BRANCH_VERSION_NUM=${BASH_REMATCH[1]}

    if ! [ "${PROJECT_VERSION_NAME}" = "$BRANCH_VERSION_NUM" ]; then
      fatal "Project version ${PROJECT_VERSION_NAME} does not match release branch version $BRANCH_VERSION_NUM"
    fi
  fi
fi

# Set the changelog version and close the release.
java -jar "${CHANGELOG_JAR_NAME}" release-set-version --version "${PROJECT_VERSION_NAME}" --file "${CHANGE_FILE}" ||
  fatal "Could not set changelog version"
java -jar "${CHANGELOG_JAR_NAME}" release-finish --file "${CHANGE_FILE}" ||
  fatal "Could not close changelog"
git add "${CHANGE_FILE}" ||
  fatal "Could not add changelog to index"

# Create a tag for the commit.
TAG_PREFIX=$(head -n 1 ".ci-local/tag-prefix.conf") ||
  fatal "Could not read .ci-local/tag-prefix.conf"

TAG_NAME="${TAG_PREFIX}-${PROJECT_VERSION_NAME}"

git commit -m "Finish ${PROJECT_VERSION_NAME} release." ||
  fatal "Could not commit changes."
git tag -a "${TAG_NAME}" -m "Release ${PROJECT_VERSION_NAME}" ||
  fatal "Could not tag release"
git push origin "${TAG_NAME}" ||
  fatal "Could not push release tag."

# Write the plain text changelog to a file so that the Fastlane deployment can use it.
RELEASE_NOTES_PATH="changes-${PROJECT_VERSION_NAME}.txt"

ci-changelog.sh "${CHANGELOG_JAR_NAME}" "${CHANGE_FILE}" > "$RELEASE_NOTES_PATH" ||
  fatal "Could not generate changelog"

echo "RELEASE_NOTES_PATH=$RELEASE_NOTES_PATH" >> $GITHUB_ENV
echo "VERSION_NUM=$PROJECT_VERSION_NAME" >> $GITHUB_ENV
echo "TAG_NAME=$TAG_NAME" >> $GITHUB_ENV
