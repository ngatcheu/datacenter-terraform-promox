output "vm_name" {
  description = "Nom de la VM CI/CD"
  value       = proxmox_virtual_environment_vm.cicd.name
}

output "vm_id" {
  description = "ID de la VM CI/CD"
  value       = proxmox_virtual_environment_vm.cicd.vm_id
}

output "vm_ip" {
  description = "Adresse IP de la VM CI/CD"
  value       = "${var.ip_address_base}.${var.ip_start + 9}"
}
