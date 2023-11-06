#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

msg=${1}

declare -a mandatory
mandatory=(
  ARGOCD_REPO
  ARGOCD_DIR
  USER_EMAIL
  USER_NAME
)

for var in "${mandatory[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Environment variable ${var} must be set"
    exit 1
  fi
done

pushd "${ARGOCD_DIR}"

if [[ "${CI}" == 'true' ]]; then
  git config user.email "${USER_EMAIL}"
  git config user.name "${USER_NAME}"
fi

git add remote argocd "${ARGOCD_REPO}"

git add -A
git commit -m "${msg}"
git push argocd HEAD:master

pushd +1
