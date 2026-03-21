# Architecture Overview

## System Architecture

This project implements an automated K3s Kubernetes cluster deployment on Proxmox VE using Infrastructure as Code (IaC) principles.

### High-Level Architecture

```mermaid
graph TB
    subgraph "Development Machine"
        DEV[Developer]
        TG[Terragrunt]
        TOFU[OpenTofu]
        ANS[Ansible]
        UV[uv/Python]
    end
    
    subgraph "Proxmox VE Host"
        PVE[Proxmox API]
        
        subgraph "Dev Environment"
            DEV_CP[Control Plane<br/>192.168.1.180]
            DEV_W1[Worker 1<br/>192.168.1.185]
            DEV_W2[Worker 2<br/>192.168.1.186]
            DEV_W3[Worker 3<br/>192.168.1.187]
        end
        
        subgraph "Prod Environment"
            PROD_CP1[Control Plane 1<br/>192.168.1.190]
            PROD_CP2[Control Plane 2<br/>192.168.1.191]
            PROD_CP3[Control Plane 3<br/>192.168.1.192]
            PROD_W1[Worker 1<br/>192.168.1.195]
            PROD_W2[Worker 2<br/>192.168.1.196]
            PROD_W3[Worker 3<br/>192.168.1.197]
            PROD_W4[Worker 4<br/>192.168.1.198]
            PROD_W5[Worker 5<br/>192.168.1.199]
        end
        
        TEMPLATE[Ubuntu 24.04<br/>Cloud Template]
    end
    
    DEV -->|1. Configure| TG
    TG -->|2. Generate Config| TOFU
    TOFU -->|3. Create VMs| PVE
    PVE -->|4. Clone from| TEMPLATE
    ANS -->|5. Configure K3s| DEV_CP
    ANS -->|5. Configure K3s| DEV_W1
    ANS -->|5. Configure K3s| DEV_W2
    ANS -->|5. Configure K3s| DEV_W3
    UV -->|Manage| ANS
    
    style DEV fill:#e1f5ff
    style TG fill:#4fc3f7
    style TOFU fill:#29b6f6
    style ANS fill:#0288d1
    style PVE fill:#f57c00
    style TEMPLATE fill:#ff9800
```

### Technology Stack

```mermaid
graph LR
    subgraph "Infrastructure Layer"
        TOFU[OpenTofu<br/>IaC Engine]
        TG[Terragrunt<br/>DRY Wrapper]
        PROX[Proxmox Provider<br/>v3.0.2-rc05]
    end
    
    subgraph "Configuration Layer"
        ANS[Ansible<br/>Config Management]
        UV[uv<br/>Python Package Manager]
        PY[Python 3.12+]
    end
    
    subgraph "Orchestration Layer"
        K3S[K3s v1.34.1+k3s1<br/>Lightweight Kubernetes]
        TRAEFIK[Traefik<br/>Ingress Controller]
        ARGO[ArgoCD<br/>GitOps Optional]
    end
    
    TG --> TOFU
    TOFU --> PROX
    UV --> PY
    PY --> ANS
    ANS --> K3S
    K3S --> TRAEFIK
    K3S --> ARGO
    
    style TOFU fill:#844fba
    style TG fill:#5c6ac4
    style ANS fill:#ee0000
    style K3S fill:#326ce5
```

## Component Architecture

### Infrastructure Components

#### 1. Terragrunt Layer
- **Purpose**: DRY configuration management
- **Responsibilities**:
  - Environment-specific configuration
  - Remote state management
  - Provider generation
  - Module orchestration

#### 2. OpenTofu Layer
- **Purpose**: Infrastructure provisioning
- **Responsibilities**:
  - VM creation and management
  - Network configuration
  - Resource lifecycle management
  - State tracking

#### 3. Ansible Layer
- **Purpose**: Configuration management
- **Responsibilities**:
  - System package installation
  - K3s cluster setup
  - Service configuration
  - Application deployment (ArgoCD)

### Cluster Architecture

#### Development Environment
```mermaid
graph TB
    subgraph "Dev Cluster - 192.168.1.180-187"
        CP[Control Plane<br/>2 vCPU, 4GB RAM<br/>192.168.1.180]
        
        W1[Worker 1<br/>1 vCPU, 2GB RAM<br/>192.168.1.185]
        W2[Worker 2<br/>1 vCPU, 2GB RAM<br/>192.168.1.186]
        W3[Worker 3<br/>1 vCPU, 2GB RAM<br/>192.168.1.187]
        
        CP -->|K3s API| W1
        CP -->|K3s API| W2
        CP -->|K3s API| W3
    end
    
    style CP fill:#4caf50
    style W1 fill:#81c784
    style W2 fill:#81c784
    style W3 fill:#81c784
```

**Resources:**
- Total: 5 vCPU, 10GB RAM
- Storage: 45GB (15GB + 3×10GB)
- VM IDs: 500-503

#### Production Environment
```mermaid
graph TB
    subgraph "Prod Cluster - 192.168.1.190-199"
        subgraph "HA Control Plane"
            CP1[Control Plane 1<br/>4 vCPU, 8GB RAM<br/>192.168.1.190]
            CP2[Control Plane 2<br/>4 vCPU, 8GB RAM<br/>192.168.1.191]
            CP3[Control Plane 3<br/>4 vCPU, 8GB RAM<br/>192.168.1.192]
        end
        
        subgraph "Worker Pool"
            W1[Worker 1<br/>2 vCPU, 4GB RAM<br/>192.168.1.195]
            W2[Worker 2<br/>2 vCPU, 4GB RAM<br/>192.168.1.196]
            W3[Worker 3<br/>2 vCPU, 4GB RAM<br/>192.168.1.197]
            W4[Worker 4<br/>2 vCPU, 4GB RAM<br/>192.168.1.198]
            W5[Worker 5<br/>2 vCPU, 4GB RAM<br/>192.168.1.199]
        end
        
        CP1 <-->|etcd| CP2
        CP2 <-->|etcd| CP3
        CP3 <-->|etcd| CP1
        
        CP1 -->|K3s API| W1
        CP1 -->|K3s API| W2
        CP2 -->|K3s API| W3
        CP2 -->|K3s API| W4
        CP3 -->|K3s API| W5
    end
    
    style CP1 fill:#2e7d32
    style CP2 fill:#2e7d32
    style CP3 fill:#2e7d32
    style W1 fill:#66bb6a
    style W2 fill:#66bb6a
    style W3 fill:#66bb6a
    style W4 fill:#66bb6a
    style W5 fill:#66bb6a
```

**Resources:**
- Total: 22 vCPU, 44GB RAM
- Storage: 190GB (3×30GB + 5×20GB)
- VM IDs: 600-607
- High Availability: 3-node etcd cluster

## Network Architecture

```mermaid
graph TB
    subgraph "Network: 192.168.1.0/24"
        GW[Gateway<br/>192.168.1.1]
        DNS[DNS Server<br/>192.168.1.1]
        
        subgraph "Dev Range: .180-.187"
            DEV_CP[.180]
            DEV_W[.185-.187]
        end
        
        subgraph "Prod Range: .190-.199"
            PROD_CP[.190-.192]
            PROD_W[.195-.199]
        end
        
        GW --> DEV_CP
        GW --> DEV_W
        GW --> PROD_CP
        GW --> PROD_W
        
        DNS -.->|Resolution| DEV_CP
        DNS -.->|Resolution| PROD_CP
    end
    
    subgraph "Proxmox Network"
        BRIDGE[vmbr0 Bridge]
        BRIDGE --> GW
    end
    
    style GW fill:#ff6f00
    style DNS fill:#ff8f00
    style BRIDGE fill:#ffa726
```

### Network Configuration
- **Bridge**: vmbr0
- **Gateway**: 192.168.1.1
- **DNS**: 192.168.1.1
- **Search Domain**: local
- **Dev IP Range**: 192.168.1.180-187
- **Prod IP Range**: 192.168.1.190-199

## Storage Architecture

```mermaid
graph TB
    subgraph "Proxmox Storage"
        ZFS[ZFS Pool<br/>local-zfs]
        
        subgraph "VM Disks"
            DEV_DISKS[Dev VMs<br/>45GB Total]
            PROD_DISKS[Prod VMs<br/>190GB Total]
        end
        
        subgraph "Cloud-Init"
            CI[Cloud-Init Drives<br/>IDE2]
        end
        
        ZFS --> DEV_DISKS
        ZFS --> PROD_DISKS
        ZFS --> CI
    end
    
    subgraph "VM Storage Layout"
        SCSI0[SCSI0: Root Disk<br/>virtio-scsi-single]
        IDE2[IDE2: Cloud-Init<br/>Configuration]
    end
    
    style ZFS fill:#1976d2
    style DEV_DISKS fill:#42a5f5
    style PROD_DISKS fill:#42a5f5
    style CI fill:#64b5f6
```

### Storage Configuration
- **Pool**: local-zfs (ZFS)
- **Controller**: virtio-scsi-single
- **Boot Disk**: scsi0
- **Cloud-Init**: ide2
- **Dev Storage**: 45GB total
- **Prod Storage**: 190GB total

## Security Architecture

```mermaid
graph TB
    subgraph "Access Control"
        API[Proxmox API<br/>Token Auth]
        SSH[SSH Keys<br/>Ed25519]
        K3S_TOKEN[K3s Token<br/>32 chars]
    end
    
    subgraph "Network Security"
        FW[Firewall Rules]
        TLS[TLS/SSL<br/>K3s API]
    end
    
    subgraph "Secrets Management"
        ENV[Environment Variables<br/>.envrc]
        GITIGNORE[.gitignore<br/>Excluded Files]
    end
    
    API -->|Authenticate| FW
    SSH -->|Access| FW
    K3S_TOKEN -->|Cluster Auth| TLS
    ENV -.->|Not Committed| GITIGNORE
    
    style API fill:#d32f2f
    style SSH fill:#f44336
    style K3S_TOKEN fill:#e57373
    style ENV fill:#ffb74d
    style GITIGNORE fill:#ffa726
```

### Security Features
- **API Authentication**: Token-based (root@pam!terraform)
- **SSH Access**: Public key authentication only
- **K3s Security**: Auto-generated 32-character token
- **Secrets**: Environment variables (not committed)
- **TLS**: Enabled for K3s API (port 6443)
- **Cloud-Init**: Secure VM initialization

## Data Flow

### Deployment Flow
```mermaid
sequenceDiagram
    participant Dev as Developer
    participant TG as Terragrunt
    participant TF as OpenTofu
    participant PVE as Proxmox API
    participant VM as Virtual Machines
    participant ANS as Ansible
    participant K3S as K3s Cluster
    
    Dev->>TG: 1. Run deploy script
    TG->>TG: 2. Load environment config
    TG->>TF: 3. Generate provider config
    TF->>TF: 4. Plan infrastructure
    Dev->>TF: 5. Approve plan
    TF->>PVE: 6. Create VMs via API
    PVE->>VM: 7. Clone from template
    VM->>VM: 8. Cloud-init configuration
    VM->>VM: 9. Boot and network setup
    ANS->>VM: 10. Install system packages
    ANS->>VM: 11. Install K3s server
    ANS->>VM: 12. Install K3s agents
    ANS->>K3S: 13. Verify cluster
    K3S->>Dev: 14. Return kubeconfig
    Dev->>K3S: 15. Access cluster
```

### Configuration Flow
```mermaid
graph LR
    subgraph "Configuration Sources"
        ENVRC[.envrc<br/>Secrets]
        TG_ROOT[terragrunt.hcl<br/>Root Config]
        ENV_HCL[env.hcl<br/>Environment]
        TG_ENV[terragrunt.hcl<br/>Env Config]
    end
    
    subgraph "Generated Config"
        PROVIDER[provider.tf<br/>Generated]
        BACKEND[backend.tf<br/>Generated]
        VARS[variables<br/>Injected]
    end
    
    subgraph "Infrastructure"
        MODULE[k3s-cluster<br/>Module]
        RESOURCES[Proxmox VMs<br/>Resources]
    end
    
    ENVRC -->|Environment Vars| TG_ENV
    TG_ROOT -->|Common Config| TG_ENV
    ENV_HCL -->|Env Vars| TG_ENV
    TG_ENV -->|Generate| PROVIDER
    TG_ENV -->|Generate| BACKEND
    TG_ENV -->|Inject| VARS
    VARS -->|Configure| MODULE
    MODULE -->|Create| RESOURCES
    
    style ENVRC fill:#ffeb3b
    style TG_ROOT fill:#4caf50
    style MODULE fill:#2196f3
```

## Module Architecture

### Terragrunt Module Structure
```mermaid
graph TB
    subgraph "Root Configuration"
        ROOT[terragrunt.hcl<br/>Root Config]
        ENV_ROOT[env.hcl<br/>Default Env]
    end
    
    subgraph "Environment: Dev"
        DEV_TG[terragrunt.hcl<br/>Dev Config]
        DEV_ENV[env.hcl<br/>Dev Vars]
    end
    
    subgraph "Environment: Prod"
        PROD_TG[terragrunt.hcl<br/>Prod Config]
        PROD_ENV[env.hcl<br/>Prod Vars]
    end
    
    subgraph "Shared Module"
        MODULE[modules/k3s-cluster/<br/>Reusable Module]
        MAIN[main.tf]
        VARS[variables.tf]
        OUTPUTS[outputs.tf]
        VERSIONS[versions.tf]
    end
    
    ROOT -->|Include| DEV_TG
    ROOT -->|Include| PROD_TG
    DEV_ENV -->|Variables| DEV_TG
    PROD_ENV -->|Variables| PROD_TG
    DEV_TG -->|Source| MODULE
    PROD_TG -->|Source| MODULE
    MODULE --> MAIN
    MODULE --> VARS
    MODULE --> OUTPUTS
    MODULE --> VERSIONS
    
    style ROOT fill:#4caf50
    style MODULE fill:#2196f3
    style DEV_TG fill:#81c784
    style PROD_TG fill:#66bb6a
```

### Ansible Playbook Structure
```mermaid
graph TB
    subgraph "Ansible Playbooks"
        INV[inventory.yml<br/>Host Definitions]
        
        SYSTEM[system-utils-install.yml<br/>System Packages]
        K3S[k3s-install.yml<br/>K3s Setup]
        ARGO[argocd-install.yml<br/>ArgoCD Optional]
    end
    
    subgraph "Execution Order"
        E1[1. System Utils]
        E2[2. K3s Install]
        E3[3. ArgoCD Optional]
    end
    
    INV -->|Hosts| SYSTEM
    INV -->|Hosts| K3S
    INV -->|Hosts| ARGO
    
    SYSTEM --> E1
    K3S --> E2
    ARGO --> E3
    
    E1 --> E2
    E2 -.->|Optional| E3
    
    style INV fill:#ee0000
    style SYSTEM fill:#ff5252
    style K3S fill:#ff6e40
    style ARGO fill:#ff9e80
```

## Scalability Considerations

### Horizontal Scaling
- **Workers**: Easily add more worker nodes by increasing `worker_count`
- **Control Plane**: Scale to 3+ nodes for HA (prod environment)
- **Environments**: Add new environments (staging, qa) by copying config

### Vertical Scaling
- **CPU**: Adjust `control_plane_cpu` and `worker_cpu`
- **Memory**: Adjust `control_plane_memory` and `worker_memory`
- **Disk**: Adjust `control_plane_disk_size` and `worker_disk_size`

### Resource Planning

| Environment | vCPU | RAM | Storage | Nodes |
|-------------|------|-----|---------|-------|
| Dev | 5 | 10GB | 45GB | 4 |
| Prod | 22 | 44GB | 190GB | 8 |
| Staging | 11 | 22GB | 95GB | 6 |

## High Availability

### Production HA Setup
```mermaid
graph TB
    subgraph "HA Control Plane"
        CP1[Control Plane 1<br/>etcd member]
        CP2[Control Plane 2<br/>etcd member]
        CP3[Control Plane 3<br/>etcd member]
        
        CP1 <-->|Raft Consensus| CP2
        CP2 <-->|Raft Consensus| CP3
        CP3 <-->|Raft Consensus| CP1
    end
    
    subgraph "Load Distribution"
        LB[K3s API<br/>Load Balanced]
        LB -->|Round Robin| CP1
        LB -->|Round Robin| CP2
        LB -->|Round Robin| CP3
    end
    
    subgraph "Worker Nodes"
        W1[Worker 1]
        W2[Worker 2]
        W3[Worker 3]
        W4[Worker 4]
        W5[Worker 5]
    end
    
    LB --> W1
    LB --> W2
    LB --> W3
    LB --> W4
    LB --> W5
    
    style CP1 fill:#2e7d32
    style CP2 fill:#2e7d32
    style CP3 fill:#2e7d32
    style LB fill:#1976d2
```

### Failure Scenarios
- **Single Control Plane Failure**: Cluster continues (2/3 quorum)
- **Worker Node Failure**: Pods rescheduled to healthy nodes
- **Network Partition**: etcd maintains quorum with majority

## Performance Characteristics

### Resource Utilization
- **Dev Environment**: Suitable for development and testing
- **Prod Environment**: Suitable for production workloads
- **K3s Overhead**: ~500MB RAM per node
- **etcd**: ~100MB RAM per control plane node

### Network Performance
- **Internal**: 1Gbps (virtio network)
- **Latency**: <1ms between nodes (same host)
- **Bandwidth**: Limited by Proxmox host network

## Monitoring and Observability

### Built-in Monitoring
- **K3s Metrics**: Available via metrics-server
- **Proxmox Monitoring**: VM resource usage
- **Logs**: journalctl for K3s services

### Optional Monitoring Stack
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **Loki**: Log aggregation
- **AlertManager**: Alerting

## Backup and Recovery

### Backup Strategy
```mermaid
graph LR
    subgraph "Backup Sources"
        ETCD[etcd Snapshots]
        STATE[Terraform State]
        CONFIG[Configuration Files]
    end
    
    subgraph "Backup Storage"
        LOCAL[Local Backups]
        REMOTE[Remote Storage]
    end
    
    ETCD -->|Automated| LOCAL
    STATE -->|Version Control| REMOTE
    CONFIG -->|Git Repository| REMOTE
    LOCAL -.->|Optional| REMOTE
    
    style ETCD fill:#4caf50
    style STATE fill:#2196f3
    style CONFIG fill:#ff9800
```

### Recovery Procedures
1. **Infrastructure**: Re-run Terragrunt to recreate VMs
2. **Configuration**: Re-run Ansible playbooks
3. **Cluster State**: Restore from etcd snapshots
4. **Applications**: Redeploy via ArgoCD or kubectl

## References

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
