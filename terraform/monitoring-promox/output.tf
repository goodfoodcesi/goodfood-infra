

output "k3s_cluster_info" {
  description = "Informations de la VM Grafana"
  value = {
    master  = proxmox_virtual_environment_vm.grafana-vm.ipv4_addresses[1]
  }
}


