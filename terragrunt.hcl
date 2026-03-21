# Root Terragrunt configuration
# This file defines common settings for all environments

locals {
  # Load environment-specific variables
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl", "env.hcl"))
  
  # Common tags
  common_tags = {
    ManagedBy = "Terragrunt"
    Project   = "k3s-proxmox"
  }
}

# Configure OpenTofu backend
remote_state {
  backend = "local"
  
  config = {
    path = "${get_parent_terragrunt_dir()}/terraform.tfstate"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc05"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
  pm_log_enable       = true
  pm_log_file         = "opentofu-plugin-proxmox.log"
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}
EOF
}

# Input variables that will be passed to all modules
inputs = {
  common_tags = local.common_tags
}
