# ========================================
# Initialisation du template Rocky Linux 9
# Exécute le script de création du template via SSH
# ========================================

resource "null_resource" "rocky_template" {
  provisioner "file" {
    source      = "${path.module}/create-rocky9-template.sh"
    destination = "/tmp/create-rocky9-template.sh"

    connection {
      type        = "ssh"
      user        = "root"
      password    = var.proxmox_password
      host        = var.proxmox_host
      port        = 22
      timeout     = "5m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create-rocky9-template.sh",
      "bash /tmp/create-rocky9-template.sh"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      password    = var.proxmox_password
      host        = var.proxmox_host
      port        = 22
      timeout     = "10m"
    }
  }
}
