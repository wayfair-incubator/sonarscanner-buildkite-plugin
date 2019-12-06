#!/usr/bin/env bash
set -euo pipefail

source bin/build_images.sh lint plugin-test plugin-lint

printf "\nRunning bash & markdown linters..."
docker-compose run --rm lint
printf "\nRunning plugin unit tests..."
docker-compose run --rm plugin-test
printf "\nRunning plugin linter..."
docker-compose run --rm plugin-lint
