# providers.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.84.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
}

data "sops_file" "secrets" {
  source_file = "secrets.enc.yaml"
}

provider "proxmox" {
  endpoint = "https://192.168.1.114:8006/"
  username = "root@pam"
  password = data.sops_file.secrets.data["proxmox_password"]
  insecure = true
  
  
  ssh {
    agent       = false
    username    = "root"
    private_key = base64decode(data.sops_file.secrets.data["proxmox_ssh_private_key_base64"])
  }
}