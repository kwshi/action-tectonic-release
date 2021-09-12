#!/bin/bash
set -euo pipefail

echo "$1" | \
  while IFS= read -r pattern; do
    echo "PATTERN: $pattern"
  done
