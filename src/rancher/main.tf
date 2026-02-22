# ===== TEMPLATE ROCKY 9 =====

resource "null_resource" "rocky_template" {
  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = "root"
    password = var.proxmox_password
  }

  provisioner "file" {
    source      = "${path.module}/create-rocky9-template.sh"
    destination = "/tmp/create-rocky9-template.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create-rocky9-template.sh",
      "/tmp/create-rocky9-template.sh"
    ]
  }
}

# ===== VMs RANCHER (Control Plane) =====

resource "proxmox_virtual_environment_vm" "rancher_1" {
  name        = "rancher-1"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start
  description = "Rancher Kubernetes Control Plane Node 1"

  clone {
    vm_id = 9100
    full  = true
  }

  cpu {
    cores = var.rancher_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.rancher_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.nameserver]
    }

    user_account {
      username = "root"
      keys     = [var.ssh_public_key]
    }
  }

  depends_on = [null_resource.rocky_template]
}

resource "proxmox_virtual_environment_vm" "rancher_2" {
  name        = "rancher-2"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start + 1
  description = "Rancher Kubernetes Control Plane Node 2"

  clone {
    vm_id = 9100
    full  = true
  }

  cpu {
    cores = var.rancher_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.rancher_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start + 1}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.nameserver]
    }

    user_account {
      username = "root"
      keys     = [var.ssh_public_key]
    }
  }

  depends_on = [proxmox_virtual_environment_vm.rancher_1]
}

resource "proxmox_virtual_environment_vm" "rancher_3" {
  name        = "rancher-3"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start + 2
  description = "Rancher Kubernetes Control Plane Node 3"

  clone {
    vm_id = 9100
    full  = true
  }

  cpu {
    cores = var.rancher_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.rancher_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start + 2}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.nameserver]
    }

    user_account {
      username = "root"
      keys     = [var.ssh_public_key]
    }
  }

  depends_on = [proxmox_virtual_environment_vm.rancher_2]
}
