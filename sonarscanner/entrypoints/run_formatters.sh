#!/usr/bin/env bash
set -euo pipefail

# shfmt default: simplify, 2-space indent, indent switch case, space after
# redirect operators, pad columns for alignment, list-only
SHFMT_DEFAULT_ARGS=("-s" "-i=2" "-ci" "-sr" "-kp" "-l")

# by default, fail if formatting changes are suggested
SHFMT_ACTIONS=("-d")
MARKDOWNFMT_ACTIONS="-l"

function usage() {
  cat << EOF
  usage: run_formatters [--check][--format][--help]

  If no arguments are given, will check formatting and syntax of bash and
  markdown files. Will fail if formatting changes are suggested.

  Options:
  -c, --check    Fail script if formatting changes are suggested [Default]
  -f, --format   Update files in place with recommended formatting changes
  -h, --help     Print this message and exit

EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  arg="$1"
  case $arg in
    -f | --format)
      SHFMT_ACTIONS=("-w")
      MARKDOWNFMT_ACTIONS="-w"
      ;;
    -h | --help)
      usage
      ;;
    -c | --check | "")
      # ignore
      ;;
    *)
      echo "Unexpected argument: ${arg}"
      usage
      ;;
  esac
  shift
done

echo "Running Shell Format..."
SHFMT_ACTIONS+=("${SHFMT_DEFAULT_ARGS[@]}")
shfmt "${SHFMT_ACTIONS[@]}" .

echo "Running Shellcheck..."
shellcheck -x {hooks/**,**/*.sh}

echo "Running Markdown format..."
if [[ $MARKDOWNFMT_ACTIONS == "-l" ]]; then
  if [[ $(markdownfmt $MARKDOWNFMT_ACTIONS -- *.md) ]]; then
    exit 1
  fi
else
  markdownfmt $MARKDOWNFMT_ACTIONS -- *.md
fi
