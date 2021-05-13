#!/bin/bash

#------------------------------------------------------------------------
# A script to set up project-specific fake credentials for users that
# are not authenticated.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-credentials-fake.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-credentials-fake.sh: info: $1" 1>&2
}

#------------------------------------------------------------------------
# Run local credentials hooks if present.
#

if [ -f .ci-local/credentials-fake.sh ]
then
  .ci-local/credentials-fake.sh || fatal "local credentials hook failed"
fi
