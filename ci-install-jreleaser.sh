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
JRELEASER_URL="https://github.com/jreleaser/jreleaser/releases/download/v${JRELEASER_VERSION}/jreleaser-native-${JRELEASER_VERSION}-linux-x86_64.zip"
JRELEASER_SHA256_EXPECTED="2f30c3141cf5a0a9c018ca96f904ff8cfb278092a275054365ec84d6144baddf"
JRELEASER_ROOT_DIRECTORY="jreleaser-native-${JRELEASER_VERSION}-linux-x86_64"

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
mv "${JRELEASER_ROOT_DIRECTORY}/bin/jreleaser" . ||
  fatal "Could not move jreleaser"
chmod 0755 jreleaser ||
  fatal "Could not ensure jreleaser is executable"
