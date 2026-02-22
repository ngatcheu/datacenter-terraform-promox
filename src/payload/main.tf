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

# ===== VMs PAYLOAD MASTERS =====

resource "proxmox_virtual_environment_vm" "payload_master_1" {
  name        = "payload-master-1"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start + 3
  description = "Payload Master Node 1"

  clone {
    vm_id = 9100
    full  = true
  }

  cpu {
    cores = var.payload_master_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.payload_master_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start + 3}/24"
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

resource "proxmox_virtual_environment_vm" "payload_master_2" {
  name        = "payload-master-2"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start + 4
  description = "Payload Master Node 2"

  clone {
    vm_id = 9100
    full  = true
  }

  cpu {
    cores = var.payload_master_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.payload_master_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start + 4}/24"
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

  depends_on = [proxmox_virtual_environment_vm.payload_master_1]
}

resource "proxmox_virtual_environment_vm" "payload_master_3" {
  name        = "payload-master-3"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start + 5
  description = "Payload Master Node 3"

  clone {
    vm_id = 9100
    full  = true
  }

  cpu {
    cores = var.payload_master_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.payload_master_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start + 5}/24"
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

  depends_on = [proxmox_virtual_environment_vm.payload_master_2]
}

# ===== VMs PAYLOAD WORKERS =====

resource "proxmox_virtual_environment_vm" "payload_worker_1" {
  name        = "payload-worker-1"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start + 6
  description = "Payload Worker Node 1"

  clone {
    vm_id = 9100
    full  = true
  }

  cpu {
    cores = var.payload_worker_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.payload_worker_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start + 6}/24"
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

  depends_on = [proxmox_virtual_environment_vm.payload_master_3]
}

resource "proxmox_virtual_environment_vm" "payload_worker_2" {
  name        = "payload-worker-2"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start + 7
  description = "Payload Worker Node 2"

  clone {
    vm_id = 9100
    full  = true
  }

  cpu {
    cores = var.payload_worker_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.payload_worker_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start + 7}/24"
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

  depends_on = [proxmox_virtual_environment_vm.payload_worker_1]
}

resource "proxmox_virtual_environment_vm" "payload_worker_3" {
  name        = "payload-worker-3"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start + 8
  description = "Payload Worker Node 3"

  clone {
    vm_id = 9100
    full  = true
  }

  cpu {
    cores = var.payload_worker_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.payload_worker_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start + 8}/24"
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

  depends_on = [proxmox_virtual_environment_vm.payload_worker_2]
}
