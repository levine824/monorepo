#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

declare -a mandatory
mandatory=(
  APP_NAME
  ARTIFACT_NAME
  PKG
  BIN_DIR
  TARGET_OS
  TARGET_ARCH
)

for var in "${mandatory[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Environment variable ${var} must be set"
    exit 1
  fi
done

GO_BUILD_CMD="go build"

# Set go env and pre-download dependencies.
# Cache the directories(~/.cache/go-build && ~/go/pkg/mod) to accelerate the build.
# If needed, uncomment the following line.
# go env -w GOPROXY=https://goproxy.cn,direct
export GO111MODULE=on
go mod download && go mod verify

echo "Building targets for ${TARGET_OS}/${TARGET_ARCH}, generated targets in ${BIN_DIR} directory."

export CGO_ENABLED=0
export GOOS=${TARGET_OS}
export GOARCH=${TARGET_ARCH}

echo "Building ${PKG}/cmd/main.go"

${GO_BUILD_CMD} \
  -ldflags "-s -w \
  -X main.Version=${VERSION}" \
  -o "${BIN_DIR}/${ARTIFACT_NAME}" \
  "${PKG}/cmd/main.go"
