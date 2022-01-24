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

if [[ $# > 1 || ($# == 1 && "$1" != "--tag") ]]
then
  fatal "usage: [--tag]
"
fi

if [[ "$1" == "--tag" ]]; then
  MAKE_TAG=yes

  info "Release will be tagged"
else
  MAKE_TAG=no
fi

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

CHANGELOG_VERSION_NAME_PATTERN='^([0-9]+\.[0-9]+\.[0-9]+) \((.*)\)$'
CHANGELOG_VERSION_NAME=`java -jar "${CHANGELOG_JAR_NAME}" release-current --file "${CHANGE_FILE}"` ||
  fatal "Could not determine changelog version"

if ! [[ $CHANGELOG_VERSION_NAME =~ $CHANGELOG_VERSION_NAME_PATTERN ]]; then
  fatal "Unable to parse changelog version name $CHANGELOG_VERSION_NAME"
fi

CHANGELOG_VERSION_NUM=${BASH_REMATCH[1]}
CHANGELOG_STATE=${BASH_REMATCH[2]}

if [ $VERSION_NUM = $CHANGELOG_VERSION_NUM ]; then
  info "Finishing dev cycle for release $VERSION_NUM"
else
  fatal "Project version $VERSION_NUM does not match changelog version $CHANGELOG_VERSION_NUM"
fi

if [ "$GITHUB_REF_TYPE" = "branch" ]; then
  RELEASE_BRANCH_NAME_PATTERN='^release/(.*)$'

  if [[ "$GITHUB_REF_NAME" =~ $RELEASE_BRANCH_NAME_PATTERN ]]; then
    BRANCH_VERSION_NUM=${BASH_REMATCH[1]}

    if ! [ $VERSION_NUM = "$BRANCH_VERSION_NUM" ]; then
      fatal "Project version $VERSION_NUM does not match release branch version $BRANCH_VERSION_NUM"
    fi
  fi
fi

if [ "$CHANGELOG_STATE" = "open" ]; then
  info "Closing changelog"

  java -jar "${CHANGELOG_JAR_NAME}" release-finish --file "${CHANGE_FILE}" ||
    fatal "Could not close changelog"
  git add "${CHANGE_FILE}" ||
    fatal "Could not add changelog to index"
else
  info "Changelog is already closed"
fi

if [ "$SNAPSHOT" = "-SNAPSHOT" ]; then
  info "Bumping project snapshot version to release version"

  sed -E -i 's/VERSION_NAME=([0-9]+\.[0-9]+\.[0-9]+)-SNAPSHOT/VERSION_NAME=\1/' gradle.properties ||
    fatal "Could not bump project version"
  git add gradle.properties ||
    fatal "Could not add gradle.properties to index"
else
  info "Project version is already a release version"
fi

git config --global user.email "palace.ci@thepalaceproject.org" ||
  fatal "Could not configure git"
git config --global user.name "Palace CI" ||
  fatal "Could not configure git"

if [ "$MAKE_TAG" = "yes" ]; then
  TAG_TEMPLATE=`head -n 1 ".ci-local/tag-template.conf"` ||
    fatal "Could not read .ci-local/tag-template.conf"

  TAG_NAME=`echo $TAG_TEMPLATE | sed 's/${VERSION_NUM}/'${VERSION_NUM}/`
fi

if ! git diff --staged --quiet; then
  if [[ "$MAKE_TAG" == "yes" && `git ls-remote --tags origin "$TAG_NAME"` ]]; then
    fatal "Changes are required to finish the release, but the release has already been tagged as $TAG_NAME"
  fi

  info "Committing and pushing changes"

  git commit -m "Finish $VERSION_NUM release." ||
    fatal "Could not commit changes"
  git push ||
    fatal "Could not push changes"
else
  info "No files changed"
fi

if [ "$MAKE_TAG" = "yes" ]; then
  if ! [[ `git ls-remote --tags origin "$TAG_NAME"` ]]; then
    info "Tagging release as $TAG_NAME"

    git tag -a "$TAG_NAME" -m "Release $VERSION_NUM" ||
      fatal "Could not tag release"
    git push origin "$TAG_NAME" ||
      fatal "Could not push release tag"
  else
    git fetch origin "refs/tags/$TAG_NAME"

    if ! git diff --quiet FETCH_HEAD HEAD; then
      fatal "The release has already been tagged, but the tag $TAG_NAME differs from the current HEAD"
    fi

    info "The release has already been tagged"
  fi
fi

RELEASE_NOTES_PATH="changes-${VERSION_NUM}.txt"

ci-changelog.sh "${CHANGELOG_JAR_NAME}" "${CHANGE_FILE}" > $RELEASE_NOTES_PATH ||
  fatal "Could not generate changelog"

echo "RELEASE_NOTES_PATH=$RELEASE_NOTES_PATH" >> $GITHUB_ENV
echo "VERSION_NUM=$VERSION_NUM" >> $GITHUB_ENV
echo "TAG_NAME=$TAG_NAME" >> $GITHUB_ENV
