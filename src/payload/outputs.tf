output "vm_names" {
  description = "Noms des VMs Payload (masters + workers)"
  value = [
    proxmox_virtual_environment_vm.payload_master_1.name,
    proxmox_virtual_environment_vm.payload_master_2.name,
    proxmox_virtual_environment_vm.payload_master_3.name,
    proxmox_virtual_environment_vm.payload_worker_1.name,
    proxmox_virtual_environment_vm.payload_worker_2.name,
    proxmox_virtual_environment_vm.payload_worker_3.name,
  ]
}

output "vm_ids" {
  description = "IDs des VMs Payload (masters + workers)"
  value = [
    proxmox_virtual_environment_vm.payload_master_1.vm_id,
    proxmox_virtual_environment_vm.payload_master_2.vm_id,
    proxmox_virtual_environment_vm.payload_master_3.vm_id,
    proxmox_virtual_environment_vm.payload_worker_1.vm_id,
    proxmox_virtual_environment_vm.payload_worker_2.vm_id,
    proxmox_virtual_environment_vm.payload_worker_3.vm_id,
  ]
}
