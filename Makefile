.PHONY: help bootstrap clean teardown delete-cluster

help:
	@echo "CluedOps - GitOps-driven troubleshooting simulator"
	@echo ""
	@echo "Available targets:"
	@echo "  make bootstrap      - Provision k3d cluster, install ArgoCD, and deploy applications"
	@echo "  make teardown       - Destroy k3d cluster and clean up resources"
	@echo "  make delete-cluster - Delete the k3d cluster directly"
	@echo "  make clean          - Remove cluster and reset environment"
	@echo ""

bootstrap:
	@bash hack/bootstrap.sh

delete-cluster:
	@k3d cluster delete cluedops || true

teardown: delete-cluster

clean: teardown
