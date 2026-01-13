output "vm_db1_ip" {
  description = "IP de VM-DB-1 (Identity)"
  value       = proxmox_virtual_environment_vm.VM-DB-1.ipv4_addresses[1]
}

output "vm_db2_ip" {
  description = "IP de VM-DB-2 (Business)"
  value       = proxmox_virtual_environment_vm.VM-DB-2.ipv4_addresses[1]
}
output "vm_db3_ip" {
  description = "IP de VM-DB-3 (Business)"
  value       = proxmox_virtual_environment_vm.VM-DB-3.ipv4_addresses[1]
}

output "vm_db1_id" {
  value = proxmox_virtual_environment_vm.VM-DB-1.vm_id
}

output "vm_db2_id" {
  value = proxmox_virtual_environment_vm.VM-DB-2.vm_id
}
output "vm_db3_id" {
  value = proxmox_virtual_environment_vm.VM-DB-3.vm_id
}