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

set -x
echo 'checking for existing release'
if read -r url < <(api 'releases/tags/latest' | jq -rc '.url'); then
  echo 'existing release, deleting'
  api "$url" -X 'DELETE'
fi

echo 'creating new release'
api 'releases' -d '{"tag_name": "latest"}'

#echo 'uploading'
#api 'releases/assets"

echo '::endgroup::'
