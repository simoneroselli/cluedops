.PHONY: help bootstrap clean teardown

help:
	@echo "CluedOps - GitOps-driven troubleshooting simulator"
	@echo ""
	@echo "Available targets:"
	@echo "  make bootstrap    - Provision k3d cluster, install ArgoCD, and deploy applications"
	@echo "  make teardown     - Destroy k3d cluster and clean up resources"
	@echo "  make clean        - Remove cluster and reset environment"
	@echo ""

bootstrap:
	@bash hack/bootstrap.sh

teardown:
	@bash hack/bootstrap.sh teardown

clean: teardown
