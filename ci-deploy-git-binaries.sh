#!/bin/bash

#------------------------------------------------------------------------
# A script to deploy APK files to the NYPL android-binaries repository.
#

#------------------------------------------------------------------------
# Utility methods

fatal()
{
  echo "ci-deploy-git-binaries.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-deploy-git-binaries.sh: info: $1" 1>&2
}

if [ ! -f ".ci-local/deploy-git-binary-source.conf" ]
then
  info ".ci-local/deploy-git-binary-source.conf does not exist, will not deploy binaries"
  exit 0
fi

WORKING_DIRECTORY=$(pwd) ||
  fatal "could not determine working directory"

GIT_BRANCH_NAME=$(head -n 1 ".ci-local/deploy-git-binary-branch.conf") ||
  fatal "could not read .ci-local/deploy-git-branch.conf"
GIT_TARGET_REPOS=$(head -n 1 ".ci-local/deploy-git-binary-target.conf") ||
  fatal "could not read .ci-local/deploy-git-target.conf"
GIT_VERSION_CODE_FILE=$(head -n 1 ".ci-local/deploy-git-binary-version-file.conf") ||
  fatal "could not read .ci-local/deploy-git-binary-version-file.conf"

GIT_TARGET_URL="https://${NYPL_GITHUB_ACCESS_TOKEN}@github.com/${GIT_TARGET_REPOS}"

info "cloning binaries"

git clone \
  --depth 1 \
  --single-branch \
  --branch "${GIT_BRANCH_NAME}" \
  "${GIT_TARGET_URL}" \
  ".binaries" ||
  fatal "could not clone binaries"

ci-deploy-git-message.sh "${GIT_VERSION_CODE_FILE}" > ".binaries-commit-message.txt" ||
  fatal "could not generate commit message"

cd ".binaries" ||
  fatal "could not move to binaries directory"
git rm -f *.apk ||
  fatal "could not remove old APKs"
git rm -f build.properties ||
fatal "could not remove old build properties"

cd "${WORKING_DIRECTORY}" ||
  fatal "could not restore working directory"

find . -wholename '*/build/outputs/apk/release/*.apk' -exec cp -v {} "${BINARIES_DIRECTORY}" \;
find . -wholename '*/build/outputs/apk/debug/*.apk' -exec cp -v {} "${BINARIES_DIRECTORY}" \;

cd ".binaries" ||
  fatal "could not switch to binaries directory"

git add *.apk ||
  fatal "could not add APKs to index"
git commit --file="${WORKING_DIRECTORY}/.binaries-commit-message.txt" ||
  fatal "could not commit"

git push --force || fatal "could not push"
