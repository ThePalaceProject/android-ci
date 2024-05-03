#!/bin/bash
#------------------------------------------------------------------------
# Download changelog if necessary.
#

#------------------------------------------------------------------------
# Utility methods
#

fatal()
{
  echo "ci-install-changelog.sh: fatal: $1" 1>&2
  exit 1
}

info()
{
  echo "ci-install-changelog.sh: info: $1" 1>&2
}

#------------------------------------------------------------------------

INSTALL_NAME=changelog.jar
TEMP_NAME="$INSTALL_NAME.tmp"

if [ -f "$INSTALL_NAME" ]; then
  info "changelog is already installed"
  exit 0
fi

CHANGELOG_URL="https://repo1.maven.org/maven2/com/io7m/changelog/com.io7m.changelog.cmdline/5.0.0-beta0002/com.io7m.changelog.cmdline-5.0.0-beta0002-main.jar"
CHANGELOG_SHA256_EXPECTED="2e2ba9dad51132339f1b416c437ab7690800ee7990908e0b0004612b38e65e06"

wget -O "${TEMP_NAME}" "${CHANGELOG_URL}" || fatal "Could not download changelog to ${TEMP_NAME}"
mv "${TEMP_NAME}" "${INSTALL_NAME}" || fatal "Could not rename changelog from ${TEMP_NAME} to ${INSTALL_NAME}"

CHANGELOG_SHA256_RECEIVED=$(openssl sha256 "${INSTALL_NAME}" | awk '{print $NF}') || fatal "Could not checksum ${INSTALL_NAME}"

if [ "${CHANGELOG_SHA256_EXPECTED}" != "${CHANGELOG_SHA256_RECEIVED}" ]
then
  fatal "$INSTALL_NAME checksum does not match.
  Expected: ${CHANGELOG_SHA256_EXPECTED}
  Received: ${CHANGELOG_SHA256_RECEIVED}"
fi
