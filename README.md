# CluedOps

A GitOps-driven troubleshooting simulator where an AI "Game Master" randomly injects obfuscated, human-engineered incidents into a local Kubernetes cluster for you to investigate.

## Local bootstrap

- `make boot` creates or reuses the `cluedops` k3d cluster, installs Argo CD, and deploys the applications.
- `make argocd` installs Argo CD into an existing running k3d cluster without creating one.
