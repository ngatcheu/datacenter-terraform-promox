# === Configuration Proxmox ===
proxmox_host = "192.168.1.100"
proxmox_node = "devsecops-dojo"

# === IDs et réseau ===
vm_id_start     = 110
network_bridge  = "vmbr0"
ip_address_base = "192.168.1"
ip_start        = 110
gateway         = "192.168.1.1"
nameserver      = "192.168.1.1"

# === Ressources Payload Masters ===
payload_master_cpu_cores = 2
payload_master_memory    = 4096  # 4 GB RAM

# === Ressources Payload Workers ===
payload_worker_cpu_cores = 3
payload_worker_memory    = 8192  # 8 GB RAM

# === Clé SSH ===
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDaHjlYm77/7UDnQxsl6kd+cLcN8ZKxdqqJ/3qepSjmYuPK5AZjTc8r9XzUiYjzTtD3rt6tvr4LkXF5hPC0FAc0trjSlqwPzsqtCVh4Zk7YQhf4pYoznMs19eSQibM4n4dZogRhc4CoZf8+bAOLboHD2vdqy+mRE4rI6EdykXQC7BQ6TMzQoRE7l+nT1o38wX/FpNdcovT7CaCJUOm+6Gg8Y0aNUZax/Vg3C7ZbUSJIbvvJLaqiBbsQRs/sbX8iOyftng1yxQPxWJgA1JXYKjrrSsZQkPjdP0HXuywqu8fYFAToEld7szmuTa0qj+woKPoCXzgwaO76/l7qFv3iC/gPd9zaVqtIznycI6vX5gnj8XvMs1HRNS3o/ElyMWgWeeNdvqSwyJWihNrd70spMTvC5JzfglgwXuzIMq6mlbEh6YQvN7SSaH4WEOcNF5/yXjIfDZxg246tMDbQ9JjdQ3QzLq7Kuwdtx/LAhyITpcfbweIPXkWHGuRvjkGX0L7ieFU= nsfab@gaby"

# ========================================
# Résultat attendu:
# payload-master-1 → ID 113 → 192.168.1.113 → 2C/4GB
# payload-master-2 → ID 114 → 192.168.1.114 → 2C/4GB
# payload-master-3 → ID 115 → 192.168.1.115 → 2C/4GB
# payload-worker-1 → ID 116 → 192.168.1.116 → 3C/8GB
# payload-worker-2 → ID 117 → 192.168.1.117 → 3C/8GB
# payload-worker-3 → ID 118 → 192.168.1.118 → 3C/8GB
