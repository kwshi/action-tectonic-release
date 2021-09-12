#!/bin/bash
set -euo pipefail

shopt -s nullglob dotglob extglob globstar

readarray -t patterns <<< "$2"

for pattern in "${patterns[@]}"; do
  # shellcheck disable=SC2206
  IFS= paths=($pattern)

  for path in "${paths[@]}"; do
    tectonic -X -c 'minimal' compile "$path"
  done
done

curl -fsS \
  -H "Authorization: Bearer $1" \
  -H 'Accept: application/vnd.github.v3+json' \
  -d '{"tag_name": "latest"}' \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/releases"
