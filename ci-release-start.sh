#!/bin/bash
#------------------------------------------------------------------------
# A script to start the development cycle for the next release.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-release-start.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-release-start.sh: info: $1" 1>&2
}

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

VERSION_NAME_PATTERN='^([0-9]+\.[0-9]+\.[0-9]+)(-SNAPSHOT)?$'
VERSION_NAME=`ci-version.sh` ||
  fatal "Could not determine project version"

if ! [[ $VERSION_NAME =~ $VERSION_NAME_PATTERN ]]; then
  fatal "Unable to parse project version name $VERSION_NAME"
fi

VERSION_NUM=${BASH_REMATCH[1]}
SNAPSHOT=${BASH_REMATCH[2]}

# Increment the bugfix number.
NEXT_VERSION_NUM=`echo ${VERSION_NUM} | awk -F. -v OFS=. '{$NF++;print}'`

info "Starting dev cycle for next release: $NEXT_VERSION_NUM"

if [ "$SNAPSHOT" = "-SNAPSHOT" ]; then
  fatal "Current project version is already a snapshot version"
fi

NEXT_SNAPSHOT_VERSION_NUM="${NEXT_VERSION_NUM}-SNAPSHOT"

info "Bumping project version to next snapshot version"

sed -E -i "s/VERSION_NAME=.*/VERSION_NAME=${NEXT_SNAPSHOT_VERSION_NUM}/" gradle.properties ||
  fatal "Could not bump project version"
sed -E -i "s/VERSION_PREVIOUS=.*/VERSION_PREVIOUS=${VERSION_NUM}/" gradle.properties ||
  fatal "Could not bump project previous version"
git add gradle.properties ||
  fatal "Could not add gradle.properties to index"

CHANGELOG_VERSION_NAME_PATTERN='^([0-9]+\.[0-9]+\.[0-9]+) \((.*)\)$'
CHANGELOG_VERSION_NAME=`java -jar "${CHANGELOG_JAR_NAME}" release-current --file "${CHANGE_FILE}"` ||
  fatal "Could not determine changelog version"

if ! [[ $CHANGELOG_VERSION_NAME =~ $CHANGELOG_VERSION_NAME_PATTERN ]]; then
  fatal "Unable to parse changelog version name $CHANGELOG_VERSION_NAME"
fi

CHANGELOG_VERSION_NUM=${BASH_REMATCH[1]}
CHANGELOG_STATE=${BASH_REMATCH[2]}

if [ "$CHANGELOG_STATE" = "open" ]; then
  fatal "Changelog is already open"
fi

info "Opening changelog for next version"

java -jar "${CHANGELOG_JAR_NAME}" release-begin --version "${NEXT_VERSION_NUM}" --file "${CHANGE_FILE}" ||
  fatal "Could not open changelog"
git add "${CHANGE_FILE}" ||
  fatal "Could not add changelog to index"

git config --global user.email "palace.ci@thepalaceproject.org" ||
  fatal "Could not configure git"
git config --global user.name "Palace CI" ||
  fatal "Could not configure git"

if ! git diff --staged --quiet; then
  info "Committing and pushing changes"

  git commit -m "Start development for next release." ||
    fatal "Could not commit changes"
  git push ||
    fatal "Could not push changes"
else
  info "No files changed"
fi
