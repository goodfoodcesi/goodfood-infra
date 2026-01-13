

output "minio_info" {
  description = "Informations de la VM du server minio preprod et dev"
  value = {
    preprod  = proxmox_virtual_environment_vm.server-minio-preprod.ipv4_addresses[1],
    dev  = proxmox_virtual_environment_vm.server-minio-dev.ipv4_addresses[1]
  }
}


