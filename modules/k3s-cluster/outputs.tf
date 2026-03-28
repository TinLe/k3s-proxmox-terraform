locals {
  # Derive /24 CIDR from the control plane start IP (e.g. "192.168.1.180" -> "192.168.1.0/24")
  cp_network_cidr  = "${join(".", slice(split(".", var.control_plane_ip_start), 0, 3))}.0/24"
  cp_host_offset   = parseint(split(".", var.control_plane_ip_start)[3], 10)
  wk_network_cidr  = "${join(".", slice(split(".", var.worker_ip_start), 0, 3))}.0/24"
  wk_host_offset   = parseint(split(".", var.worker_ip_start)[3], 10)
}

output "k3s_token" {
  description = "K3s cluster token"
  value       = local.k3s_token
  sensitive   = true
}

output "control_plane_ips" {
  description = "Control plane node IP addresses"
  value = [
    for i in range(var.control_plane_count) :
    cidrhost(local.cp_network_cidr, local.cp_host_offset + i)
  ]
}

output "worker_ips" {
  description = "Worker node IP addresses"
  value = [
    for i in range(var.worker_count) :
    cidrhost(local.wk_network_cidr, local.wk_host_offset + i)
  ]
}

output "control_plane_names" {
  description = "Control plane node names"
  value       = [for vm in proxmox_vm_qemu.k3s_control_plane : vm.name]
}

output "worker_names" {
  description = "Worker node names"
  value       = [for vm in proxmox_vm_qemu.k3s_worker : vm.name]
}

output "ssh_command_control_plane" {
  description = "SSH command for control plane node"
  value       = "ssh ubuntu@${cidrhost(local.cp_network_cidr, local.cp_host_offset)}"
}

output "kubeconfig_command" {
  description = "Command to retrieve kubeconfig from control plane"
  value       = "ssh ubuntu@${cidrhost(local.cp_network_cidr, local.cp_host_offset)} 'sudo cat /etc/rancher/k3s/k3s.yaml'"
}

output "cluster_info" {
  description = "K3s cluster information"
  value = {
    environment = var.environment
    control_plane = {
      count  = var.control_plane_count
      cpu    = var.control_plane_cpu
      memory = var.control_plane_memory
      ips = [
        for i in range(var.control_plane_count) :
        cidrhost(local.cp_network_cidr, local.cp_host_offset + i)
      ]
    }
    workers = {
      count  = var.worker_count
      cpu    = var.worker_cpu
      memory = var.worker_memory
      ips = [
        for i in range(var.worker_count) :
        cidrhost(local.wk_network_cidr, local.wk_host_offset + i)
      ]
    }
    k3s_version = var.k3s_version
  }
}
