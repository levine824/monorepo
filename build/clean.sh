#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

declare -a mandatory
mandatory=(
  OUT_DIR
  TARGET_IMAGE
)

for var in "${mandatory[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Environment variable ${var} must be set"
    exit 1
  fi
done

[ -e "${OUT_DIR}" ] && rm -rf "${OUT_DIR}"

docker image prune -f

IMAGE_ID=$(docker image ls "${TARGET_IMAGE}" -q)

[ -n "${IMAGE_ID}" ] && docker rmi "${IMAGE_ID}"
