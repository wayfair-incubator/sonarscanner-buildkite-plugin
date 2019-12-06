#!/usr/bin/env bash
set -euo pipefail

source ".env"

ARGS=("$@")

build_images()  {
  docker-compose build \
    --parallel \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    "${ARGS[@]}"
}

BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

echo "Building Docker images (lastest tag)..."
build_images

echo "Building Docker images (version tag)..."
export IMAGE_VERSION="${PLUGIN_VERSION}"
build_images
