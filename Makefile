# Set debug.
DBG_MAKEFILE ?=
ifeq ($(DBG_MAKEFILE),1)
    $(warning: starting Makefile for goals "$(MAKECMDGOALS)")
    $(warning: $(shell date))
else
    # If we're not debugging the Makefile, don't echo recipes.
    MAKEFLAGS += -s
endif

# Set default shell.
SHELL := /usr/bin/env bash -o errexit -o pipefail -o nounset

# We don't need make's built-in rules.
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

# Add the following 'help' target to your Makefile.
# And add help text after each target name starting with '\#\#'.
.DEFAULT_GOAL := help

# Constants used throughout.
.EXPORT_ALL_VARIABLES:

APP_NAME ?=
ifndef APP_NAME
  $(error APP_NAME must be set.)
endif

ARTIFACT_NAME ?= ${APP_NAME}

PKG = app/$(APP_NAME)

OUT_DIR ?= _output
BIN_DIR = $(OUT_DIR)/bin

REPO_INFO ?= $(shell git config --get remote.origin.url)

COMMIT_SHA ?= $(shell git rev-parse --short HEAD)
COMMIT_TIMESTAMP ?= $(shell git log -1 --pretty=format:"%ct")

BUF_WORKSPACE ?= .
BUF_WORK_YAML = $(BUF_WORKSPACE)/buf.work.yaml
BUF_DIRECTORIES = $(shell yq '.directories' $(BUF_WORK_YAML) | awk -F "- " 'BEGIN{ORS=" "}{print $$2}' | xargs)

HOST_OS = $(shell which go >/dev/null 2>&1 && go env GOHOSTOS)
HOST_ARCH = $(shell which go >/dev/null 2>&1 && go env GOARCH)

TARGET_OS ?= $(HOST_OS)
TARGET_ARCH ?= $(HOST_ARCH)

VERSION ?= $(shell cat VERSION | sed 's|v||')

BASE_DOCKERFILE = build/image/base/Dockerfile
COMMON_DOCKERFILE = build/image/Dockerfile

TAG ?= $(COMMIT_SHA)-$(COMMIT_TIMESTAMP)
REGISTRY ?= levine824
TARGET_IMAGE ?= $(REGISTRY)/$(APP_NAME):$(TAG)

IMAGE_ARCHIVE_DIR ?= $(OUT_DIR)/images

PROFILE ?= dev

ARGOCD_DIR ?= $(OUT_DIR)/argocd
OVERLAY_DIR = deploy/kustomize/$(APP_NAME)/overlays/$(PROFILE)
VARIANT_DIR ?= $(ARGOCD_DIR)/$(PROFILE)/$(APP_NAME)

ARGOCD_REPO ?= https://github.com/levine824/monorepo-argocd.git
USER_EMAIL ?= actions@github.com
USER_NAME ?= Github Actions

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

all: setup-linux lint test build manifest ## Run all stages

.PHONY: gen
gen: ## Run buf generate
	@$(MAKE) buf-generate

.PHONY: build
build: gen ## Build images
	@$(MAKE) go-build
	@$(MAKE) docker-build

.PHONY: test
test: ## Run go test
	@$(MAKE) go-test

.PHONY: lint
lint: ## Run golangci-lint
	@$(MAKE) go-lint

.PHONY: manifest
manifest: ## Build and push manifests
	@$(MAKE) git_clone_argocd
	@$(MAKE) kustomize-build
	@$(MAKE) git_push_argocd

.PHONY: setup-linux
setup-linux: ## Install tools
	@./build/setup-linux.sh

.PHONY: clean
clean: ## Delete output directory and images
	@./build/clean.sh

.PHONY: buf-mod-update
buf-mod-update: ## Run buf mod update
	@./build/buf.sh update

.PHONY: buf-lint
buf-lint: ## Run buf lint
	@./build/buf.sh lint

.PHONY: buf-generate
buf-generate: buf-mod-update buf-lint ## Run buf generate
	@./build/buf.sh generate

.PHONY: buf-build
buf-build: buf-mod-update buf-lint ## Run buf build
	@./build/buf.sh build

.PHONY: go-build
go-build: ## Run go build
	@./build/build.sh

.PHONY: go-test
go-test: ## Run go test
	@./build/test.sh

.PHONY: go-lint
go-lint: ## Run go lint
	@golangci-lint run $(PKG)/...

.PHONY: docker-build
docker-build: ## Run docker build
	@docker build \
       -f $(BASE_DOCKERFILE) \
       -t $(TARGET_IMAGE) \
       $(BIN_DIR) \
       --build-arg APP=$(APP_NAME) \
       --label "org.opencontainers.image.source=$(REPO_INFO)"

.PHONY: docker-save
docker-save: ## Run docker save
	@[ -d $(IMAGE_ARCHIVE_DIR) ] || mkdir -p $(IMAGE_ARCHIVE_DIR)
	@docker save \
       $(TARGET_IMAGE) \
       | gzip > $(IMAGE_ARCHIVE_DIR)/${APP_NAME}.tar.gz

.PHONY: docker-push
docker-push: ## Run docker push
	@docker push $(TARGET_IMAGE)

.PHONY: build_in_docker
build_in_docker: ## Run multi-stage build
	@docker build \
	   -f $(COMMON_DOCKERFILE) \
	   -t $(TARGET_IMAGE) \
	   . \
	   --build-arg APP=$(APP_NAME) \
	   --build-arg VERSION=$(VERSION) \
	   --build-arg TARGET_OS=$(TARGET_OS) \
	   --build-arg TARGET_ARCH=$(TARGET_ARCH) \
	   --label "org.opencontainers.image.source=$(REPO_INFO)"

.PHONY: kustomize-build
kustomize-build: ## Run kustomize build
	@[ -d $(VARIANT_DIR) ] || mkdir -p $(VARIANT_DIR)
	@kustomize build $(OVERLAY_DIR) | envsubst >$(VARIANT_DIR)/$(APP_NAME).yaml

.PHONY: git_clone_argocd
git_clone_argocd: ## Clone argocd repo
	@git clone $(ARGOCD_REPO) $(ARGOCD_DIR)

.PHONY: git_push_argocd
git_push_argocd: ## Push to argocd repo
	@./build/push.sh "chore(*): update yaml [skip ci]"
