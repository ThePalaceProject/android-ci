Simplified-Android-CI
=======================

The NYPL's [Library Simplified](http://www.librarysimplified.org/) CI scripts.

![ci](./readme.jpg?raw=true)

_Image by [Nowaja](https://pixabay.com/users/nowaja-9363663/) from [Pixabay](https://pixabay.com/photos/handicraft-weaving-loom-wool-work-4388501/)_

### What Is This?

The contents of this repository define the CI scripts used to continuously
build the various [Library Simplified](http://www.librarysimplified.org/)
Android modules.

### Features

* Automatic deployment of application binaries to a git repository.
* Automatic deployment of snapshots and releases to [Maven Central](https://search.maven.org/).
* Build pull requests safely without access to secrets.
* Zero-configuration in the common case; add a git submodule and go!

### Usage

First, add the CI scripts to your project as a Git submodule in a `.ci` directory:

```
$ git submodule add https://www.github.com/NYPL-Simplified/Simplified-Android-CI .ci
```

Per-project configuration data is expected to be placed into a `.ci-local` directory
at the root of the project. Most projects will not need to define any configuration
information. The scripts in `.ci` contain _no user-serviceable parts_.

The CI scripts only know how to build [Gradle](https://www.gradle.org) projects as,
unfortunately, this is the only supported build system for use in Android project.
The CI scripts expect your Gradle project to define the following tasks:

|Task                      |Description|
|--------------------------|-----------|
|`clean`                   |Deletes all build artifacts to guarantee a clean build|
|`assembleDebug`           |Builds all artifacts in `debug` mode|
|`assembleRelease`         |Builds all artifacts in `release` mode|
|`test`                    |Runs all tests|
|`ktlint`                  |Executes [ktlint](https://ktlint.github.io/) to check code style|
|`verifySemanticVersioning`|Runs semantic versioning checks|

The scripts expect all of these tasks to be defined, but it is possible to
simply define empty tasks for `ktlint` and `verifySemanticVersioning` if
the project in question does not use them.

The scripts expect your Gradle project to accept the following project properties:

|Property                                 |Value         |Description|
|-----------------------------------------|--------------|-----------|
|`org.librarysimplified.no_signing`       |`true`/`false`|If `true`, no PGP signing of artifacts will occur|
|`org.librarysimplified.directory.publish`|Any path      |If set, artifacts will be published to the named directory in Maven repository format|
|`mavenCentralUsername`                   |Any string    |The username used to publish to Maven Central|
|`mavenCentralPassword`                   |Any string    |The password used to publish to Maven Central|

The entry point to the CI scripts is the [ci-main.sh](ci-main.sh) script. This
script takes a single parameter specifying the type of build that will be
performed. The CI scripts distinguish between different types of builds for
reasons of security: Commits that are coming from a potentially untrustworthy
third party might try to modify the CI scripts themselves in order to steal
credentials and other build secrets when the build executes. Additionally,
the build artifacts that are produced by commits coming from a potentially
untrustworthy third party should not be automatically published to, for example,
[Maven Central](https://search.maven.org/).

The `ci-main.sh` script therefore defines the following build types:

|Value   |Description|
|--------|-----------|
|`normal`|This is a normal build of code that has been reviewed. The build will be granted full access to secrets. The artifacts produced will be published to various locations.|
|`pull-request`|This is a build of a pull request. The build will proceed without access to secrets, and any build artifacts produced will _not_ be published.|

Using [GitHub Actions](https://github.com/features/actions) as an example,
the intention is that projects will define a pair of _workflows_ `A` and `B`.
Workflow `A` is triggered when any commit is made to the `develop` or `main` branch
of the repos, and calls `$ ci-main.sh normal` to perform a full build
with secrets and publishing. Workflow `B` is triggered when a pull request
is opened, and calls `$ ci-main.sh pull-request` to do a limited build
without secrets or publishing. There is a facility to do [extra handling](#credentials-hook)
of credentials and secrets if required.

Here are two example Workflow definitions that implement the above:

```
name: Android CI (Authenticated)

on:
  push:
    branches: [ develop, master ]
    tags: v[0-9]+.[0-9]+.[0-9]+

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout reposistory
        uses: actions/checkout@v2
      - name: Checkout submodules
        run: git submodule update --init --recursive
      - name: set up JDK 1.8
        uses: actions/setup-java@v1
        with:
          java-version: 1.8
      - name: Build
        env:
          MAVEN_CENTRAL_USERNAME:           ${{ secrets.MAVEN_CENTRAL_USERNAME }}
          MAVEN_CENTRAL_PASSWORD:           ${{ secrets.MAVEN_CENTRAL_PASSWORD }}
          MAVEN_CENTRAL_STAGING_PROFILE_ID: '3dbb9c4528708261'
          MAVEN_CENTRAL_SIGNING_KEY_ID:     'c8d9e0c27090998d'
          NYPL_GITHUB_ACCESS_TOKEN:         ${{ secrets.NYPL_GITHUB_ACCESS_TOKEN }}
        run: .ci/ci-main.sh normal
```

```
name: Android CI (Pull Requests)

on:
  pull_request:
    branches: [ develop ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout reposistory
        uses: actions/checkout@v2
      - name: Checkout submodules
        run: git submodule update --init --recursive
      - name: set up JDK 1.8
        uses: actions/setup-java@v1
        with:
          java-version: 1.8
      - name: Build PR
        run: .ci/ci-main.sh pull-request
```

### Environment Variables

The build scripts require the following environment variables to be defined when executing
a `normal` build. Executing a `pull-request` build does not require any particular environment.

|Name                              |Description|
|----------------------------------|-----------|
|`MAVEN_CENTRAL_USERNAME`          |The username used to publish binaries to Maven Central|
|`MAVEN_CENTRAL_PASSWORD`          |The password used to publish binaries to Maven Central|
|`MAVEN_CENTRAL_STAGING_PROFILE_ID`|The staging profile used to publish binaries to Maven Central|
|`MAVEN_CENTRAL_SIGNING_KEY_ID`    |The ID of the PGP key used to sign binaries for Maven Central|
|`NYPL_GITHUB_ACCESS_TOKEN`        |A GitHub access token used to access private NYPL repositories|

These values should be stored in GitHub Actions _secrets_ and passed in as shown in the
example workflows above.

### APK Git Publishing

The CI scripts can be optionally configured to publish APK files to a Git repository. If
the file `.ci-local/deploy-git-binary-source.conf` exists, the CI scripts will attempt to
publish all produced APK files to a named branch in a remote Git repository. The configuration
files in `.ci-local` follow the convention that only the first line of each file is significant,
and the rest of the file is ignored. For example, to set up publishing to a remote Git repository,
do the following:

```
$ echo 'https://github.com/NYPL-Simplified/Simplified-Android-SimplyE' > .ci-local/deploy-git-binary-source.conf
$ echo 'NYPL-Simplified/android-binaries' > .ci-local/deploy-git-binary-target.conf
$ echo 'app/version.properties' > .ci-local/deploy-git-binary-version-file.conf
$ echo 'SimplyE' > .ci-local/deploy-git-binary-branch.conf
$ git add .ci-local
$ git commit -m 'Configured CI'
```

The above set of configuration files will cause binaries to be published to the `NYPL-Simplified/android-binaries`
repository on GitHub, on branch `SimplyE`. The file `app/version.properties` will be examined and
is expected to be a [Java properties](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/Properties.html)
file containing a `versionCode` key indicating the version code of the APK files being published.
The commit made in the remote repository will contain a link back to the repository
`https://github.com/NYPL-Simplified/Simplified-Android-SimplyE`, showing the exact commit that
produced the binaries.

The possible configuration files are as follows:

|File                              |Description|
|----------------------------------|-----------|
|`.ci-local/deploy-git-binary-source.conf` |The first line of this file gives the URL of the source repository, used in commit messages|
|`.ci-local/deploy-git-binary-target.conf` |The first line of this file gives the GitHub-relative name of the target repository|
|`.ci-local/deploy-git-binary-version-file.conf` |The first line of this file gives the name of the file containing a `versionCode` property indicating the version of the build APK files|
|`.ci-local/deploy-git-binary-branch.conf`|The first line of this file gives the name of the branch to which binaries will be committed|

### Credentials Hook

If the file `.ci-local/credentials.sh` exists, it will be executed after the build
credentials have been configured in `normal` builds. This script allows for copying
any extra required credentials into their expected places during the build. As an
example:

```
$ cat .ci-local/credentials.sh
#!/bin/sh

fatal()
{
  echo "credentials.sh: fatal: $1" 1>&2
  exit 1
}

if [ -z "${SECRET_SITE_PASSWORD}" ]
then
  fatal "SECRET_SITE_PASSWORD is undefined"
fi

wget "https://user:${SECRET_SITE_PASSWORD}@example.com/secret.txt" ||
  fatal "could not fetch secret"
cp secret.txt app/src/main/assets/secret.txt ||
  fatal "could not copy secret"
```
