#!/usr/bin/env bash

function plugin_read_config() {
  local var="BUILDKITE_PLUGIN_SONARSCANNER_${1}"
  local default="${2:-}"
  echo "${!var:-$default}"
}

function plugin_read_list_into_result() {
  result=()

  for prefix in "$@"; do
    local i=0
    local parameter="${prefix}_${i}"

    if [[ -n ${!prefix:-} ]]; then
      echo >&2 "🚨 Plugin received a string for $prefix, expected an array"
      exit 1
    fi

    while [[ -n ${!parameter:-} ]]; do
      result+=("${!parameter}")
      i=$((i + 1))
      parameter="${prefix}_${i}"
    done
  done

  [[ ${#result[@]} -gt 0 ]] || return 1
}

function cleanup() {
  echo "Running rm -rf ${LOCAL_ARTIFACTS_DIR}"
  rm -rf "${LOCAL_ARTIFACTS_DIR}"
}
