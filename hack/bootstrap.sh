#!/usr/bin/env bash
set -Eeuo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-cluedops}"
K3S_SERVER_ARGS=("--disable=traefik")

log() {
  printf '%s\n' "$*"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "ERROR: required command not found: $cmd"
    exit 1
  fi
}

ensure_docker_running() {
  if ! docker info >/dev/null 2>&1; then
    log "ERROR: docker is installed but not reachable. Please ensure Docker is running."
    exit 1
  fi
}

check_prerequisites() {
  log "==> Validating required tooling"

  require_cmd docker
  require_cmd kubectl
  require_cmd helm
  require_cmd k3d

  ensure_docker_running

  log "Validated: docker, kubectl, helm, and k3d are available"
}

cluster_exists() {
  k3d cluster list 2>/dev/null | awk '{print $1}' | grep -Fxq "$CLUSTER_NAME"
}

create_cluster() {
  log "==> Provisioning k3d cluster: $CLUSTER_NAME"

  if cluster_exists; then
    log "Cluster '$CLUSTER_NAME' already exists; reusing it."
    return 0
  fi

  # The cluster is intentionally created with two agent nodes and port mappings
  # for ingress traffic on 80/443, matching the project requirement.
  k3d cluster create "$CLUSTER_NAME" \
    --servers 1 --agents 2 \
    --port "80:80@loadbalancer" \
    --port "443:443@loadbalancer"

  log "Cluster '$CLUSTER_NAME' created successfully"
}

main() {
  log "CluedOps bootstrap starting"
  check_prerequisites
  create_cluster

  log "Prerequisites validation and cluster provisioning are prepared."
  log "Next steps in later PRs: install ArgoCD, apply GitOps manifests, and validate health."
}

main "$@"