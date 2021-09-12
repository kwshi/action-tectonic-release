#!/bin/sh
set -eu

echo "$1" | \
  while read -r pattern; do
    echo "PATTERN: $pattern"
  done
exit 1
