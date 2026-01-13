locals {
  ssh_public_key = data.sops_file.secrets.data["ssh_public_key"]
}

resource "proxmox_virtual_environment_vm" "VM-DB-1" {
  name      = "VM-DB-1"
  node_name = "r730-proxmox"
  vm_id     = 300
  template = false

  clone {
    vm_id = 110
    full  = true
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  network_device {
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }

  boot_order    = ["scsi0"]
  scsi_hardware = "virtio-scsi-single"

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         =80
  }

  initialization {
    datastore_id = "local-lvm"

    user_account {
      username = "debian"
      keys     = [trimspace(local.ssh_public_key)]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
        
        # address = "192.168.1.47/24"
        # gateway = "192.168.1.1"
      }
    }
  }

  agent {
  enabled = true
}

  started = true
}

resource "proxmox_virtual_environment_vm" "VM-DB-2" {
  name      = "VM-DB-2"
  node_name = "r730-proxmox"
  vm_id     = 301
  template = false

  clone {
    vm_id = 110
    full  = true
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  network_device {
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }

  boot_order    = ["scsi0"]
  scsi_hardware = "virtio-scsi-single"

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         =80
  }

  initialization {
    datastore_id = "local-lvm"

    user_account {
      username = "debian"
      keys     = [trimspace(local.ssh_public_key)]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
        
      }
    }
  }

  agent {
  enabled = true
}

  started = true
}

resource "proxmox_virtual_environment_vm" "VM-DB-3" {
  name      = "VM-DB-3"
  node_name = "r730-proxmox"
  vm_id     = 302
  template = false

  clone {
    vm_id = 110
    full  = true
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  network_device {
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }

  boot_order    = ["scsi0"]
  scsi_hardware = "virtio-scsi-single"

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         =80
  }

  initialization {
    datastore_id = "local-lvm"

    user_account {
      username = "debian"
      keys     = [trimspace(local.ssh_public_key)]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
        
      }
    }
  }

  agent {
  enabled = true
}

  started = true
}



