# Development environment configuration

include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = "${get_terragrunt_dir()}/env.hcl"
  expose = true
}

terraform {
  source = "../../modules/k3s-cluster"
}

inputs = {
  # Environment
  environment = include.env.locals.environment
  
  # Proxmox Connection
  proxmox_api_url          = get_env("PROXMOX_API_URL", "https://192.168.1.200:8006/api2/json")
  proxmox_api_token_id     = get_env("PROXMOX_API_TOKEN_ID", "root@pam!terraform")
  proxmox_api_token_secret = get_env("PROXMOX_API_TOKEN_SECRET", "")
  
  # SSH Key
  ssh_public_key = get_env("SSH_PUBLIC_KEY", "")
  
  # Proxmox Settings
  proxmox_node    = "proxmox"
  template_id     = "ubuntu-24.04-cloud-tpl"
  vm_id_start     = 500
  # storage         = "local-zfs"
  storage         = var.proxmox_storage
  snippet_storage = "usb-storage-01"
  bridge          = "vmbr0"
  gateway         = "192.168.1.1"
  nameserver      = "192.168.1.1"
  searchdomain    = "local"
  
  # Control Plane Configuration
  control_plane_count     = 1
  control_plane_cpu       = 2
  control_plane_memory    = 4096
  control_plane_disk_size = "15G"
  control_plane_ip_start  = "192.168.1.180"
  
  # Worker Configuration
  worker_count     = 3
  worker_cpu       = 1
  worker_memory    = 2048
  worker_disk_size = "10G"
  worker_ip_start  = "192.168.1.185"
  
  # K3s Configuration
  k3s_version = "v1.34.1+k3s1"
  k3s_token   = ""
}
