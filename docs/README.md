# K3s on Proxmox VE - Documentation

Welcome to the comprehensive documentation for the K3s on Proxmox VE project using Terragrunt and OpenTofu.

## 📚 Documentation Structure

### Quick Start Guides
- **[Architecture Overview](architecture/README.md)** - System architecture and diagrams
- **[Deployment Flow](architecture/deployment-flow.md)** - Detailed deployment process

### Operations
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Deployment procedures
- **[pve-info-checklist-example.md](pve-info-checklist-example.md)** - Proxmox setup checklist

## 🎯 Quick Navigation

### I want to...

#### Deploy a new cluster
→ [Architecture Overview](architecture/README.md) or [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

#### Understand the architecture
→ [Architecture Overview](architecture/README.md)

#### See deployment flow
→ [Deployment Flow](architecture/deployment-flow.md)

#### Troubleshoot issues
→ [Architecture Overview](architecture/README.md)

## 📖 Documentation by Role

### For Developers
1. [Architecture Overview](architecture/README.md) - Understand the system
2. [Deployment Flow](architecture/deployment-flow.md) - Deployment process
3. [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Daily operations

### For DevOps Engineers
1. [Architecture Overview](architecture/README.md) - System design
2. [Deployment Flow](architecture/deployment-flow.md) - Deployment process
3. [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Operations guide

### For System Administrators
1. [pve-info-checklist-example.md](pve-info-checklist-example.md) - Proxmox setup
2. [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deployment procedures

### For Decision Makers
1. [Architecture Overview](architecture/README.md) - System overview

## 🏗️ Project Overview

### What is this project?

This project provides an automated way to deploy K3s (lightweight Kubernetes) clusters on Proxmox VE using modern Infrastructure as Code (IaC) tools:

- **OpenTofu**: Open-source Terraform alternative for infrastructure provisioning
- **Terragrunt**: DRY wrapper for managing multiple environments
- **Ansible**: Configuration management for K3s installation
- **uv**: Fast Python package manager for Ansible dependencies

### Key Features

- ✅ **Multi-environment support** - Separate dev/prod configurations
- ✅ **DRY configuration** - No code duplication
- ✅ **Modular architecture** - Reusable components
- ✅ **Automated deployment** - One-command cluster creation
- ✅ **High availability** - 3-node control plane for production
- ✅ **GitOps ready** - Optional ArgoCD integration
- ✅ **Fast package management** - uv for Python dependencies

### Architecture at a Glance

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
│  │  Dev Environment (4 VMs)                               │ │
│  │  • 1 Control Plane (2 vCPU, 4GB RAM)                  │ │
│  │  • 3 Workers (1 vCPU, 2GB RAM each)                   │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Prod Environment (8 VMs)                              │ │
│  │  • 3 Control Planes (4 vCPU, 8GB RAM each) - HA       │ │
│  │  • 5 Workers (2 vCPU, 4GB RAM each)                   │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

```bash
# 1. Setup tools and environment
./setup-terragrunt.sh

# 2. Configure credentials
cp .envrc.example .envrc
nano .envrc
source .envrc

# 3. Deploy cluster
./deploy.sh dev

# 4. Access cluster
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

For detailed instructions, see [docs/README.md](README.md).

## 📊 Environment Comparison

| Aspect | Dev | Prod |
|--------|-----|------|
| **Control Planes** | 1 | 3 (HA) |
| **Workers** | 3 | 5 |
| **Total vCPU** | 5 | 22 |
| **Total RAM** | 10GB | 44GB |
| **Total Storage** | 45GB | 190GB |
| **VM IDs** | 500+ | 600+ |
| **IP Range** | .180-.187 | .190-.199 |
| **Use Case** | Development/Testing | Production Workloads |

## 🔧 Common Tasks

### Deploy Cluster
```bash
# Dev environment
make apply ENV=dev

# Prod environment
make apply ENV=prod
```

### Manage Infrastructure
```bash
# Plan changes
make plan ENV=dev

# Show outputs
make outputs ENV=dev

# Destroy cluster
make destroy ENV=dev
```

### Access Cluster
```bash
# Set kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# Get nodes
kubectl get nodes

# Get pods
kubectl get pods -A
```

### SSH to Nodes
```bash
# Dev control plane
ssh ubuntu@192.168.1.180

# Prod control plane
ssh ubuntu@192.168.1.190
```

## 🛠️ Technology Stack

### Infrastructure Layer
- **OpenTofu** v1.8+ - Infrastructure as Code
- **Terragrunt** v0.68+ - Configuration wrapper
- **Proxmox Provider** v3.0.2-rc05 - Proxmox integration

### Configuration Layer
- **Ansible** v9.0+ - Configuration management
- **uv** - Python package manager
- **Python** 3.12+ - Ansible runtime

### Orchestration Layer
- **K3s** v1.34.1+k3s1 - Lightweight Kubernetes
- **Traefik** - Ingress controller (built-in)
- **ArgoCD** - GitOps (optional)

## 📝 Documentation Standards

### Diagram Types Used

1. **Architecture Diagrams** - System structure and components
2. **Sequence Diagrams** - Process flows and interactions
3. **Flow Diagrams** - Decision trees and workflows
4. **Gantt Charts** - Timeline and scheduling

### Mermaid Syntax

All diagrams use Mermaid syntax for easy rendering in:
- GitHub
- GitLab
- VS Code (with Mermaid extension)
- Documentation sites

## 🔍 Troubleshooting

### Common Issues

1. **Tools not found** → Run `./setup-terragrunt.sh`
2. **Environment variables not set** → Run `source .envrc`
3. **SSH connection failed** → Wait longer for VMs to boot
4. **Terragrunt cache issues** → Run `make clean`

For detailed troubleshooting, see [docs/architecture/README.md](architecture/README.md).

## 📚 Additional Resources

### External Documentation
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Ansible Documentation](https://docs.ansible.com/)

### Community Resources
- [K3s GitHub](https://github.com/k3s-io/k3s)
- [OpenTofu GitHub](https://github.com/opentofu/opentofu)
- [Terragrunt GitHub](https://github.com/gruntwork-io/terragrunt)

## 🤝 Contributing

When contributing documentation:

1. Follow existing structure and style
2. Use Mermaid for diagrams
3. Keep explanations clear and concise
4. Include code examples where appropriate
5. Update this index when adding new docs

## 📄 License

MIT License - See project root for details

## 🆘 Getting Help

1. Check the [troubleshooting section](architecture/README.md)
2. Review [architecture documentation](architecture/README.md)
3. Consult [deployment flow](architecture/deployment-flow.md)
4. Check external documentation links above

---

**Last Updated**: 2024
**Project Version**: 2.0 (Terragrunt + OpenTofu)
