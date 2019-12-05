#!/usr/bin/env bash
set -euo pipefail

BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
echo "Building Docker images..."
docker-compose build --build-arg BUILD_DATE="${BUILD_DATE}"
echo "Running bash & markdown linters..."
docker-compose run --rm lint
echo "Running plugin unit tests..."
docker-compose run --rm plugin-test
echo "Running plugin linter..."
docker-compose run --rm plugin-lint
