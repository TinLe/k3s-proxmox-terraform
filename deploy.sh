#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Environment (default to dev)
ENV=${1:-dev}
ENV_DIR="environments/$ENV"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}K3s on Proxmox Deployment (Terragrunt + OpenTofu)${NC}"
echo -e "${GREEN}Environment: $ENV${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if environment directory exists
if [ ! -d "$ENV_DIR" ]; then
    echo -e "${RED}Error: Environment directory '$ENV_DIR' not found${NC}"
    echo "Available environments: dev, prod"
    exit 1
fi

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check for OpenTofu or Terraform
if command -v tofu &> /dev/null; then
    TF_CMD="tofu"
    echo -e "${GREEN}✓ OpenTofu found${NC}"
elif command -v terraform &> /dev/null; then
    TF_CMD="terraform"
    echo -e "${YELLOW}⚠ Using Terraform (OpenTofu recommended)${NC}"
else
    echo -e "${RED}✗ Neither OpenTofu nor Terraform found${NC}"
    echo "Please install OpenTofu: https://opentofu.org/docs/intro/install/"
    exit 1
fi

# Check for Terragrunt
if ! command -v terragrunt &> /dev/null; then
    echo -e "${RED}✗ Terragrunt not found${NC}"
    echo "Please install Terragrunt: https://terragrunt.gruntwork.io/docs/getting-started/install/"
    exit 1
fi
echo -e "${GREEN}✓ Terragrunt found${NC}"

# Check for uv
if ! command -v uv &> /dev/null; then
    echo -e "${RED}✗ uv not found${NC}"
    echo "Please install uv: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi
echo -e "${GREEN}✓ uv found${NC}"

# Setup Python virtual environment with Ansible
echo -e "${YELLOW}Setting up Python virtual environment...${NC}"
if [ ! -d .venv ]; then
    if [ ! -f pyproject.toml ]; then
        uv init --no-readme --no-workspace
    fi
    uv venv --seed
fi

# Activate virtual environment and install dependencies
source .venv/bin/activate

if [ -f requirements.txt ]; then
    uv pip install -r requirements.txt
fi

if [ -f requirements.yml ]; then
    .venv/bin/ansible-galaxy install -r requirements.yml
fi

echo -e "${GREEN}✓ Python virtual environment ready${NC}"
echo -e "${GREEN}✓ Ansible installed${NC}"

# Check for SSH key
if [ ! -f ~/.ssh/id_ed25519.pub ]; then
    echo -e "${RED}✗ SSH key not found at ~/.ssh/id_ed25519.pub${NC}"
    echo "Generate one with: ssh-keygen -t ed25519"
    exit 1
fi
echo -e "${GREEN}✓ SSH key found${NC}"

# Check for environment variables
if [ -z "$PROXMOX_API_TOKEN_SECRET" ]; then
    echo -e "${YELLOW}⚠ PROXMOX_API_TOKEN_SECRET not set${NC}"
    echo "Please set environment variables or create .envrc file"
    echo "See .envrc.example for reference"
    exit 1
fi

echo ""
echo -e "${GREEN}All prerequisites met!${NC}"
echo ""

# Step 1: Initialize Terragrunt
echo -e "${YELLOW}Step 1: Initializing Terragrunt...${NC}"
cd "$ENV_DIR"
terragrunt init
cd ../..
echo -e "${GREEN}✓ Terragrunt initialized${NC}"
echo ""

# Step 2: Plan deployment
echo -e "${YELLOW}Step 2: Planning deployment...${NC}"
cd "$ENV_DIR"
terragrunt plan
cd ../..
echo ""

# Ask for confirmation
read -p "Do you want to proceed with deployment? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Step 3: Apply Terragrunt configuration
echo -e "${YELLOW}Step 3: Creating VMs with Terragrunt...${NC}"
cd "$ENV_DIR"
terragrunt apply -auto-approve
cd ../..
echo -e "${GREEN}✓ VMs created${NC}"
echo ""

# Step 4: Get outputs
echo -e "${YELLOW}Step 4: Getting cluster information...${NC}"
cd "$ENV_DIR"
CONTROL_PLANE_IP=$(terragrunt output -json control_plane_ips | jq -r '.[0]')
K3S_TOKEN=$(terragrunt output -raw k3s_token)
cd ../..

echo "Control Plane IP: $CONTROL_PLANE_IP"
echo "K3s Token: [hidden]"
export K3S_TOKEN
echo ""

# Step 5: Wait for VMs to boot
echo -e "${YELLOW}Step 5: Waiting for VMs to boot (60 seconds)...${NC}"
sleep 60
echo -e "${GREEN}✓ VMs should be ready${NC}"
echo ""

# Step 6: Test SSH connectivity
echo -e "${YELLOW}Step 6: Testing SSH connectivity...${NC}"
max_retries=5
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$CONTROL_PLANE_IP "echo 'SSH OK'" &> /dev/null; then
        echo -e "${GREEN}✓ SSH connection successful${NC}"
        break
    else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo -e "${YELLOW}⚠ SSH not ready, retrying ($retry_count/$max_retries)...${NC}"
            sleep 10
        else
            echo -e "${RED}✗ SSH connection failed after $max_retries attempts${NC}"
            exit 1
        fi
    fi
done
echo ""

# Step 7: Install system utilities
echo -e "${YELLOW}Step 7: Installing system utilities with Ansible...${NC}"
cd ansible
../.venv/bin/ansible-playbook -i inventory.yml system-utils-install.yml
cd ..
echo -e "${GREEN}✓ System utilities installed${NC}"
echo ""

# Step 8: Install K3s
echo -e "${YELLOW}Step 8: Installing K3s with Ansible...${NC}"
cd ansible
../.venv/bin/ansible-playbook -i inventory.yml k3s-install.yml
cd ..
echo -e "${GREEN}✓ K3s installed${NC}"
echo ""

# Step 9: Retrieve kubeconfig
echo -e "${YELLOW}Step 9: Retrieving kubeconfig...${NC}"
ssh ubuntu@$CONTROL_PLANE_IP "sudo cat /etc/rancher/k3s/k3s.yaml" | \
    sed "s/127.0.0.1/$CONTROL_PLANE_IP/g" > kubeconfig
chmod 600 kubeconfig
echo -e "${GREEN}✓ Kubeconfig saved to ./kubeconfig${NC}"
echo ""

# Step 10: Verify cluster
echo -e "${YELLOW}Step 10: Verifying cluster...${NC}"
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
echo ""
kubectl get pods -A
echo -e "${GREEN}✓ Cluster is ready!${NC}"
echo ""

# Optional: Install ArgoCD
read -p "Do you want to install ArgoCD? (yes/no): " install_argocd
if [ "$install_argocd" = "yes" ]; then
    echo -e "${YELLOW}Installing ArgoCD...${NC}"
    cd ansible
    ../.venv/bin/ansible-playbook -i inventory.yml argocd-install.yml
    cd ..
    echo -e "${GREEN}✓ ArgoCD installed${NC}"
    echo ""
    echo "Access ArgoCD:"
    echo "  kubectl port-forward svc/argocd-server -n argocd 8080:80"
    echo "  Username: admin"
    echo "  Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    echo ""
fi

# Deactivate virtual environment
deactivate 2>/dev/null || true

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Environment: $ENV"
echo "Control Plane IP: $CONTROL_PLANE_IP"
echo "Kubeconfig: $(pwd)/kubeconfig"
echo ""
echo "Next steps:"
echo "  export KUBECONFIG=$(pwd)/kubeconfig"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo ""
echo "SSH to control plane:"
echo "  ssh ubuntu@$CONTROL_PLANE_IP"
echo ""
