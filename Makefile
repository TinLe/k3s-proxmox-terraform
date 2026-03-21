ROOT_DIR=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
SHELL=/bin/bash

# Default environment
ENV ?= dev
ENV_DIR = environments/$(ENV)

.PHONY: help setup init plan apply deploy destroy clean status ssh logs kubeconfig test venv clean-venv

# Default target
help:
	@echo "K3s on Proxmox - Available Commands (Terragrunt + OpenTofu):"
	@echo ""
	@echo "  make setup       - Run initial setup and check prerequisites"
	@echo "  make init        - Initialize Terragrunt/OpenTofu"
	@echo "  make plan        - Show Terragrunt plan"
	@echo "  make apply       - Create VMs with Terragrunt"
	@echo "  make deploy      - Full deployment (Terragrunt + Ansible)"
	@echo "  make destroy     - Destroy all resources"
	@echo "  make clean       - Clean Terragrunt/OpenTofu cache"
	@echo ""
	@echo "  make status      - Show cluster status"
	@echo "  make ssh         - SSH to control plane"
	@echo "  make logs        - View K3s logs on control plane"
	@echo "  make kubeconfig  - Export kubeconfig"
	@echo "  make test        - Deploy test nginx application"
	@echo "  make venv        - Setup project virtual environment"
	@echo "  make clean-venv  - Clean virtualenv files"
	@echo ""
	@echo "Environment Selection:"
	@echo "  make plan ENV=dev    - Plan for dev environment (default)"
	@echo "  make apply ENV=prod  - Apply for prod environment"
	@echo ""

setup:
	@echo "Running setup..."
	./setup-terragrunt.sh

init:
	@echo "Initializing Terragrunt/OpenTofu for $(ENV) environment..."
	cd $(ENV_DIR) && terragrunt init

plan: init
	@echo "Planning deployment for $(ENV) environment..."
	cd $(ENV_DIR) && terragrunt plan

apply: init
	@echo "Applying Terragrunt configuration for $(ENV) environment..."
	cd $(ENV_DIR) && terragrunt apply

deploy:
	@echo "Running full deployment for $(ENV) environment..."
	./deploy.sh $(ENV)

destroy:
	@echo "Destroying infrastructure for $(ENV) environment..."
	cd $(ENV_DIR) && terragrunt destroy

clean:
	@echo "Cleaning Terragrunt/OpenTofu cache..."
	find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	rm -f terraform.tfstate* *.log

status:
	@echo "Cluster Status:"
	@export KUBECONFIG=$(shell pwd)/kubeconfig && kubectl get nodes -o wide
	@echo ""
	@export KUBECONFIG=$(shell pwd)/kubeconfig && kubectl get pods -A

ssh:
	@echo "Connecting to control plane..."
	@ssh ubuntu@192.168.1.180

logs:
	@echo "K3s logs from control plane:"
	@ssh ubuntu@192.168.1.180 "sudo journalctl -u k3s -n 50"

kubeconfig:
	@echo "Kubeconfig location: $(shell pwd)/kubeconfig"
	@echo ""
	@echo "Export with:"
	@echo "export KUBECONFIG=$(shell pwd)/kubeconfig"

test:
	@echo "Deploying test nginx application..."
	@export KUBECONFIG=$(shell pwd)/kubeconfig && \
		kubectl create deployment nginx --image=nginx && \
		kubectl expose deployment nginx --port=80 --type=NodePort && \
		kubectl get svc nginx
	@echo ""
	@echo "Access nginx at: http://192.168.1.185:<NodePort>"

# Show Terragrunt outputs
outputs:
	@cd $(ENV_DIR) && terragrunt output

# Get K3s token
token:
	@cd $(ENV_DIR) && terragrunt output -raw k3s_token

# Ping all nodes
ping:
	@echo "Pinging control plane..."
	@ping -c 1 192.168.1.180 > /dev/null && echo "✓ Control plane (192.168.1.180)" || echo "✗ Control plane unreachable"
	@echo "Pinging workers..."
	@ping -c 1 192.168.1.185 > /dev/null && echo "✓ Worker 1 (192.168.1.185)" || echo "✗ Worker 1 unreachable"
	@ping -c 1 192.168.1.186 > /dev/null && echo "✓ Worker 2 (192.168.1.186)" || echo "✗ Worker 2 unreachable"
	@ping -c 1 192.168.1.187 > /dev/null && echo "✓ Worker 3 (192.168.1.187)" || echo "✗ Worker 3 unreachable"

# Quick cluster info
info:
	@echo "=== Cluster Information ($(ENV)) ==="
	@cd $(ENV_DIR) && terragrunt output -json cluster_info | jq .
	@echo ""
	@echo "=== Node IPs ==="
	@echo "Control Plane: $(shell cd $(ENV_DIR) && terragrunt output -json control_plane_ips 2>/dev/null | jq -r '.[]' || echo 'N/A')"
	@echo "Workers: $(shell cd $(ENV_DIR) && terragrunt output -json worker_ips 2>/dev/null | jq -r '.[]' || echo 'N/A')"

venv: requirements.txt requirements.yml
	@echo "Setting up Python virtual environment with uv..."
	@if [ ! -f pyproject.toml ]; then uv init --no-readme --no-workspace; fi
	@if [ ! -d .venv ]; then uv venv --seed; fi
	@. .venv/bin/activate && \
		uv pip install -r requirements.txt && \
		.venv/bin/ansible-galaxy install -r requirements.yml
	@echo "✓ Virtual environment ready"
	@echo "Activate with: source .venv/bin/activate"

clean-venv:
	@echo "Cleaning virtualenv files..."
	rm -rf .venv

# Validate Terragrunt configuration
validate:
	@echo "Validating Terragrunt configuration for $(ENV)..."
	cd $(ENV_DIR) && terragrunt validate

# Show Terragrunt dependency graph
graph:
	@echo "Generating dependency graph for $(ENV)..."
	cd $(ENV_DIR) && terragrunt graph-dependencies | dot -Tpng > terragrunt-graph.png
	@echo "Graph saved to terragrunt-graph.png"

# Run Terragrunt for all environments
plan-all:
	@echo "Planning all environments..."
	@for env in dev prod; do \
		echo "=== Planning $$env ==="; \
		cd environments/$$env && terragrunt plan; \
		cd ../..; \
	done

apply-all:
	@echo "Applying all environments..."
	@for env in dev prod; do \
		echo "=== Applying $$env ==="; \
		cd environments/$$env && terragrunt apply -auto-approve; \
		cd ../..; \
	done

destroy-all:
	@echo "Destroying all environments..."
	@for env in dev prod; do \
		echo "=== Destroying $$env ==="; \
		cd environments/$$env && terragrunt destroy -auto-approve; \
		cd ../..; \
	done
