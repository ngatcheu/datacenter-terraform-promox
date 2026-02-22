terraform {
  required_version = ">= 1.2.0"

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
  endpoint = "https://${var.proxmox_host}:8006"
  username = "root@pam"
  password = var.proxmox_password
  insecure = true
}
