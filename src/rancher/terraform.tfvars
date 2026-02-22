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

# === Ressources Rancher ===
rancher_cpu_cores = 2
rancher_memory    = 8192  # 8 GB RAM

# === Clé SSH ===
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDaHjlYm77/7UDnQxsl6kd+cLcN8ZKxdqqJ/3qepSjmYuPK5AZjTc8r9XzUiYjzTtD3rt6tvr4LkXF5hPC0FAc0trjSlqwPzsqtCVh4Zk7YQhf4pYoznMs19eSQibM4n4dZogRhc4CoZf8+bAOLboHD2vdqy+mRE4rI6EdykXQC7BQ6TMzQoRE7l+nT1o38wX/FpNdcovT7CaCJUOm+6Gg8Y0aNUZax/Vg3C7ZbUSJIbvvJLaqiBbsQRs/sbX8iOyftng1yxQPxWJgA1JXYKjrrSsZQkPjdP0HXuywqu8fYFAToEld7szmuTa0qj+woKPoCXzgwaO76/l7qFv3iC/gPd9zaVqtIznycI6vX5gnj8XvMs1HRNS3o/ElyMWgWeeNdvqSwyJWihNrd70spMTvC5JzfglgwXuzIMq6mlbEh6YQvN7SSaH4WEOcNF5/yXjIfDZxg246tMDbQ9JjdQ3QzLq7Kuwdtx/LAhyITpcfbweIPXkWHGuRvjkGX0L7ieFU= nsfab@gaby"

# ========================================
# Résultat attendu:
# rancher-1 → ID 110 → 192.168.1.110 → 2C/8GB
# rancher-2 → ID 111 → 192.168.1.111 → 2C/8GB
# rancher-3 → ID 112 → 192.168.1.112 → 2C/8GB
