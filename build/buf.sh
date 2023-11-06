#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

declare -a mandatory
mandatory=(
  BUF_WORKSPACE
  BUF_DIRECTORIES
)

for var in "${mandatory[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Environment variable ${var} must be set"
    exit 1
  fi
done

case $1 in
update)
  for buf_dir in ${BUF_DIRECTORIES}; do
    buf mod update "${buf_dir}"
  done
  ;;
lint)
  for buf_dir in ${BUF_DIRECTORIES}; do
    buf lint "${buf_dir}"
  done
  ;;
generate)
  buf generate "${BUF_WORKSPACE}"
  ;;
build)
  buf build "${BUF_WORKSPACE}"
  ;;
*)
  echo 'Args does not exist, please input update, lint, generate or build.'
  ;;
esac