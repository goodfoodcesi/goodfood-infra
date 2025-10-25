# main.tf
locals {
  ssh_public_key = data.sops_file.secrets.data["ssh_public_key"]
}

resource "proxmox_virtual_environment_vm" "k3s-master" {
  name      = "k3s-master"
  node_name = "r730-proxmox"
  vm_id     = 100
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
    size         = 20
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

resource "proxmox_virtual_environment_vm" "k3s-worker" {
  count     = 3
  name      = "k3s-worker-${count.index + 1}"
  node_name = "r730-proxmox"
  
  vm_id     = 200 + count.index + 1
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
    # hostname      = "k3s-worker-${count.index + 1}"


    user_account {
      username = "debian"
      keys     = [trimspace(local.ssh_public_key)]
    }


    ip_config {
      ipv4 {
        address = "dhcp"
        # address = "192.168.1.10${count.index + 1}/24"
        # gateway = "192.168.1.1"
      }
    }
  }

  agent {
  enabled = true
}


  started = true
}
