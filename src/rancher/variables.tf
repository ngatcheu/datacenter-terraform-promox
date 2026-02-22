variable "proxmox_host" {
  description = "Adresse IP du serveur Proxmox"
  type        = string
  default     = "192.168.1.100"
}

variable "proxmox_password" {
  description = "Mot de passe root Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  type = string
}

variable "network_bridge" {
  type = string
}

variable "vm_id_start" {
  type = number
}

variable "ip_address_base" {
  type = string
}

variable "ip_start" {
  type = number
}

variable "gateway" {
  type = string
}

variable "nameserver" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "rancher_cpu_cores" {
  type = number
}

variable "rancher_memory" {
  type = number
}
