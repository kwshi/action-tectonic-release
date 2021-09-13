#!/bin/bash
set -euo pipefail
shopt -s nullglob dotglob extglob globstar

declare GITHUB_TOKEN="$1" PATTERNS="$2"

readarray -t patterns <<< "$PATTERNS"
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

CURL=(
  curl -fsS
  -H "Authorization: Bearer $GITHUB_TOKEN"
  -H 'Accept: application/vnd.github.v3+json'
)

echo 'checking for existing release'
if read -r id < <("${CURL[@]}" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/latest" \
  | jq -rc '.id'
  ); then
  echo 'existing release, deleting'
  "${CURL[@]}" -X 'DELETE' \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$id"
fi

echo 'creating new release'
read -r id < <("${CURL[@]}" -d '{"tag_name": "latest"}' \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/releases" \
  | jq -rc '.id'
)

echo 'uploading release assets'
"${CURL[@]}" \
  -H 'Content-Type: text/plain' \
  --data-binary '@lgcs105.cls' \
  "https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases/$id/assets?name=a/lgcs105.cls&label=hello/test"

echo '::endgroup::'
