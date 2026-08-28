#!/usr/bin/env bash
set -Eeuo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-cluedops}"
TRAEFIK_PORT=8085
TRAEFIK_PORT_SSL=8443

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
    --port "${TRAEFIK_PORT}:80@loadbalancer" \
    --port "${TRAEFIK_PORT_SSL}:443@loadbalancer"
    #--k3s-arg "--disable=traefik@server:0"
  log "Cluster '$CLUSTER_NAME' created successfully"
}

setup_argocd() {
  log "==> Bootstrapping Argo CD (namespace, core manifests, Application)"

  log "Creating 'argocd' namespace (safe to run if it already exists)"
  kubectl create namespace argocd || true

  log "Applying Argo CD install manifests into 'argocd' namespace"
  kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  log "Applying local Argo CD Application manifest: clusters/local/argocd-app.yaml"
  kubectl apply -f clusters/local/argocd-app.yaml

  wait_for_argocd_pods_running() {
    # Wait until all pods in the 'argocd' namespace report status == Running
    local timeout=${1:-300} # seconds
    local interval=5
    local elapsed=0

    log "Waiting up to ${timeout}s for all pods in 'argocd' to be 'Running'"
    while true; do
      # Collect pod phases into an array portably (Bash 3.2+)
      phases=()
      while IFS= read -r line; do
        [[ -n "$line" ]] && phases+=("$line")
      done < <(kubectl get pods -n argocd -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null || true)

      if [ "${#phases[@]}" -eq 0 ]; then
        log "No pods found in 'argocd' yet; sleeping ${interval}s"
      else
        all_running=true
        for p in "${phases[@]}"; do
          if [ "$p" != "Running" ]; then
            all_running=false
            break
          fi
        done

        if $all_running; then
          log "All argocd pods are 'Running'"
          return 0
        fi

        log "Not all pods are 'Running' yet: ${phases[*]}; sleeping ${interval}s"
      fi

      sleep "$interval"
      elapsed=$((elapsed + interval))
      if [ "$elapsed" -ge "$timeout" ]; then
        log "Timed out waiting for argocd pods to be Running after ${timeout}s"
        return 1
      fi
    done
}

  if wait_for_argocd_pods_running 300; then
    log "Setting up ArgoCD Ingress..."
    kubectl apply -f clusters/local/argocd-ingress.yaml
  else
    log "Skipping apply: not all argocd pods reached 'Running' within timeout"
    exit 1
  fi

  log "Setting up \"${CLUSTER_NAME}\" application set..."
  kubectl apply -f clusters/local/${CLUSTER_NAME}.yaml
  log "Argo CD bootstrap completed"
}

main() {
  log "CluedOps bootstrap starting"
  check_prerequisites
  create_cluster

  log "Prerequisites validation and cluster provisioning are prepared."

  # Bootstrap Argo CD and the Application CR
  echo "Bootstrap Argo CD and Application CR"
  setup_argocd
}

main "$@"
