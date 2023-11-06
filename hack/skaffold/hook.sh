#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

declare -a mandatory
mandatory=(
  VERSION
  SKAFFOLD_IMAGE
)

for var in "${mandatory[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Environment variable ${var} must be set"
    exit 1
  fi
done

APP_NAME=$1

OVERLAY_DIR=deploy/kustomize/${APP_NAME}/overlays/dev

export TARGET_IMAGE=${SKAFFOLD_IMAGE}

kustomize build "${OVERLAY_DIR}" | envsubst >"hack/skaffold/${APP_NAME}.yaml"
