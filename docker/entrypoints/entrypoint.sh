#!/usr/bin/env bash
set -euo pipefail

exec sonar-scanner "$@"
