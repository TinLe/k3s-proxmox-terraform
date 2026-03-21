# Deployment Flow Documentation

## Overview

This document details the complete deployment flow from initial setup to a running K3s cluster.

## Deployment Phases

```mermaid
graph TB
    START([Start Deployment])
    
    subgraph "Phase 1: Prerequisites"
        P1[Check Tools]
        P2[Setup Environment]
        P3[Create Virtual Env]
    end
    
    subgraph "Phase 2: Infrastructure"
        I1[Initialize Terragrunt]
        I2[Plan Infrastructure]
        I3[Create VMs]
        I4[Wait for Boot]
    end
    
    subgraph "Phase 3: Configuration"
        C1[Install System Utils]
        C2[Install K3s Server]
        C3[Install K3s Agents]
        C4[Verify Cluster]
    end
    
    subgraph "Phase 4: Finalization"
        F1[Retrieve Kubeconfig]
        F2[Optional: ArgoCD]
        F3[Cluster Ready]
    end
    
    START --> P1
    P1 --> P2
    P2 --> P3
    P3 --> I1
    I1 --> I2
    I2 --> I3
    I3 --> I4
    I4 --> C1
    C1 --> C2
    C2 --> C3
    C3 --> C4
    C4 --> F1
    F1 --> F2
    F2 --> F3
    F3 --> END([Cluster Ready])
    
    style START fill:#4caf50
    style END fill:#4caf50
    style P1 fill:#81c784
    style I1 fill:#64b5f6
    style C1 fill:#ff8a65
    style F1 fill:#ba68c8
```

## Phase 1: Prerequisites Check

### Tool Verification
```mermaid
sequenceDiagram
    participant Script as deploy.sh
    participant System as System
    participant UV as uv
    participant Env as Environment
    
    Script->>System: Check OpenTofu/Terraform
    System-->>Script: Version info
    Script->>System: Check Terragrunt
    System-->>Script: Version info
    Script->>System: Check uv
    System-->>Script: Version info
    
    alt uv not found
        Script->>System: Install uv
        System-->>Script: Installation complete
    end
    
    Script->>UV: Create virtual environment
    UV->>UV: Initialize pyproject.toml
    UV->>UV: Create .venv directory
    UV->>UV: Install Ansible
    UV-->>Script: Virtual env ready
    
    Script->>Env: Load .envrc
    Env-->>Script: Environment variables loaded
    
    Script->>Script: Verify credentials
    alt Credentials missing
        Script->>Script: Exit with error
    else Credentials valid
        Script->>Script: Continue to Phase 2
    end
```

### Environment Setup Steps

1. **Check OpenTofu/Terraform**
   ```bash
   if command -v tofu; then
       TF_CMD="tofu"
   elif command -v terraform; then
       TF_CMD="terraform"
   else
       exit 1
   fi
   ```

2. **Check Terragrunt**
   ```bash
   if ! command -v terragrunt; then
       echo "Install Terragrunt"
       exit 1
   fi
   ```

3. **Setup Python Virtual Environment**
   ```bash
   if [ ! -d .venv ]; then
       uv init --no-readme --no-workspace
       uv venv --seed
   fi
   source .venv/bin/activate
   uv pip install -r requirements.txt
   .venv/bin/ansible-galaxy install -r requirements.yml
   ```

4. **Load Environment Variables**
   ```bash
   source .envrc
   # Verify required variables
   echo $PROXMOX_API_TOKEN_SECRET
   echo $SSH_PUBLIC_KEY
   ```

## Phase 2: Infrastructure Provisioning

### Terragrunt Initialization
```mermaid
sequenceDiagram
    participant TG as Terragrunt
    participant TF as OpenTofu
    participant Cache as .terragrunt-cache
    participant Providers as Provider Registry
    
    TG->>TG: Read terragrunt.hcl
    TG->>TG: Read env.hcl
    TG->>Cache: Create cache directory
    TG->>Cache: Generate provider.tf
    TG->>Cache: Generate backend.tf
    TG->>TF: Initialize OpenTofu
    TF->>Providers: Download proxmox provider
    TF->>Providers: Download random provider
    Providers-->>TF: Providers installed
    TF-->>TG: Initialization complete
    TG-->>TG: Ready for planning
```

### Infrastructure Planning
```mermaid
graph TB
    subgraph "Planning Phase"
        READ[Read Configuration]
        CALC[Calculate Changes]
        VALIDATE[Validate Resources]
        DISPLAY[Display Plan]
    end
    
    subgraph "Resources to Create"
        TOKEN[Random K3s Token]
        CP[Control Plane VMs]
        WORKERS[Worker VMs]
        NETWORK[Network Config]
    end
    
    READ --> CALC
    CALC --> VALIDATE
    VALIDATE --> DISPLAY
    
    CALC -.->|Will Create| TOKEN
    CALC -.->|Will Create| CP
    CALC -.->|Will Create| WORKERS
    CALC -.->|Will Configure| NETWORK
    
    style READ fill:#4fc3f7
    style DISPLAY fill:#29b6f6
    style TOKEN fill:#81c784
    style CP fill:#66bb6a
    style WORKERS fill:#4caf50
```

### VM Creation Process
```mermaid
sequenceDiagram
    participant TG as Terragrunt
    participant TF as OpenTofu
    participant PVE as Proxmox API
    participant Storage as ZFS Storage
    participant Template as Cloud Template
    participant VM as Virtual Machine
    
    TG->>TF: Apply configuration
    TF->>TF: Generate K3s token
    
    loop For each VM
        TF->>PVE: Create VM request
        PVE->>Storage: Allocate disk space
        Storage-->>PVE: Disk allocated
        PVE->>Template: Clone template
        Template-->>PVE: VM cloned
        PVE->>VM: Configure CPU/RAM
        PVE->>VM: Configure network
        PVE->>VM: Inject cloud-init
        PVE->>VM: Start VM
        VM->>VM: Cloud-init runs
        VM->>VM: Network configured
        VM->>VM: SSH keys installed
        VM-->>PVE: VM ready
        PVE-->>TF: VM created
    end
    
    TF-->>TG: All VMs created
    TG->>TG: Save state
```

### Resource Creation Order

1. **Random Token Generation**
   ```hcl
   resource "random_password" "k3s_token" {
     length  = 32
     special = false
   }
   ```

2. **Control Plane VMs**
   - Created first (startup order=1)
   - Configured with higher resources
   - Assigned sequential IPs starting from control_plane_ip_start

3. **Worker VMs**
   - Created after control plane (depends_on)
   - Startup order=2
   - Assigned sequential IPs starting from worker_ip_start

## Phase 3: Configuration Management

### Ansible Execution Flow
```mermaid
sequenceDiagram
    participant Deploy as deploy.sh
    participant Ansible as Ansible
    participant CP as Control Plane
    participant Workers as Worker Nodes
    participant K3s as K3s Service
    
    Deploy->>Ansible: Run system-utils-install.yml
    Ansible->>CP: Install packages
    Ansible->>Workers: Install packages
    CP-->>Ansible: Packages installed
    Workers-->>Ansible: Packages installed
    
    Deploy->>Ansible: Run k3s-install.yml
    
    Note over Ansible,CP: Install K3s Server
    Ansible->>CP: Download K3s script
    Ansible->>CP: Install K3s server
    CP->>K3s: Start K3s service
    K3s->>K3s: Initialize cluster
    K3s->>K3s: Start API server
    K3s-->>CP: Server ready
    CP->>CP: Get node token
    CP-->>Ansible: Token retrieved
    
    Note over Ansible,Workers: Install K3s Agents
    loop For each worker
        Ansible->>Workers: Download K3s script
        Ansible->>Workers: Install K3s agent
        Workers->>K3s: Connect to server
        K3s->>Workers: Join cluster
        Workers-->>Ansible: Agent ready
    end
    
    Ansible->>CP: Verify cluster
    CP->>K3s: kubectl get nodes
    K3s-->>CP: All nodes ready
    CP-->>Ansible: Cluster verified
    Ansible-->>Deploy: Configuration complete
```

### System Utilities Installation

**Playbook**: `ansible/system-utils-install.yml`

```mermaid
graph LR
    START[Start] --> UPDATE[Update apt cache]
    UPDATE --> INSTALL[Install packages]
    INSTALL --> VERIFY[Verify installation]
    VERIFY --> END[Complete]
    
    style START fill:#4caf50
    style END fill:#4caf50
```

**Packages Installed**:
- curl
- apt-transport-https
- ca-certificates
- micro (text editor)
- htop (process monitor)
- net-tools (networking utilities)

### K3s Installation Process

**Playbook**: `ansible/k3s-install.yml`

#### Control Plane Setup
```mermaid
graph TB
    START[Start] --> DOWNLOAD[Download K3s script]
    DOWNLOAD --> INSTALL[Install K3s server]
    INSTALL --> CONFIG[Configure cluster-init]
    CONFIG --> WAIT[Wait for API ready]
    WAIT --> TOKEN[Get node token]
    TOKEN --> VERIFY[Verify control plane]
    VERIFY --> END[Control plane ready]
    
    style START fill:#4caf50
    style END fill:#4caf50
    style INSTALL fill:#2196f3
```

**Installation Command**:
```bash
INSTALL_K3S_VERSION=v1.34.1+k3s1 \
K3S_TOKEN=<generated-token> \
sh /tmp/k3s-install.sh server \
  --cluster-init \
  --write-kubeconfig-mode=644 \
  --tls-san=<control-plane-ip> \
  --node-name=<hostname>
```

#### Worker Setup
```mermaid
graph TB
    START[Start] --> DOWNLOAD[Download K3s script]
    DOWNLOAD --> INSTALL[Install K3s agent]
    INSTALL --> CONNECT[Connect to server]
    CONNECT --> WAIT[Wait for kubelet]
    WAIT --> VERIFY[Verify node joined]
    VERIFY --> END[Worker ready]
    
    style START fill:#4caf50
    style END fill:#4caf50
    style INSTALL fill:#ff9800
```

**Installation Command**:
```bash
INSTALL_K3S_VERSION=v1.34.1+k3s1 \
K3S_URL=https://<control-plane-ip>:6443 \
K3S_TOKEN=<node-token> \
sh /tmp/k3s-install.sh agent \
  --node-name=<hostname>
```

### Cluster Verification
```mermaid
sequenceDiagram
    participant Ansible as Ansible
    participant CP as Control Plane
    participant K3s as K3s API
    participant Nodes as All Nodes
    
    Ansible->>CP: Wait for nodes ready
    CP->>K3s: kubectl wait --for=condition=Ready
    K3s->>Nodes: Check node status
    Nodes-->>K3s: Status reports
    K3s-->>CP: All nodes ready
    CP-->>Ansible: Verification complete
    
    Ansible->>CP: Get cluster info
    CP->>K3s: kubectl get nodes -o wide
    K3s-->>CP: Node details
    CP-->>Ansible: Display cluster info
    
    Ansible->>CP: Get kubeconfig
    CP-->>Ansible: kubeconfig content
    Ansible->>Ansible: Save locally
    Ansible->>Ansible: Update server IP
```

## Phase 4: Finalization

### Kubeconfig Retrieval
```mermaid
graph LR
    FETCH[Fetch from CP] --> DECODE[Base64 decode]
    DECODE --> REPLACE[Replace 127.0.0.1]
    REPLACE --> SAVE[Save locally]
    SAVE --> CHMOD[Set permissions 600]
    CHMOD --> VERIFY[Verify access]
    
    style FETCH fill:#4fc3f7
    style SAVE fill:#29b6f6
    style VERIFY fill:#0288d1
```

**Process**:
1. Read `/etc/rancher/k3s/k3s.yaml` from control plane
2. Replace `127.0.0.1` with control plane IP
3. Save to `./kubeconfig`
4. Set permissions to 600
5. Verify with `kubectl get nodes`

### Optional: ArgoCD Installation

**Playbook**: `ansible/argocd-install.yml`

```mermaid
graph TB
    START[User confirms] --> NS[Create namespace]
    NS --> INSTALL[Install ArgoCD]
    INSTALL --> WAIT[Wait for pods]
    WAIT --> SECRET[Get admin password]
    SECRET --> DISPLAY[Display access info]
    DISPLAY --> END[ArgoCD ready]
    
    style START fill:#4caf50
    style END fill:#4caf50
    style INSTALL fill:#ff6f00
```

**Installation Steps**:
1. Create `argocd` namespace
2. Apply ArgoCD manifests
3. Wait for pods to be ready
4. Retrieve admin password
5. Display access instructions

## Deployment Timeline

### Development Environment
```mermaid
gantt
    title Dev Environment Deployment Timeline
    dateFormat mm:ss
    
    section Prerequisites
    Check tools           :00:00, 00:30
    Setup environment     :00:30, 01:00
    
    section Infrastructure
    Initialize Terragrunt :01:00, 01:30
    Plan infrastructure   :01:30, 02:00
    Create VMs            :02:00, 04:00
    Wait for boot         :04:00, 05:00
    
    section Configuration
    Install system utils  :05:00, 06:00
    Install K3s server    :06:00, 07:30
    Install K3s agents    :07:30, 09:00
    Verify cluster        :09:00, 09:30
    
    section Finalization
    Retrieve kubeconfig   :09:30, 10:00
    Optional ArgoCD       :10:00, 12:00
```

**Total Time**: ~10-12 minutes (without ArgoCD)

### Production Environment
```mermaid
gantt
    title Prod Environment Deployment Timeline
    dateFormat mm:ss
    
    section Prerequisites
    Check tools           :00:00, 00:30
    Setup environment     :00:30, 01:00
    
    section Infrastructure
    Initialize Terragrunt :01:00, 01:30
    Plan infrastructure   :01:30, 02:00
    Create VMs (8 nodes)  :02:00, 06:00
    Wait for boot         :06:00, 07:00
    
    section Configuration
    Install system utils  :07:00, 08:30
    Install K3s servers   :08:30, 11:00
    Install K3s agents    :11:00, 14:00
    Verify cluster        :14:00, 15:00
    
    section Finalization
    Retrieve kubeconfig   :15:00, 15:30
    Optional ArgoCD       :15:30, 18:00
```

**Total Time**: ~15-18 minutes (without ArgoCD)

## Error Handling

### Common Failure Points
```mermaid
graph TB
    START[Deployment Start]
    
    CHECK1{Tools<br/>Installed?}
    CHECK2{Environment<br/>Variables Set?}
    CHECK3{Proxmox<br/>Accessible?}
    CHECK4{VMs<br/>Created?}
    CHECK5{SSH<br/>Accessible?}
    CHECK6{K3s<br/>Installed?}
    
    START --> CHECK1
    CHECK1 -->|No| ERROR1[Install tools]
    CHECK1 -->|Yes| CHECK2
    CHECK2 -->|No| ERROR2[Set variables]
    CHECK2 -->|Yes| CHECK3
    CHECK3 -->|No| ERROR3[Check network]
    CHECK3 -->|Yes| CHECK4
    CHECK4 -->|No| ERROR4[Check Proxmox]
    CHECK4 -->|Yes| CHECK5
    CHECK5 -->|No| ERROR5[Wait longer]
    CHECK5 -->|Yes| CHECK6
    CHECK6 -->|No| ERROR6[Check logs]
    CHECK6 -->|Yes| SUCCESS[Deployment Complete]
    
    ERROR1 --> START
    ERROR2 --> START
    ERROR3 --> START
    ERROR4 --> START
    ERROR5 --> CHECK5
    ERROR6 --> CHECK6
    
    style SUCCESS fill:#4caf50
    style ERROR1 fill:#f44336
    style ERROR2 fill:#f44336
    style ERROR3 fill:#f44336
    style ERROR4 fill:#f44336
    style ERROR5 fill:#ff9800
    style ERROR6 fill:#ff9800
```

### Retry Logic
- **SSH Connection**: 5 retries with 10-second delay
- **Node Ready**: 5 retries with 10-second delay
- **API Server**: 300-second timeout

## State Management

### Terraform State Flow
```mermaid
graph LR
    subgraph "State Operations"
        INIT[Initialize] --> PLAN[Plan]
        PLAN --> APPLY[Apply]
        APPLY --> STATE[Update State]
        STATE --> LOCK[Release Lock]
    end
    
    subgraph "State Storage"
        LOCAL[Local File<br/>terraform.tfstate]
        BACKUP[Backup<br/>terraform.tfstate.backup]
    end
    
    STATE --> LOCAL
    LOCAL -.->|Previous| BACKUP
    
    style STATE fill:#4caf50
    style LOCAL fill:#2196f3
```

### State File Location
- **Dev**: `./terraform.tfstate`
- **Prod**: `./terraform.tfstate`
- **Backup**: Automatic on each apply

## Rollback Procedures

### Infrastructure Rollback
```mermaid
graph TB
    ISSUE[Deployment Issue] --> ASSESS[Assess Damage]
    ASSESS --> DECISION{Can Fix?}
    
    DECISION -->|Yes| FIX[Fix and Reapply]
    DECISION -->|No| DESTROY[Destroy Resources]
    
    FIX --> VERIFY[Verify Fix]
    VERIFY --> SUCCESS[Deployment Fixed]
    
    DESTROY --> CLEAN[Clean State]
    CLEAN --> REDEPLOY[Redeploy from Scratch]
    REDEPLOY --> SUCCESS
    
    style ISSUE fill:#f44336
    style SUCCESS fill:#4caf50
```

### Rollback Commands
```bash
# Destroy infrastructure
cd environments/dev
terragrunt destroy

# Clean cache
rm -rf .terragrunt-cache

# Redeploy
terragrunt apply
```

## Monitoring Deployment

### Log Locations
- **Terragrunt**: Console output
- **OpenTofu**: `opentofu-plugin-proxmox.log`
- **Ansible**: Console output
- **K3s**: `journalctl -u k3s`

### Health Checks
```bash
# Check VMs
ssh root@proxmox "qm list | grep k3s"

# Check K3s service
ssh ubuntu@192.168.1.180 "systemctl status k3s"

# Check cluster
export KUBECONFIG=./kubeconfig
kubectl get nodes
kubectl get pods -A
```

## Best Practices

1. **Always verify prerequisites** before starting deployment
2. **Use environment variables** for sensitive data
3. **Test in dev** before deploying to prod
4. **Monitor logs** during deployment
5. **Verify each phase** before proceeding
6. **Keep backups** of state files
7. **Document changes** to configuration
8. **Use version control** for all config files

## References

- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
- [K3s Installation](https://docs.k3s.io/installation)
