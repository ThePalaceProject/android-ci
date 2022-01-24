#!/bin/bash
#------------------------------------------------------------------------
# A script to verify that a workflow is being executed on a release
# branch.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-verify-release-branch.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-verify-release-branch.sh: info: $1" 1>&2
}

#------------------------------------------------------------------------

info "Workflow triggered on ${GITHUB_REF_TYPE}: $GITHUB_REF_NAME"

RELEASE_BRANCH_NAME_PATTERN='^release/[0-9]+\.[0-9]+\.[0-9]+$'

if ! [[ "$GITHUB_REF_TYPE" == "branch" && "$GITHUB_REF_NAME" =~ $RELEASE_BRANCH_NAME_PATTERN ]]; then
  fatal "Workflow must be triggered on a release branch (release/x.y.z)"
fi
