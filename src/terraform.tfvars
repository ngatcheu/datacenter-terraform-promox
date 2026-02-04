# ========================================
# Configuration personnalisée
# 3 VMs Rancher + 6 VMs Payload + 2 VMs Services
# ========================================

# === Configuration Proxmox ===
proxmox_node = "devsecops-dojo"
vm_id_start  = 110

# === Template (optionnel) ===
# Si vous avez un template cloud-init, décommentez:
template_name = "rocky-9-cloud-template"

# === Installation depuis ISO (optionnel) ===
# Si vous voulez installer depuis ISO, décommentez:
# iso_file = "local:iso/ubuntu-22.04-server.iso"

# === Configuration VMs RANCHER ===
# Rancher nécessite plus de ressources (control plane Kubernetes)
rancher_cpu_cores = 2
rancher_memory    = 8192  # 8GB RAM
rancher_disk_size = "25G"

# === Configuration VMs PAYLOAD MASTERS ===
# Masters ont besoin de ressources
payload_master_cpu_cores = 2
payload_master_memory     = 4096  # 4 GB RAM

# === Configuration VMs PAYLOAD WORKERS ===
# Workers ont aussi besoin de 8 GB RAM maintenant
payload_worker_cpu_cores = 3
payload_worker_memory    = 8192  # 8 GB RAM

payload_disk_size = "25G"

# === Configuration VM CI/CD ===
cicd_cpu_cores = 2
cicd_memory    = 8192  # 8 GB RAM


# === Stockage ===
vm_storage = "local-lvm"

# === Configuration Réseau ===
network_bridge  = "vmbr0"
ip_address_base = "192.168.1"
ip_start        = 110
gateway         = "192.168.1.1"
nameserver      = "192.168.1.1"

# === Clé SSH (optionnel) ===
# Si vous utilisez cloud-init, ajoutez votre clé publique:
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDaHjlYm77/7UDnQxsl6kd+cLcN8ZKxdqqJ/3qepSjmYuPK5AZjTc8r9XzUiYjzTtD3rt6tvr4LkXF5hPC0FAc0trjSlqwPzsqtCVh4Zk7YQhf4pYoznMs19eSQibM4n4dZogRhc4CoZf8+bAOLboHD2vdqy+mRE4rI6EdykXQC7BQ6TMzQoRE7l+nT1o38wX/FpNdcovT7CaCJUOm+6Gg8Y0aNUZax/Vg3C7ZbUSJIbvvJLaqiBbsQRs/sbX8iOyftng1yxQPxWJgA1JXYKjrrSsZQkPjdP0HXuywqu8fYFAToEld7szmuTa0qj+woKPoCXzgwaO76/l7qFv3iC/gPd9zaVqtIznycI6vX5gnj8XvMs1HRNS3o/ElyMWgWeeNdvqSwyJWihNrd70spMTvC5JzfglgwXuzIMq6mlbEh6YQvN7SSaH4WEOcNF5/yXjIfDZxg246tMDbQ9JjdQ3QzLq7Kuwdtx/LAhyITpcfbweIPXkWHGuRvjkGX0L7ieFU= nsfab@gaby"

# ========================================
# Résultat attendu:
# ========================================
# rancher-1        → ID 110 → 192.168.1.110 → 2C/8 GB/25 G
# rancher-2        → ID 111 → 192.168.1.111 → 2C/8 GB/25 G
# rancher-3        → ID 112 → 192.168.1.112 → 2C/8 GB/25 G
# payload-master-1 → ID 113 → 192.168.1.113 → 2C/4 GB/25 G
# payload-master-2 → ID 114 → 192.168.1.114 → 2C/4 GB/25 G
# payload-master-3 → ID 115 → 192.168.1.115 → 2C/4 GB/25 G
# payload-worker-1 → ID 116 → 192.168.1.116 → 3C/8 GB/25 G
# payload-worker-2 → ID 117 → 192.168.1.117 → 3C/8 GB/25 G
# payload-worker-3 → ID 118 → 192.168.1.118 → 3C/8 GB/25 G
# cicd             → ID 119 → 192.168.1.119 → 2C/8 GB/25 G