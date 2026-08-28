.PHONY: help bootstrap argocd clean teardown delete-cluster

help:
	@echo "CluedOps - GitOps-driven troubleshooting simulator"
	@echo ""
	@echo "Available targets:"
	@echo "  make boot           - Provision k3d cluster, install ArgoCD, and deploy applications"
	@echo "  make argocd         - Install ArgoCD into an existing running k3d cluster"
	@echo "  make teardown       - Destroy k3d cluster and clean up resources"
	@echo "  make delete-cluster - Delete the k3d cluster directly"
	@echo "  make clean          - Remove cluster and reset environment"
	@echo ""

boot:
	@bash hack/bootstrap.sh

argocd:
	@bash hack/bootstrap.sh --setup-argocd

delete-cluster:
	@k3d cluster delete cluedops || true

teardown: delete-cluster

clean: teardown
