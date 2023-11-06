#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

declare -a mandatory
mandatory=(
  PKG
)

for var in "${mandatory[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Environment variable ${var} must be set"
    exit 1
  fi
done

echo "Testing ${PKG}/..."

go test -v \
  $(go list "./${PKG}/...")