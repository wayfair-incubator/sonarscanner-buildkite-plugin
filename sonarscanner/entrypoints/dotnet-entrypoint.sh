#!/usr/bin/env bash
set -euo pipefail

dotnet sonarscanner begin "$@"

dotnet build "${DOTNET_BUILD_PROJECT}" \
  /p:DebugType=Full

dotnet sonarscanner end \
  /d:sonar.login="${SONARQUBE_LOGIN}"
