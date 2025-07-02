#!/bin/bash
#------------------------------------------------------------------------
# Download jreleaser if necessary.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-install-jreleaser.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-install-jreleaser.sh: info: $1" 1>&2
}

#------------------------------------------------------------------------

JRELEASER_VERSION="1.19.0"
JRELEASER_URL="https://github.com/jreleaser/jreleaser/releases/download/v${JRELEASER_VERSION}/jreleaser-${JRELEASER_VERSION}.zip"
JRELEASER_SHA256_EXPECTED="5a20df93b51654f6a06984a587e4c3595f5746b95f202b571d707315a2191efe"
JRELEASER_ROOT_DIRECTORY="jreleaser-${JRELEASER_VERSION}"

wget -O "jreleaser.zip.tmp" "${JRELEASER_URL}" ||
  fatal "Could not download jreleaser"
mv "jreleaser.zip.tmp" "jreleaser.zip" ||
  fatal "Could not rename jreleaser.zip"

JRELEASER_SHA256_RECEIVED=$(openssl sha256 "jreleaser.zip" | awk '{print $NF}') ||
  fatal "Could not checksum jreleaser.zip"

if [ "${JRELEASER_SHA256_EXPECTED}" != "${JRELEASER_SHA256_RECEIVED}" ]
then
  fatal "jreleaser.zip checksum does not match.
  Expected: ${JRELEASER_SHA256_EXPECTED}
  Received: ${JRELEASER_SHA256_RECEIVED}"
fi

rm -rfv "${JRELEASER_ROOT_DIRECTORY}" ||
  fatal "Could not remove old jreleaser directory"
unzip jreleaser.zip ||
  fatal "Could not unzip jreleaser"
mv "${JRELEASER_ROOT_DIRECTORY}" jreleaser ||
  fatal "Could not move jreleaser"
./jreleaser/bin/jreleaser --version ||
  fatal "Could not run jreleaser --version"
