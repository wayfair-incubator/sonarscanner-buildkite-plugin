#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

# Uncomment to enable stub debugging
export CURL_STUB_DEBUG=/dev/tty

source ".env"

setup() {
    export TMPDIR_BACKUP=$TMPDIR
    export TMPDIR="/tmp"
    export SONARQUBE_LOGIN="secretkey"
    export BUILDKITE_PLUGIN_SONARSCANNER_PROJECT_KEY="my_project"
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="https://sonarqube.example.com"
    stub mktemp \
    "-d \"${PWD}/artifacts-tmp.XXXXXXXXXX\" : echo /workdir/artifacts-tmp.XXXXXXXXXX"
}

teardown() {
    unstub mktemp
    unstub docker
    TMPDIR=$TMPDIR_BACKUP
    unset SONARQUBE_LOGIN
    unset BUILDKITE_PLUGIN_SONARSCANNER_PROJECT_KEY
}

@test "Logs start of run" {

    stub docker \
    "create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.projectKey=my_project -Dsonar.sources=. -Dsonar.login=secretkey : echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success
    assert_output --partial "+++ :docker: :sonarqube: Starting sonar-scanner"
}

@test "Run in custom workdir" {
    export BUILDKITE_PLUGIN_SONARSCANNER_WORKDIR="/foo"
    stub docker \
    "create --workdir /foo sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.projectKey=my_project -Dsonar.sources=. -Dsonar.login=secretkey : echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success

    unset BUILDKITE_PLUGIN_SONARSCANNER_WORKDIR
}

@test "Securely logs docker create" {
    stub docker \
    "create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.projectKey=my_project -Dsonar.sources=. -Dsonar.login=secretkey : echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Running docker create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.sources=. -Dsonar.projectKey=my_project -Dsonar.login=**********"
}

@test "Docker copies local files into container" {
    stub docker \
    "create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.sources=. -Dsonar.projectKey=my_project -Dsonar.login=secretkey : echo 1234"  \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Running docker cp /plugin/. 1234:/workdir"
    assert_output --partial "ran docker copy"
}

@test "Docker starts" {
    stub docker \
    "create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.sources=. -Dsonar.projectKey=my_project -Dsonar.login=secretkey : echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Running docker start -a 1234"
    assert_output --partial "ran docker start"
}

@test "Accepts custom sources" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SOURCES="/source1,source2"

    stub docker \
    "create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.projectKey=my_project -Dsonar.sources=/source1,source2 -Dsonar.login=secretkey : echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Running docker create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.sources=/source1,source2 -Dsonar.projectKey=my_project -Dsonar.login=**********"

    unset BUILDKITE_PLUGIN_SONARSCANNER_SOURCES
}

@test "Accepts additional flag from string" {
    export BUILDKITE_PLUGIN_SONARSCANNER_ADDITIONAL_FLAGS="-X"

    stub docker \
    "create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.projectKey=my_project -Dsonar.sources=. -X -Dsonar.login=********** :  echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Running docker create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.sources=. -Dsonar.projectKey=my_project -Dsonar.login=********** -Dsonar.host.url=https://sonarqube.example.com -X"

    unset BUILDKITE_PLUGIN_SONARSCANNER_ADDITIONAL_FLAGS
}

@test "Accepts additional flags from array" {
    export BUILDKITE_PLUGIN_SONARSCANNER_ADDITIONAL_FLAGS_0="-X"
    export BUILDKITE_PLUGIN_SONARSCANNER_ADDITIONAL_FLAGS_1="-Dsonar.test=foo"
    stub docker \
    "docker create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.sources=. -Dsonar.projectKey=my_project -Dsonar.login=secretkey -X -Dsonar.test=foo : echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Running docker create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.sources=. -Dsonar.projectKey=my_project -Dsonar.login=********** -Dsonar.host.url=https://sonarqube.example.com -X -Dsonar.test=foo"

    unset BUILDKITE_PLUGIN_SONARSCANNER_ADDITIONAL_FLAGS_0
    unset BUILDKITE_PLUGIN_SONARSCANNER_ADDITIONAL_FLAGS_1
}

@test "Upload single artifacts from string" {
    export BUILDKITE_PLUGIN_SONARSCANNER_ADDITIONAL_FLAGS="-Dsonar.python.coverage.reportPaths=tmp/*coverage-*.xml"
    export BUILDKITE_PLUGIN_SONARSCANNER_ARTIFACTS="tmp/*coverage-*.xml"

    stub docker \
    "create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.sources=. -Dsonar.projectKey=my_project -Dsonar.login=secretkey -Dsonar.host.url=https://sonarqube.example.com -Dsonar.python.coverage.reportPaths=tmp/*coverage-*.xml : echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "cp /workdir/artifacts-tmp.XXXXXXXXXX/. 1234:/workdir : echo ran docker artifact copy" \
    "start -a 1234 : echo ran docker start"

    stub buildkite-agent \
    "artifact download tmp/*coverage-*.xml /workdir/artifacts-tmp.XXXXXXXXXX : echo downloaded artifacts"

    run $PWD/hooks/command
    assert_success
    assert_output --partial "ran docker artifact copy"
    assert_output --partial "Running buildkite-agent artifact download tmp/*coverage-*.xml /workdir/artifacts-tmp.XXXXXXXXXX"
    assert_output --partial "downloaded artifacts"
    assert_output --partial "Running docker cp /workdir/artifacts-tmp.XXXXXXXXXX/. 1234:/workdir"

    unstub buildkite-agent

    unset BUILDKITE_PLUGIN_SONARSCANNER_ARTIFACTS
    unset BUILDKITE_PLUGIN_SONARSCANNER_ADDITIONAL_FLAGS
}

@test "Upload multiple artifacts from array" {
    export BUILDKITE_PLUGIN_SONARSCANNER_ADDITIONAL_FLAGS="-Dsonar.python.coverage.reportPaths=tmp/*coverage-*.xml"
    export BUILDKITE_PLUGIN_SONARSCANNER_ARTIFACTS_0="tmp/*coverage-*.xml"
    export BUILDKITE_PLUGIN_SONARSCANNER_ARTIFACTS_1="tmp/*coverage-*.html"

    stub docker \
    "create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.sources=. -Dsonar.projectKey=my_project -Dsonar.login=secretkey -Dsonar.host.url=https://sonarqube.example.com -Dsonar.python.coverage.reportPaths=tmp/*coverage-*.xml : echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "cp /workdir/artifacts-tmp.XXXXXXXXXX/. 1234:/workdir : echo ran docker artifact copy" \
    "start -a 1234 : echo ran docker start"

    stub buildkite-agent \
    "artifact download tmp/*coverage-*.xml /workdir/artifacts-tmp.XXXXXXXXXX : echo downloaded artifact 0 -" \
    "artifact download tmp/*coverage-*.html /workdir/artifacts-tmp.XXXXXXXXXX : echo downloaded artifact 1 -" \

    run $PWD/hooks/command
    assert_success
    assert_output --partial "ran docker artifact copy"
    assert_output --partial "Running buildkite-agent artifact download tmp/*coverage-*.xml /workdir/artifacts-tmp.XXXXXXXXXX"
    assert_output --partial "Running buildkite-agent artifact download tmp/*coverage-*.html /workdir/artifacts-tmp.XXXXXXXXXX"
    assert_output --partial "downloaded artifact 0"
    assert_output --partial "downloaded artifact 1"
    assert_output --partial "Running docker cp /workdir/artifacts-tmp.XXXXXXXXXX/. 1234:/workdir"

    unstub buildkite-agent

    unset BUILDKITE_PLUGIN_SONARSCANNER_ARTIFACTS_0
    unset BUILDKITE_PLUGIN_SONARSCANNER_ARTIFACTS_1
    unset BUILDKITE_PLUGIN_SONARSCANNER_ADDITIONAL_FLAGS
}

@test "Fails when project key not set" {
    unset BUILDKITE_PLUGIN_SONARSCANNER_PROJECT_KEY

    run $PWD/hooks/command
    assert_failure
    assert_output --partial "ERROR: sonarqube project key not set"
}

@test "Fails when login token not set" {
    unset SONARQUBE_LOGIN

    run $PWD/hooks/command
    assert_failure
    assert_output --partial "ERROR: sonarqube login not set"
}

@test "Fails when sonarqube_host not set" {
    unset BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST
    run $PWD/hooks/command
    assert_failure
    assert_output --partial "ERROR: sonarqube host URL not set"
}

@test "Cleans up after error" {
    unset SONARQUBE_LOGIN

    run $PWD/hooks/command
    assert_failure
    assert_output --partial "Running rm -rf /workdir/artifacts-tmp.XXXXXXXXXX"
}

@test "Run in Dotnet" {
    export BUILDKITE_PLUGIN_SONARSCANNER_IS_DOTNET="true"
    export BUILDKITE_PLUGIN_SONARSCANNER_DOTNET_BUILD_PROJECT="My.App.sln"

    stub docker \
    "create --workdir /workdir --env SONARQUBE_LOGIN=secretkey --env DOTNET_BUILD_PROJECT=My.App.sln sonarscannerbuildkite/sonarscanner-dotnet:${PLUGIN_VERSION} /k:my_project /d:secretkey : echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Running docker create --workdir /workdir --env SONARQUBE_LOGIN=********** --env DOTNET_BUILD_PROJECT=My.App.sln sonarscannerbuildkite/sonarscanner-dotnet:${PLUGIN_VERSION} /k:my_project /d:sonar.login=**********"

    unset BUILDKITE_PLUGIN_SONARSCANNER_IS_DOTNET
    unset BUILDKITE_PLUGIN_SONARSCANNER_DOTNET_BUILD_PROJECT
}

@test "Using custom sonarqube_host" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="http://some_sonarqube_host"
    stub docker \
    "create --workdir /workdir sonarscannerbuildkite/sonarscanner:${PLUGIN_VERSION} -Dsonar.projectKey=my_project -Dsonar.sources=. -Dsonar.login=secretkey -Dsonar.host.url=http://some_sonarqube_host: echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success

    unset BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST
}

@test "Using custom sonarqube_host dotnet" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="http://some_sonarqube_host"
    export BUILDKITE_PLUGIN_SONARSCANNER_IS_DOTNET="true"
    export BUILDKITE_PLUGIN_SONARSCANNER_DOTNET_BUILD_PROJECT="My.App.sln"

    stub docker \
    "create --workdir /workdir --env SONARQUBE_LOGIN=secretkey --env DOTNET_BUILD_PROJECT=My.App.sln sonarscannerbuildkite/sonarscanner-dotnet:${PLUGIN_VERSION} /k:my_project /d:secretkey /d:sonar.host.url=http://some_sonarqube_host: echo 1234" \
    "cp /plugin/. 1234:/workdir : echo ran docker copy" \
    "start -a 1234 : echo ran docker start"

    run $PWD/hooks/command
    assert_success
    assert_output --partial "docker create --workdir /workdir --env SONARQUBE_LOGIN=********** --env DOTNET_BUILD_PROJECT=My.App.sln sonarscannerbuildkite/sonarscanner-dotnet:${PLUGIN_VERSION} /k:my_project /d:sonar.login=********** /d:sonar.host.url=http://some_sonarqube_host"

    unset BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST
    unset BUILDKITE_PLUGIN_SONARSCANNER_IS_DOTNET
    unset BUILDKITE_PLUGIN_SONARSCANNER_DOTNET_BUILD_PROJECT
}

@test "Enabled branch scan and no pull request scan with master" {
    export BUILDKITE_PLUGIN_SONARSCANNER_USES_COMMUNITY_EDITION="false"
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="http://some.enterprise.server"
    export BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_BRANCH_SCAN="true"
    export BUILDKITE_BRANCH="master"
    unset BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_PULL_REQUEST_SCAN

    stub docker

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Current build is for master, which is the defined 'default' branch, doing 'default' branch scan."
}

@test "Enabled branch scan and no pull request scan with feature branch" {
    export BUILDKITE_PLUGIN_SONARSCANNER_USES_COMMUNITY_EDITION="false"
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="http://some.enterprise.server"
    export BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_BRANCH_SCAN="true"
    export BUILDKITE_BRANCH="feature_branch"
    unset BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_PULL_REQUEST_SCAN

    stub docker

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Current build is feature branch build, doing branch scan"
    assert_output --partial "-Dsonar.branch.name=feature_branch -Dsonar.branch.target=master"
}

@test "Enabled PR scan and not enable branch scan" {
    export BUILDKITE_PLUGIN_SONARSCANNER_USES_COMMUNITY_EDITION="false"
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="http://some.enterprise.server"
    unset BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_BRANCH_SCAN
    export BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_PULL_REQUEST_SCAN="true"
    export BUILDKITE_BRANCH="feature_branch"
    export BUILDKITE_PULL_REQUEST_BASE_BRANCH="master"
    export BUILDKITE_PULL_REQUEST="1"

    stub docker

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Current build triggered by PR, doing PR scan"
    assert_output --partial "-Dsonar.pullrequest.branch=feature_branch -Dsonar.pullrequest.base=master"
}

@test "Enabled PR scan and not enable branch scan, and not a PR" {
    export BUILDKITE_PLUGIN_SONARSCANNER_USES_COMMUNITY_EDITION="false"
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="http://some.enterprise.server"
    unset BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_BRANCH_SCAN
    export BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_PULL_REQUEST_SCAN="true"
    export BUILDKITE_BRANCH="feature_branch"
    export BUILDKITE_PULL_REQUEST_BASE_BRANCH=""
    export BUILDKITE_PULL_REQUEST="false"

    stub docker

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Pull request scan enabled, checking PR info"
    assert_output --partial "Current build is not triggered by PR, checking if branch scan enabled"
    assert_output --partial "Branch scan not enabled"
    assert_output --partial "+++ :docker: :sonarqube: Starting sonar-scanner"
}

@test "Enabled PR scan and branch scan, and not triggered by PR" {
    export BUILDKITE_PLUGIN_SONARSCANNER_USES_COMMUNITY_EDITION="false"
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="http://some.enterprise.server"
    export BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_BRANCH_SCAN="true"
    export BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_PULL_REQUEST_SCAN="true"
    export BUILDKITE_BRANCH="feature_branch"
    export BUILDKITE_PULL_REQUEST_BASE_BRANCH=""
    export BUILDKITE_PULL_REQUEST="false"

    stub docker

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Current build is feature branch build, doing branch scan"
    assert_output --partial "-Dsonar.branch.name=feature_branch -Dsonar.branch.target=master"
}

@test "Enabled PR scan and branch scan, and triggered by PR" {
    export BUILDKITE_PLUGIN_SONARSCANNER_USES_COMMUNITY_EDITION="false"
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="http://some.enterprise.server"
    export BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_BRANCH_SCAN="true"
    export BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_PULL_REQUEST_SCAN="true"
    export BUILDKITE_BRANCH="feature_branch"
    export BUILDKITE_PULL_REQUEST_BASE_BRANCH="master"
    export BUILDKITE_PULL_REQUEST="1"

    stub docker

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Current build triggered by PR, doing PR scan"
    assert_output --partial "-Dsonar.pullrequest.key=1 -Dsonar.pullrequest.branch=feature_branch -Dsonar.pullrequest.base=master"
}

@test "Not enable PR and branch scan, and a branch build (enterprise edition)" {
    export BUILDKITE_PLUGIN_SONARSCANNER_USES_COMMUNITY_EDITION="false"
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="http://some.enterprise.server"
    unset BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_BRANCH_SCAN
    unset BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_PULL_REQUEST_SCAN
    export BUILDKITE_BRANCH="feature_branch"

    stub docker

    run $PWD/hooks/command
    assert_success
    assert_output --partial "Both branch scan and pull request scan not enabled, and this is branch build, scan skipped"
}

@test "Not enable PR and branch scan, and a branch build (community edition)" {
    unset BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_BRANCH_SCAN
    unset BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_PULL_REQUEST_SCAN
    export BUILDKITE_BRANCH="feature_branch"

    stub docker

    run $PWD/hooks/command
    assert_success
    assert_output --partial "+++ :docker: :sonarqube: Starting sonar-scanner"
}

@test "Enabled PR scan, but target community server" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="https://sonarqube.example.com"
    export BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_PULL_REQUEST_SCAN="true"

    run $PWD/hooks/command
    assert_failure
    assert_output --partial "+++ :warning: Enabled PR or Branch Scan but targeting Sonarqube Community"
}

@test "Enabled branch scan, but target community server" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SONARQUBE_HOST="https://sonarqube.example.com"
    export BUILDKITE_PLUGIN_SONARSCANNER_ENABLE_BRANCH_SCAN="true"

    run $PWD/hooks/command
    assert_failure
    assert_output --partial "+++ :warning: Enabled PR or Branch Scan but targeting Sonarqube Community"
}

@test "Enabled scan only if sources changed, no sources" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SCAN_ONLY_IF_SOURCES_CHANGED="true"

    stub docker
    stub git "diff --name-only --exit-code master -- . : exit 0"

    run $PWD/hooks/command

    assert_success
    assert_output --partial "Scan only if sources changed set to true, checking changed files against sources"
    assert_output --partial "Source directories to scan for: ."
    assert_output --partial "Changed files: None"
    assert_output --partial "Target sources not changed, aborting scan."

    unstub git
}

@test "Enabled scan only if sources changed, no matching sources" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SCAN_ONLY_IF_SOURCES_CHANGED="true"
    export BUILDKITE_PLUGIN_SONARSCANNER_SOURCES="sample/directory"

    stub git "diff --name-only --exit-code master -- sample/directory : exit 0"

    run $PWD/hooks/command

    assert_success
    assert_output --partial "Scan only if sources changed set to true, checking changed files against sources"
    assert_output --partial "Source directories to scan for: sample/directory"
    assert_output --partial "Changed files: None"
    assert_output --partial "Target sources not changed, aborting scan."

    unstub git
}

@test "Enabled scan only if sources changed, found match and ran scan" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SCAN_ONLY_IF_SOURCES_CHANGED="true"
    export BUILDKITE_PLUGIN_SONARSCANNER_SOURCES="sample/directory"

    stub docker
    stub git "diff --name-only --exit-code master -- sample/directory : echo "sample/directory/file.file" && exit 1"

    run $PWD/hooks/command

    assert_success
    assert_output --partial "Scan only if sources changed set to true, checking changed files against sources"
    assert_output --partial "Source directories to scan for: sample/directory"
    assert_output --partial "Changed files: sample/directory/file.file"
    assert_output --partial "Targeted sources changed, proceeding with scan"

    unstub git
}

@test "Enabled scan only if sources changed, found match and ran scan using default sources" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SCAN_ONLY_IF_SOURCES_CHANGED="true"

    stub docker
    stub git "diff --name-only --exit-code master -- . : echo "sample/directory/file.file" && exit 1"

    run $PWD/hooks/command

    assert_success
    assert_output --partial "Scan only if sources changed set to true, checking changed"
    assert_output --partial "Source directories to scan for: ."
    assert_output --partial "Changed files: sample/directory/file.file"
    assert_output --partial "Targeted sources changed, proceeding with scan"

    unstub git
}

@test "Enabled scan only if sources changed, found match and ran scan using multiple sources" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SCAN_ONLY_IF_SOURCES_CHANGED="true"
    export BUILDKITE_PLUGIN_SONARSCANNER_SOURCES="sample/directory,another/directory"
    stub docker
    stub git "diff --name-only --exit-code master -- sample/directory another/directory : echo "sample/directory/file.file" && exit 1"

    run $PWD/hooks/command

    assert_success
    assert_output --partial "Scan only if sources changed set to true, checking changed files against sources"
    assert_output --partial "Source directories to scan for: sample/directory another/directory"
    assert_output --partial "Changed files: sample/directory/file.file"
    assert_output --partial "Targeted sources changed, proceeding with scan"

    unstub git
}

@test "Enabled scan only if sources changed, nonstandard default branch" {
    export BUILDKITE_PLUGIN_SONARSCANNER_SCAN_ONLY_IF_SOURCES_CHANGED="true"
    export BUILDKITE_PLUGIN_SONARSCANNER_BRANCH_SCAN_TARGET="staging"

    stub docker
    stub git "diff --name-only --exit-code staging -- . : exit 0"

    run $PWD/hooks/command

    assert_success
    assert_output --partial "Scan only if sources changed set to true, checking changed files against sources"
    assert_output --partial "Source directories to scan for: ."
    assert_output --partial "Changed files: None"
    assert_output --partial "Target sources not changed, aborting scan."

    unstub git
}
