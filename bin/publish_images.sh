#!/usr/bin/env bash
set -euo pipefail

source ".env"

source bin/build_images.sh sonarscanner sonarscanner-dotnet

echo "Logging into Docker Hub..."
echo "${DOCKER_PASSWORD}" | docker login --username "${DOCKER_USER}" --password-stdin

echo "Pushing images to Docker Hub..."
echo sonarscannerbuildkite/{sonarscanner,sonarscanner-dotnet}:"${PLUGIN_VERSION}" | xargs -n 1 docker push

echo "Logging out of Docker Hub..."
docker logout
