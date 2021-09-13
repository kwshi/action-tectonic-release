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

function api {
  local path="$1"
  shift
  curl -fsS \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H 'Accept: application/vnd.github.v3+json' \
    "$@" "https://api.github.com/repos/$GITHUB_REPOSITORY/$path"
}

echo 'checking for existing release'
if read -r id < <(api 'releases/tags/latest' | jq -rc '.id'); then
  echo 'existing release, deleting'
  api "releases/$id" -X 'DELETE'
fi

echo 'creating new release'
read -r id < <(api 'releases' -d '{"tag_name": "latest"}' | jq -rc '.id')

echo 'uploading release assets'
curl -fsS \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H 'Accept: application/vnd.github.v3+json' \
  --data-binary '@lgcs105.cls'
  "https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases/$id/assets?name=lgcs105cls"
#api "releases/$id/assets?name=lgcs105cls" --data-binary '@lgcs105.cls'
#api 'releases/assets"

echo '::endgroup::'
