output "vm_names" {
  description = "Noms des VMs Rancher"
  value = [
    proxmox_virtual_environment_vm.rancher_1.name,
    proxmox_virtual_environment_vm.rancher_2.name,
    proxmox_virtual_environment_vm.rancher_3.name,
  ]
}

output "vm_ids" {
  description = "IDs des VMs Rancher"
  value = [
    proxmox_virtual_environment_vm.rancher_1.vm_id,
    proxmox_virtual_environment_vm.rancher_2.vm_id,
    proxmox_virtual_environment_vm.rancher_3.vm_id,
  ]
}
