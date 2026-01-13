locals {
  ssh_public_key = data.sops_file.secrets.data["ssh_public_key"]
}

resource "proxmox_virtual_environment_vm" "server-minio-preprod" {
  name      = "server-minio-preprod"
  node_name = "r730-proxmox"
  vm_id     = 402
  template = false

  clone {
    vm_id = 110
    full  = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
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
    size         = 50
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

resource "proxmox_virtual_environment_vm" "server-minio-dev" {
  name      = "server-minio-dev"
  node_name = "r730-proxmox"
  vm_id     = 401
  template = false

  clone {
    vm_id = 110
    full  = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
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
    size         = 15
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


