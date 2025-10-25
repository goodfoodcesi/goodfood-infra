# output "k3s_master_ip" {
#   description = "IP du master K3s"
#   value       = proxmox_virtual_environment_vm.k3s-master.ipv4_addresses[0]
# }

# output "k3s_workers_ips" {
#   description = "IPs des workers K3s"
#   value       = [for vm in proxmox_virtual_environment_vm.k3s-worker : vm.ipv4_addresses[1]]
# }

output "k3s_cluster_info" {
  description = "Informations du cluster K3s"
  value = {
    master  = proxmox_virtual_environment_vm.k3s-master.ipv4_addresses[1]
    workers = [for vm in proxmox_virtual_environment_vm.k3s-worker : vm.ipv4_addresses[1]]
  }
}

# output "k3s_master_interfaces" {
#   value = proxmox_virtual_environment_vm.k3s-master.network_interface_names
# }

