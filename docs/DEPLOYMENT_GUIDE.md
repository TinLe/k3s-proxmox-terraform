# K3s on Proxmox - Deployment Guide

## Overview

This guide covers deploying a K3s Kubernetes cluster on Proxmox VE using Terragrunt, OpenTofu, and Ansible.

---

## Prerequisites

- Proxmox VE 7.0+ with Ubuntu 24.04 cloud template (`ubuntu-24.04-cloud-tpl`)
- SSH key at `~/.ssh/id_ed25519`
- Proxmox API token (`root@pam!terraform`)
- Tools: OpenTofu, Terragrunt, uv, jq

Run the setup script to install missing tools:

```bash
./setup-terragrunt.sh
```

---

## Quick Deployment

```bash
# 1. Configure environment
cp .envrc.example .envrc
nano .envrc        # Add your Proxmox credentials
source .envrc

# 2. Deploy (dev environment)
./deploy.sh dev

# 3. Access cluster
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

---

## Manual Step-by-Step

### 1. Initialize Terragrunt

```bash
cd environments/dev
terragrunt init
```

### 2. Plan

```bash
terragrunt plan
```

### 3. Apply

```bash
terragrunt apply
```

### 4. Get outputs

```bash
terragrunt output -json control_plane_ips
terragrunt output -raw k3s_token
cd ../..
```

### 5. Setup Python venv and install Ansible

```bash
make venv
```

### 6. Run Ansible playbooks

```bash
cd ansible
../.venv/bin/ansible-playbook -i inventory.yml system-utils-install.yml
../.venv/bin/ansible-playbook -i inventory.yml k3s-install.yml
cd ..
```

### 7. Optional: Install ArgoCD

```bash
cd ansible
../.venv/bin/ansible-playbook -i inventory.yml argocd-install.yml
cd ..
```

### 8. Retrieve kubeconfig

```bash
CONTROL_PLANE_IP=192.168.1.180  # dev default
ssh ubuntu@$CONTROL_PLANE_IP "sudo cat /etc/rancher/k3s/k3s.yaml" | \
  sed "s/127.0.0.1/$CONTROL_PLANE_IP/g" > kubeconfig
chmod 600 kubeconfig
```

---

## Makefile Shortcuts

```bash
make setup          # Run setup-terragrunt.sh
make init ENV=dev   # Initialize Terragrunt
make plan ENV=dev   # Preview changes
make apply ENV=dev  # Apply infrastructure
make deploy ENV=dev # Full deploy (Terragrunt + Ansible)
make destroy ENV=dev
make clean          # Remove .terragrunt-cache
make outputs ENV=dev
make info ENV=dev
```

---

## Customization

### Change worker count

Edit `environments/{env}/terragrunt.hcl`:

```hcl
inputs = {
  worker_count  = 5
  worker_cpu    = 2
  worker_memory = 4096
}
```

Also update `ansible/inventory.yml` to match.

### Change IP range

```hcl
inputs = {
  control_plane_ip_start = "192.168.1.190"
  worker_ip_start        = "192.168.1.195"
}
```

### Change K3s version

```hcl
inputs = {
  k3s_version = "v1.34.1+k3s1"
}
```

---

## Environments

| | Dev | Prod |
|---|---|---|
| Control Planes | 1 | 3 (HA) |
| Workers | 3 | 5 |
| VM IDs | 500-503 | 600-607 |
| IP Range | .180-.187 | .190-.199 |

---

## Troubleshooting

### VMs not booting
```bash
ssh root@192.168.1.200 "qm list"
```
Check Proxmox web UI console for cloud-init errors.

### SSH connection fails
```bash
ssh -v ubuntu@192.168.1.180
```
Wait 2-3 minutes after VM creation for cloud-init to complete.

### Terragrunt cache issues
```bash
make clean
```

### K3s installation fails
```bash
ssh ubuntu@192.168.1.180 "sudo journalctl -u k3s -n 100"
```

### Worker nodes not joining
```bash
ssh ubuntu@192.168.1.185 "sudo journalctl -u k3s-agent -n 100"
ssh ubuntu@192.168.1.185 "curl -k https://192.168.1.180:6443"
```

---

## Destroy

```bash
make destroy ENV=dev

# Or manually
cd environments/dev
terragrunt destroy
```

---

## Deployment Checklist

- [ ] `.envrc` configured with Proxmox credentials
- [ ] SSH key exists at `~/.ssh/id_ed25519`
- [ ] Template `ubuntu-24.04-cloud-tpl` exists on Proxmox
- [ ] IP range available (dev: .180-.187, prod: .190-.199)
- [ ] VM ID range available (dev: 500-503, prod: 600-607)
- [ ] `./deploy.sh dev` completed successfully
- [ ] `kubectl get nodes` shows all nodes Ready
