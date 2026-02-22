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

# ===== VM CI/CD =====

resource "proxmox_virtual_environment_vm" "cicd" {
  name        = "cicd"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id_start + 9
  description = "CI/CD Server (GitLab + OpenLDAP)"

  clone {
    vm_id = 9100
    full  = true
  }

  cpu {
    cores = var.cicd_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.cicd_memory
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start + 9}/24"
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
