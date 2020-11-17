#!/bin/sh

PROJECTS="
Simplified-Android-SimplyE
Simplified-Android-Core
Simplified-Android-HTTP
audiobook-android
audiobook-android-overdrive
audiobook-audioengine-android
"

cat <<EOF
|Project|Status|
|-------|------|
EOF

for PROJECT in ${PROJECTS}
do
  cat <<EOF
|[${PROJECT}](https://www.github.com/NYPL-Simplified/${PROJECT})|[![Build Status](https://img.shields.io/github/workflow/status/NYPL-Simplified/${PROJECT}/Android%20CI%20(Authenticated)?style=flat-square)](https://github.com/NYPL-Simplified/${PROJECT}/actions?query=workflow%3A%22Android+CI+%28Authenticated%29%22)|
EOF
done
