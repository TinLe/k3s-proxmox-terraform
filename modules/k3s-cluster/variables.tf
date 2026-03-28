variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID (format: user@realm!tokenname)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "template_id" {
  description = "VM template name for cloning"
  type        = string
}

variable "vm_id_start" {
  description = "Starting VM ID for created VMs"
  type        = number
}

variable "storage" {
  description = "Storage pool for VM disks"
  type        = string
}

variable "snippet_storage" {
  description = "Storage for cloud-init snippets"
  type        = string
}

variable "bridge" {
  description = "Network bridge"
  type        = string
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
}

variable "searchdomain" {
  description = "DNS search domain"
  type        = string
}

# Control Plane Configuration
variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
}

variable "control_plane_cpu" {
  description = "CPU cores for control plane nodes"
  type        = number
}

variable "control_plane_memory" {
  description = "Memory in MB for control plane nodes"
  type        = number
}

variable "control_plane_disk_size" {
  description = "Disk size for control plane nodes"
  type        = string
}

variable "control_plane_ip_start" {
  description = "Starting IP for control plane nodes"
  type        = string
}

# Worker Configuration
variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "worker_cpu" {
  description = "CPU cores for worker nodes"
  type        = number
}

variable "worker_memory" {
  description = "Memory in MB for worker nodes"
  type        = number
}

variable "worker_disk_size" {
  description = "Disk size for worker nodes"
  type        = string
}

variable "worker_ip_start" {
  description = "Starting IP for worker nodes"
  type        = string
}

# K3s Configuration
variable "k3s_version" {
  description = "K3s version to install"
  type        = string
}

variable "k3s_token" {
  description = "K3s cluster token (will be auto-generated if not provided)"
  type        = string
  sensitive   = true
}

variable "proxmox_storage" {
  description = "The name of the Proxmox storage pool"
  type        = string
  default     = "local-zfs" # Keep as default but allow override
}
