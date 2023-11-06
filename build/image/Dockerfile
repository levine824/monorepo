# syntax = docker/dockerfile:1.2
FROM golang:1.20.0 AS builder

WORKDIR /go/src/github.com/levine824/monorepo

COPY go.mod go.sum ./

ENV GO111MODULE=on

RUN --mount=type=cache,id=go_mod_cache,target=/go/pkg/mod \
    go mod download && go mod verify

COPY . .

ARG APP
ARG VERSION
ARG TARGET_OS=linux
ARG TARGET_ARCH=amd64

ENV CGO_ENABLED=0
ENV GOOS=${TARGET_OS}
ENV GOARCH=${TARGET_ARCH}

RUN --mount=type=cache,id=go_cache,target=/root/.cache/go-build \
    go build -ldflags "-s -w -X main.Version=${VERSION}" -o /go/bin/${APP} app/${APP}/cmd/main.go

FROM gcr.io/distroless/base
# Kubernetes v1.23 has now introduced built-in gRPC health checking
# https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-grpc-liveness-probe
#
# RUN GRPC_HEALTH_PROBE_VERSION=v0.3.1 && \
#     wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
#     chmod +x /bin/grpc_health_probe

ARG APP

WORKDIR /

COPY --from=builder /go/bin/${APP} .

CMD ["/${APP}"]