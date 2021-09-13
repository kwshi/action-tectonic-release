#!/bin/bash
set -euo pipefail
shopt -s nullglob dotglob extglob globstar

declare \
  TOKEN="$1" \
  TAG="$2" \
  PATTERNS="$3" \
  UPLOAD_URL="https://uploads.github.com/repos/$GITHUB_REPOSITORY/releases" \
  API_URL="https://api.github.com/repos/$GITHUB_REPOSITORY/releases"

declare -a CURL_API=(
  curl -fs
  -H "Authorization: Bearer $TOKEN"
  -H 'Accept: application/vnd.github.v3+json'
)

declare -a patterns paths=()
declare path pdf id data url

function percent-encode {
  local encoded='' c
  for (( i=0; i<${#1}; ++i )); do
    c="${1:i:1}"
    case "$c" in
      [0-9A-Za-z_.~-]) encoded="$encoded$c";;
      *) printf -v encoded "%s%%%02x" "$encoded" "'$c";;
    esac
  done
  echo "$encoded"
}

# glob source files
echo '::group::Finding source files'
readarray -t patterns <<< "$PATTERNS"
for pattern in "${patterns[@]}"; do
  # shellcheck disable=SC2206
  IFS= paths+=($pattern)
done
for path in "${paths[@]}"; do
  echo "$path"
  if [[ ! -e "$path" ]]; then
    echo "::error::No path matching ${path@Q}"
    exit 1
  fi
done
echo '::endgroup::'

# compile pdfs
for path in "${paths[@]}"; do
  echo "::group::Compiling ${path@Q}"
  tectonic -X -c 'minimal' compile "$path"
  echo '::endgroup::'
done

# setup release
echo '::group::Creating release'
if id="$(
  "${CURL_API[@]}" "$API_URL/tags/$(percent-encode "$TAG")" \
    | jq -rc '.id'
)"; then
  "${CURL_API[@]}" -S -X 'DELETE' "$API_URL/$id"
fi
data="$(jq -cn --arg 'tag' "$TAG" '{tag_name: $tag}')"
id="$("${CURL_API[@]}" -S -d "$data" "$API_URL" | jq -rc '.id')"
echo '::endgroup::'

# upload pdfs
echo '::group::Uploading release assets'
for path in "${paths[@]}"; do
  pdf="${path%.*}.pdf"
  name="${pdf##*/}"

  url="$(
    "${CURL_API[@]}" -S \
      -H 'Content-Type: application/pdf' \
      --data-binary "@$pdf" \
      "$UPLOAD_URL/$id/assets?name=$(
        percent-encode "$name"
      )&label=$(
        percent-encode "$pdf"
      )" | jq -rc '.browser_download_url'
  )"

  echo "${pdf@Q}: $url"
done
echo '::endgroup::'
