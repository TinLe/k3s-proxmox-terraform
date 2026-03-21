# K3s on Proxmox VE

> **Automated Kubernetes Cluster Deployment using Terragrunt, OpenTofu, and Ansible**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-1.8+-844fba)](https://opentofu.org/)
[![Terragrunt](https://img.shields.io/badge/Terragrunt-0.68+-5c6ac4)](https://terragrunt.gruntwork.io/)
[![K3s](https://img.shields.io/badge/K3s-v1.34.1-326ce5)](https://k3s.io/)

Deploy production-ready Kubernetes clusters on Proxmox VE with a single command. This project provides Infrastructure as Code (IaC) automation for K3s cluster provisioning using modern, open-source tools.

## ✨ Features

- 🚀 **One-Command Deployment** - Full cluster in <15 minutes
- 🔄 **Multi-Environment** - Separate dev/prod configurations
- 📦 **Modular Architecture** - Reusable Terragrunt modules
- 🔒 **Secure by Default** - SSH keys, API tokens, encrypted secrets
- 📊 **High Availability** - 3-node control plane for production
- 🎯 **GitOps Ready** - Optional ArgoCD integration
- ⚡ **Fast Package Management** - uv for Python dependencies
- 📚 **Comprehensive Docs** - Architecture diagrams and guides

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Machine                       │
│  ┌──────────┐  ┌──────────┐  ┌─────────┐  ┌──────────┐   │
│  │Terragrunt│→ │ OpenTofu │→ │ Ansible │→ │   K3s    │   │
│  └──────────┘  └──────────┘  └─────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Proxmox VE Host                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Dev: 1 CP + 3 Workers (5 vCPU, 10GB RAM)             │ │
│  │  Prod: 3 CP + 5 Workers (22 vCPU, 44GB RAM) - HA      │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**[View Detailed Architecture →](docs/architecture/README.md)**

## 🚀 Quick Start

### Prerequisites

- **Proxmox VE** 7.0+ with Ubuntu 24.04 cloud template
- **Development Machine** with Linux, macOS, or WSL2
- **SSH Key** for VM access
- **API Token** for Proxmox authentication

### Installation

```bash
# 1. Clone repository
git clone <repository-url>
cd k3s-proxmox-terragrunt

# 2. Run setup (installs tools)
./setup-terragrunt.sh

# 3. Configure environment
cp .envrc.example .envrc
nano .envrc  # Add your credentials
source .envrc

# 4. Deploy cluster
./deploy.sh dev

# 5. Access cluster
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

**[Detailed Setup Guide →](docs/README.md)**

## 📊 Environment Comparison

| Aspect | Development | Production |
|--------|-------------|------------|
| **Control Planes** | 1 node | 3 nodes (HA) |
| **Workers** | 3 nodes | 5 nodes |
| **vCPU** | 5 total | 22 total |
| **RAM** | 10GB total | 44GB total |
| **Storage** | 45GB total | 190GB total |
| **VM IDs** | 500-503 | 600-607 |
| **IP Range** | .180-.187 | .190-.199 |
| **Use Case** | Development/Testing | Production Workloads |

## 🛠️ Technology Stack

### Infrastructure Layer
- **[OpenTofu](https://opentofu.org/)** - Open-source IaC engine
- **[Terragrunt](https://terragrunt.gruntwork.io/)** - DRY configuration wrapper
- **[Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox)** - VM automation

### Configuration Layer
- **[Ansible](https://www.ansible.com/)** - Configuration management
- **[uv](https://github.com/astral-sh/uv)** - Fast Python package manager
- **Python 3.12+** - Ansible runtime

### Orchestration Layer
- **[K3s](https://k3s.io/)** - Lightweight Kubernetes
- **[Traefik](https://traefik.io/)** - Ingress controller (built-in)
- **[ArgoCD](https://argo-cd.readthedocs.io/)** - GitOps (optional)

## 📚 Documentation

### Getting Started
- **[Architecture Overview](docs/architecture/README.md)** - System design with diagrams
- **[Deployment Flow](docs/architecture/deployment-flow.md)** - Deployment process
- **[Documentation Index](docs/README.md)** - All documentation

### Technical Guides
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Operations and deployment procedures

## 🎯 Common Tasks

### Deploy Cluster
```bash
# Development environment
make apply ENV=dev

# Production environment
make apply ENV=prod
```

### Manage Infrastructure
```bash
make plan ENV=dev      # Preview changes
make apply ENV=dev     # Apply changes
make destroy ENV=dev   # Destroy cluster
make outputs ENV=dev   # Show outputs
make info ENV=dev      # Cluster information
```

### Access Cluster
```bash
# Set kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# View nodes
kubectl get nodes -o wide

# View all pods
kubectl get pods -A

# SSH to control plane
ssh ubuntu@192.168.1.180  # dev
ssh ubuntu@192.168.1.190  # prod
```

## 🔧 Configuration

### Environment Variables

Create `.envrc` from template:

```bash
# Proxmox Configuration
export PROXMOX_API_URL="https://192.168.1.200:8006/api2/json"
export PROXMOX_API_TOKEN_ID="root@pam!terraform"
export PROXMOX_API_TOKEN_SECRET="your-secret-here"

# SSH Configuration
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"

# Environment Selection
export TG_ENV="dev"  # or "prod"
```

### Customize Resources

Edit `environments/{env}/terragrunt.hcl`:

```hcl
inputs = {
  # Scale workers
  worker_count = 5
  
  # Increase resources
  worker_cpu = 2
  worker_memory = 4096
  
  # Change K3s version
  k3s_version = "v1.34.1+k3s1"
}
```

## 🎨 Project Structure

```
k3s-proxmox-terragrunt/
├── .ai-rules/              # AI assistant context
├── ansible/                # Configuration management
├── docs/                   # Documentation
│   └── architecture/       # Architecture diagrams
├── environments/           # Environment configs
│   ├── dev/               # Development
│   └── prod/              # Production
├── modules/               # Terragrunt modules
│   └── k3s-cluster/       # K3s cluster module
├── deploy.sh              # Deployment script
├── setup-terragrunt.sh    # Setup script
├── Makefile               # Build automation
└── terragrunt.hcl         # Root configuration
```

## 🔍 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Tools not found | Run `./setup-terragrunt.sh` |
| Environment variables not set | Run `source .envrc` |
| SSH connection failed | Wait longer for VMs to boot |
| Terragrunt cache issues | Run `make clean` |

**[Full Troubleshooting Guide →](docs/architecture/README.md)**

## 🚦 CI/CD Integration

GitHub Actions workflows included:

- **Validation** - Terragrunt/Ansible syntax checking
- **Security** - Dependency scanning
- **Release** - Automated versioning

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

Built with:
- [OpenTofu](https://opentofu.org/) - Open-source IaC
- [Terragrunt](https://terragrunt.gruntwork.io/) - DRY configuration
- [K3s](https://k3s.io/) - Lightweight Kubernetes
- [Ansible](https://www.ansible.com/) - Configuration management
- [Proxmox VE](https://www.proxmox.com/) - Virtualization platform

## 📞 Support

- **Documentation**: [docs/README.md](docs/README.md)
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions

## 🗺️ Roadmap

- [x] Terragrunt + OpenTofu migration
- [x] Multi-environment support
- [x] uv integration
- [x] Comprehensive documentation
- [x] Architecture diagrams
- [ ] Remote state backend
- [ ] Monitoring stack integration
- [ ] Backup automation
- [ ] Multi-cluster management

---

**[Get Started →](docs/README.md)** | **[View Architecture →](docs/architecture/README.md)** | **[Read Docs →](docs/README.md)**

## Architecture (Customizable)

- **Control Plane**: 1 node (2 vCPU, 4GB RAM, 15GB disk)
- **Workers**: 3 nodes (1 vCPU, 2GB RAM, 10GB disk each) - configurable
- **Total Resources**: 5 vCPU, 10GB RAM (configurable)
- **Network**: 192.168.1.180-187
- **Storage**: ZFS (local-zfs)
- **K3s Version**: v1.34.1+k3s1
- **Provider**: telmate/proxmox v3.0.2-rc05
- **QEMU Guest Agent**: Pre-installed and enabled on all nodes
- **Micro Editor**: Modern terminal text editor pre-installed

## Prerequisites

### On WSL/Linux:
```bash
# Terraform
terraform version  # Should be >= 1.0

# Ansible
ansible --version  # Will be installed by deploy script if missing

# SSH key
ls ~/.ssh/id_ed25519.pub  # Should exist

# jq (for parsing JSON)
sudo apt install jq
```

### On Proxmox:
- Ubuntu 24.04 cloud template (name: `ubuntu-24.04-cloud-tpl`)
- API token created: `root@pam!terraform`
- Available resources: 5+ vCPU, 10+ GB RAM
- ZFS storage pool: `local-zfs`
- Network bridge: `vmbr0`

## Quick Start

### 1. Clone and Setup

```bash
cd ~/k3s-proxmox-terraform
```

### 2. Configure Terraform Variables

```bash
# Copy example file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit with your values (IMPORTANT!)
nano terraform/terraform.tfvars
```

**Required changes in `terraform/terraform.tfvars`:**
```hcl
proxmox_api_token_secret = "YOUR_ACTUAL_TOKEN_SECRET_HERE"
```

### 3. Deploy the Cluster

```bash
# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

The script will:
1. Initialize Terraform
2. Create VMs on Proxmox
3. Wait for VMs to boot
4. Install system utilities using Ansible
5. Install K3s using Ansible
6. Optional: Install ArgoCD for GitOps workflows
7. Save kubeconfig locally

### 4. Access Your Cluster

```bash
# Set kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# Verify cluster
kubectl get nodes
kubectl get pods -A

# SSH to control plane
ssh ubuntu@192.168.1.180
```

### 5. Optional: Access ArgoCD (if installed)

If you chose to install ArgoCD during deployment:

```bash
# Port-forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Access in browser: http://localhost:8080
# Username: admin
# Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
```

## Manual Deployment (Step by Step)

If you prefer to run each step manually:

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Plan Deployment
```bash
terraform plan
```

### Step 3: Apply Configuration
```bash
terraform apply
```

### Step 4: Get K3s Token
```bash
export K3S_TOKEN=$(terraform output -raw k3s_token)
echo $K3S_TOKEN
```

### Step 5: Wait for VMs
```bash
# Wait 60 seconds for VMs to boot
sleep 60

# Test SSH
ssh ubuntu@192.168.1.180 "echo 'SSH OK'"
```

### Step 6: Install System Utilities
```bash
cd ansible
ansible-playbook -i inventory.yml system-utils-install.yml
cd ..
```

### Step 7: Install K3s
```bash
cd ansible
ansible-playbook -i inventory.yml k3s-install.yml
cd ..
```

### Step 8: Optional: Install ArgoCD
```bash
cd ansible
ansible-playbook -i inventory.yml argocd-install.yml
cd ..
```

### Step 9: Use Your Cluster
```bash
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

## Project Structure

```
k3s-proxmox-terraform/
├── terraform/
│   ├── main.tf                  # Main Terraform configuration
│   ├── variables.tf             # Variable definitions
│   ├── outputs.tf               # Output definitions
│   ├── terraform.tfvars.example # Example variables file
│   └── terraform.tfvars         # Your actual variables (gitignored)
├── ansible/
│   ├── inventory.yml            # Ansible inventory
│   ├── k3s-install.yml          # K3s installation playbook
│   ├── system-utils-install.yml # System utilities installation playbook
│   └── argocd-install.yml       # ArgoCD installation playbook
├── .github/workflows/           # GitHub Actions workflows
│   ├── validate.yml             # Code validation workflow
│   ├── release.yml              # Release automation workflow
│   └── security.yml             # Security scanning workflow
├── deploy.sh                    # Automated deployment script
├── setup-terragrunt.sh          # Setup script
├── .yamllint.yml                # YAML linting configuration
└── README.md                    # This file
```

## GitHub Actions & CI/CD

This project uses GitHub Actions for automated testing, security scanning, and release management.

### Workflow Status

[![Validate Code](https://github.com/your-username/k3s-proxmox-terraform/actions/workflows/validate.yml/badge.svg)](https://github.com/your-username/k3s-proxmox-terraform/actions/workflows/validate.yml)
[![Security Scan](https://github.com/your-username/k3s-proxmox-terraform/actions/workflows/security.yml/badge.svg)](https://github.com/your-username/k3s-proxmox-terraform/actions/workflows/security.yml)

### Development Workflow

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/new-feature
   ```

2. **Make your changes and commit:**
   ```bash
   git add .
   git commit -m "Add new feature"
   ```

3. **Push and create a Pull Request:**
   ```bash
   git push origin feature/new-feature
   ```

4. **Automatic validation runs:**
   - Terraform format and validation
   - Ansible syntax and linting
   - YAML validation
   - Security scanning

5. **After review, merge to main**

### Release Process

To create a new release:

1. **Update version and commit:**
   ```bash
   git add .
   git commit -m "Release v1.2.3"
   ```

2. **Create and push a tag:**
   ```bash
   git tag v1.2.3
   git push --tags
   ```

3. **GitHub Actions automatically:**
   - Creates a release with versioned archive
   - Generates SHA256 and MD5 checksums
   - Publishes release notes
   - Makes the release immutable

### Repository Settings

For optimal security and workflow, configure these repository settings:

1. **Enable release immutability:**
   - Settings → Code and automation → Releases
   - Check "Enable release immutability"

2. **Protect the main branch:**
   - Settings → Branches → Branch protection rules
   - Require status checks to pass
   - Require PR reviews before merging

### Available Workflows

- **Validate Code**: Runs on every PR and push to main
- **Security Scan**: Runs weekly and on-demand
- **Release Automation**: Runs when tags are created

## Customization

### Change Cluster Size

Edit `terraform.tfvars`:

```hcl
# Add more workers
worker_count = 5

# More resources per worker
worker_cpu = 2
worker_memory = 4096
worker_disk_size = "20G"

# High availability control plane
control_plane_count = 3
control_plane_cpu = 4
control_plane_memory = 8192
control_plane_disk_size = "30G"
```

**Important:** When changing `worker_count`, you must also update the Ansible inventory to match:

```bash
# Edit ansible/inventory.yml
nano ansible/inventory.yml
```

Update the workers section to match your new worker count. For example, for 5 workers:
```yaml
workers:
  hosts:
    k3s-worker-1:
      ansible_host: 192.168.1.185
    k3s-worker-2:
      ansible_host: 192.168.1.186
    k3s-worker-3:
      ansible_host: 192.168.1.187
    k3s-worker-4:
      ansible_host: 192.168.1.188
    k3s-worker-5:
      ansible_host: 192.168.1.189
```

### Change IP Addresses

Edit `terraform/terraform.tfvars`:

```hcl
control_plane_ip_start = "192.168.1.190"
worker_ip_start = "192.168.1.195"
```

### Change K3s Version

Edit `terraform/terraform.tfvars`:

```hcl
k3s_version = "v1.34.1+k3s1"  # Current default, change to any valid K3s version
```

## Useful Commands

### Terraform

```bash
# Show current state
terraform show

# List resources
terraform state list

# Destroy everything
terraform destroy

# Show outputs
terraform output

# Get specific output
terraform output -raw k3s_token
terraform output -json control_plane_ips
```

### Kubectl

```bash
# Set context
export KUBECONFIG=$(pwd)/kubeconfig

# Get cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A

# Deploy test application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc
```

### Ansible

```bash
# Test connectivity
ansible -i ansible/inventory.yml all -m ping

# Run specific playbook
ansible-playbook -i ansible/inventory.yml ansible/k3s-install.yml
ansible-playbook -i ansible/inventory.yml ansible/system-utils-install.yml
ansible-playbook -i ansible/inventory.yml ansible/argocd-install.yml

# Check K3s status
ansible -i ansible/inventory.yml control_plane -a "kubectl get nodes" -b
```

## ArgoCD Installation

### What is ArgoCD?
ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It automates the deployment of applications to your Kubernetes cluster by syncing with Git repositories.

### Features
- **GitOps Workflow**: Automatically syncs applications from Git repositories
- **Web UI**: Visual interface for managing applications
- **Declarative**: Define your desired state in Git
- **Multi-cluster**: Can manage multiple Kubernetes clusters
- **Rollback**: Easy rollback to previous versions

### Installation Options
1. **During deployment**: Choose "yes" when prompted during `./deploy.sh`
2. **Manual installation**: Run `ansible-playbook -i ansible/inventory.yml ansible/argocd-install.yml`

### Accessing ArgoCD
```bash
# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Troubleshooting

### Network Device Configuration

If worker nodes are not getting IP addresses, ensure all VMs use network device ID 0:

```bash
# Check network configuration in main.tf
grep -A 3 "network {" main.tf
```

All VMs should have `network { id = 0 }` to ensure CloudInit properly configures network interfaces.

### VMs Not Booting

```bash
# Check VM status in Proxmox
ssh root@192.168.1.200 "qm list"

# Check specific VM
ssh root@192.168.1.200 "qm status <VMID>"

# View console
# Access Proxmox web UI: https://192.168.1.200:8006
```

### SSH Connection Issues

```bash
# Test SSH manually
ssh -v ubuntu@192.168.1.180

# Check cloud-init logs on VM
ssh ubuntu@192.168.1.180 "sudo cloud-init status --long"

# Verify SSH key
cat ~/.ssh/id_ed25519.pub
```

### K3s Installation Fails

```bash
# Check K3s service status
ssh ubuntu@192.168.1.180 "sudo systemctl status k3s"

# View K3s logs
ssh ubuntu@192.168.1.180 "sudo journalctl -u k3s -f"

# Reinstall K3s manually
ssh ubuntu@192.168.1.180
curl -sfL https://get.k3s.io | sh -
```

### Terraform State Issues

```bash
# Refresh state
terraform refresh

# Import existing VM
terraform import proxmox_vm_qemu.k3s_control_plane[0] proxmox/<VMID>

# Remove from state (doesn't delete VM)
terraform state rm proxmox_vm_qemu.k3s_worker[0]
```

### Provider Compatibility

This project uses telmate/proxmox provider v3.0.2-rc05 which has breaking changes from v2.x:

- Use `cpu` block instead of `cpu` argument
- Network blocks require explicit `id` field
- CloudInit requires explicit `ide2 cloudinit` drive
- Serial port requires explicit configuration

## Destroying the Cluster

### Option 1: Terraform Destroy (Recommended)

```bash
# Destroy all resources
terraform destroy

# Auto-approve (skip confirmation)
terraform destroy -auto-approve
```

### Option 2: Manual Cleanup

```bash
# Stop and remove VMs
ssh root@192.168.1.200
qm stop <VMID>
qm destroy <VMID>
```

## Security Considerations

1. **Change default password**: The VMs use `ubuntu:ubuntu` by default
   ```bash
   ssh ubuntu@192.168.1.180 "sudo passwd ubuntu"
   ```

2. **Disable password auth**: Use SSH keys only
   ```bash
   ssh ubuntu@192.168.1.180 "sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo systemctl reload sshd"
   ```

3. **Firewall**: Configure UFW on nodes
   ```bash
   ssh ubuntu@192.168.1.180 "sudo ufw allow 22/tcp && sudo ufw allow 6443/tcp && sudo ufw --force enable"
   ```

4. **API Token**: Keep your Proxmox API token secret secure
   - Never commit `terraform.tfvars` to git
   - Use `.gitignore` to exclude sensitive files

## Next Steps

After deployment, you can:

1. **Access ArgoCD** (if installed): Set up GitOps workflows for your applications
2. **Install a CNI plugin** (if not using default Flannel)
3. **Deploy cert-manager** for TLS certificates
4. **Install Helm** for package management
5. **Traefik Ingress Controller** (enabled by default)
6. **Configure persistent storage** (Longhorn, NFS)
7. **Setup monitoring** (Prometheus, Grafana)
8. **Deploy applications** using ArgoCD or kubectl

### Using ArgoCD for Application Deployment
Once ArgoCD is installed, you can:
- Create Application manifests in Git
- Connect ArgoCD to your Git repositories
- Automatically deploy and sync applications
- Monitor application health through the UI
- Rollback to previous versions if needed

### Traefik Ingress Controller
Traefik is now enabled by default in K3s and provides:
- Built-in ingress controller for routing HTTP/HTTPS traffic
- Automatic SSL certificate management
- Load balancing capabilities
- Service discovery

## Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)

## License

MIT

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review Terraform/Ansible logs
3. Check Proxmox VE logs
4. Consult K3s documentation