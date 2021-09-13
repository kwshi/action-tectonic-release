#!/bin/bash
set -euo pipefail
shopt -s nullglob dotglob extglob globstar

declare GITHUB_TOKEN="$1" PATTERNS="$2"
declare -a CURL_API=(
  curl -fsS
  -H "Authorization: Bearer $GITHUB_TOKEN"
  -H 'Accept: application/vnd.github.v3+json'
)

declare -a patterns paths=()
declare path pdf

readarray -t patterns <<< "$PATTERNS"
for pattern in "${patterns[@]}"; do
  # shellcheck disable=SC2206
  IFS= paths+=($pattern)
done

for path in "${paths[@]}"; do
  echo "::group::Compiling ${path@Q}"
  tectonic -X -c 'minimal' compile "$path"
  echo '::endgroup::'
done

echo '::group::Creating release'
if read -r id < <("${CURL_API[@]}" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/tags/latest" \
  | jq -rc '.id'
  ); then
  echo 'existing release, deleting'
  "${CURL_API[@]}" -X 'DELETE' \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/$id"
fi
read -r id < <("${CURL_API[@]}" -d '{"tag_name": "latest"}' \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/releases" \
  | jq -rc '.id'
)
echo '::endgroup::'

echo '::group::Uploading release assets'
for path in "${paths[@]}"; do
  pdf="${path%.*}.pdf"
  echo "$path"
  "${CURL_API[@]}" \
    -H 'Content-Type: application/pdf' \
    --data-binary "@$pdf" \
    "https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases/$id/assets?name=$pdf&label=$pdf"

done
echo '::endgroup::'
