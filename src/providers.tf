terraform {
  required_version = ">= 1.12.2"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.50.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.1.100:8006"

  username = "root@pam"
  password = var.proxmox_password

  insecure = true
}
