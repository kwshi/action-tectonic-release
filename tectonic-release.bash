#!/bin/bash
set -euo pipefail

shopt -s nullglob dotglob extglob globstar

readarray -t patterns <<< "$1"

for pattern in "${patterns[@]}"; do
  # shellcheck disable=SC2206
  IFS= paths=($pattern)

  for path in "${paths[@]}"; do
    tectonic -X compile "$path"
  done
done

curl "https://api.github.com/repos/$GITHUB_REPOSITORY/releases"
