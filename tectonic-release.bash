#!/bin/bash
set -euo pipefail

shopt -s nullglob dotglob extglob globstar

readarray -t patterns <<< "$2"

for pattern in "${patterns[@]}"; do
  # shellcheck disable=SC2206
  IFS= paths=($pattern)
  for path in "${paths[@]}"; do

    echo "::group::Compiling ${path@Q}"
    tectonic -X -c 'minimal' compile "$path"
    echo '::endgroup::'

  done
done

echo '::group::Creating release'

curl=(
  curl -fsS
  -H "Authorization: Bearer $1"
  -H 'Accept: application/vnd.github.v3+json'
)

echo 'deleting'
"${curl[@]}" -X 'DELETE' \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/latest"

echo 'creating'
"${curl[@]}" -d '{"tag_name": "latest"}' \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/releases"

echo 'uploading'
"${curl[@]}" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/latest/assets"

echo '::endgroup::'
