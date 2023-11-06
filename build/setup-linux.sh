#!/usr/bin/env bash

# config
# yq
yq_path=/usr/bin
yq_version=4.2.0
yq_release_url=https://github.com/mikefarah/yq/releases/download

# golangci-lint
golangci_path=/usr/bin
golangci_version=1.54.2
golangci_release_url=https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh

# skaffold
skaffold_path=/usr/local/bin
skaffold_version=2.5.0
skaffold_release_url=https://storage.googleapis.com/skaffold/releases

# buf
buf_path=/usr/local/bin
buf_version=1.19.0
buf_release_url=https://github.com/bufbuild/buf/releases/download

# kustomize
kustomize_path=/usr/local/bin
kustomize_version=4.5.7
kustomize_release_url=https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh

# terraform
terraform_path=/usr/bin
terraform_version=1.5.2
terraform_release_url=https://releases.hashicorp.com/terraform

# init
# Get system info.
os=linux
if [[ "${OSTYPE}" == linux* ]]; then
  os=linux
elif [[ "${OSTYPE}" == drawin* ]]; then
  os=drawin
fi
arch=$(uname -m)

# Use amd64 instead of x86_64, because skaffold and terraform don't have x86_64 package.
arch_amd64=$(echo "${arch}" | awk '{if($1 == "x86_64") print "amd64";else print $1 }')

# Generate file name.
yq_file_name=yq_${os}_${arch_amd64}
skaffold_file_name=skaffold-${os}-${arch_amd64}
buf_file_name=buf-$(uname -s)-${arch}
terraform_file_name=terraform_${terraform_version}_${os}_${arch_amd64}.zip

# prepare
# Verify that the file exists.
for file in "${skaffold_path}/skaffold" "${buf_path}/buf" "${kustomize_path}/kustomize" "${terraform_path}/terraform"; do
  [ -f "${file}" ] && echo "${file} exists.Remove it first." && exit 1
done

# Create temp directory.
tmp_dir=$(mktemp -d)
if [[ -z "${tmp_dir}" || ! -d "${tmp_dir}" ]]; then
  echo "Could not create temp dir."
  exit 1
fi

# Define clean function.
function cleanup() {
  rm -rf "${tmp_dir}"
}

# Ensure that the cleanup is always executed.
trap cleanup EXIT

pushd "${tmp_dir}" >&/dev/null || exit 1

# install
if ! command -v yq >/dev/null 2>&1; then
  echo "Install yq"
  wget "${yq_release_url}/v${yq_version}/${yq_file_name}" -O "${yq_path}/yq"
  chmod +x "${yq_path}/yq"
fi

if ! command -v golangci-lint >/dev/null 2>&1; then
  echo "Install golangci-lint"
  curl -sSfL "${golangci_release_url}" | sh -s -- -b "${golangci_path}" "v${golangci_version}"
fi

echo "Install skaffold."
curl -Lo skaffold "${skaffold_release_url}/v${skaffold_version}/${skaffold_file_name}"
chmod +x skaffold
mv skaffold "${skaffold_path}/"

echo "Install buf."
curl -sSL buf "${buf_release_url}/v${buf_version}/${buf_file_name}"
chmod +x buf
mv buf "${buf_path}/"

echo "Install kustomize."
curl -s "${kustomize_release_url}" >install_kustomize.sh
chmod +x install_kustomize.sh
bash install_kustomize.sh "${kustomize_version}"
mv kustomize "${kustomize_path}/"

echo "Install terraform."
curl -sS "${terraform_release_url}/${terraform_version}/${terraform_file_name}"
unzip -q "${terraform_file_name}"
chmod +x terraform
mv terraform "${terraform_path}/"

# verify
for file in "${skaffold_path}/skaffold" "${buf_path}/buf" "${kustomize_path}/kustomize" "${terraform_path}/terraform"; do
  if [[ -x "${file}" ]]; then
    echo "Install ${file#**/} successfully."
  else
    echo "Install ${file#**/} failed."
  fi
done
