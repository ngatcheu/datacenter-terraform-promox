# Explication du Code Terraform - Proxmox

Ce document explique en detail chaque fichier Terraform du projet.

---

## 1. providers.tf - Configuration du Provider

```hcl
terraform {
  required_version = ">= 1.12.2"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.50.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.1.100:8006"
  username = "root@pam"
  password = var.proxmox_password
  insecure = true
}
```

### Explication :

| Bloc | Role |
|------|------|
| `terraform.required_version` | Version minimum de Terraform requise |
| `required_providers.proxmox` | Provider bpg/proxmox pour gerer Proxmox |
| `required_providers.null` | Provider pour executer des scripts |
| `provider "proxmox"` | Configuration de connexion a l'API Proxmox |

### Parametres du provider :
- **endpoint** : URL de l'API Proxmox (port 8006)
- **username** : Format `user@realm` (ici root@pam)
- **password** : Mot de passe (variable sensible)
- **insecure** : Ignore les certificats SSL auto-signes

---

## 2. variables.tf - Variables Parametrables

### Variables de connexion Proxmox

```hcl
variable "proxmox_node" {
  description = "Nom du noeud Proxmox cible"
  type        = string
  default     = "devsecops-dojo"
}

variable "proxmox_host" {
  description = "Adresse IP du serveur Proxmox"
  type        = string
  default     = "192.168.1.100"
}

variable "proxmox_password" {
  description = "Mot de passe root Proxmox"
  type        = string
  sensitive   = true  # Cache la valeur dans les logs
}
```

### Variables des VMs Rancher (Control Plane)

```hcl
variable "rancher_cpu_cores" {
  description = "Nombre de coeurs CPU"
  type        = number
  default     = 2
}

variable "rancher_memory" {
  description = "Memoire RAM en MB"
  type        = number
  default     = 8192  # 8 GB
}
```

### Variables des VMs Payload

```hcl
# Masters : moins de ressources
variable "payload_master_cpu_cores" { default = 2 }
variable "payload_master_memory"    { default = 4096 }  # 4 GB

# Workers : plus de ressources pour les workloads
variable "payload_worker_cpu_cores" { default = 3 }
variable "payload_worker_memory"    { default = 8192 }  # 8 GB
```

### Variables reseau

```hcl
variable "ip_address_base" {
  default = "192.168.1"  # Prefixe IP
}

variable "ip_start" {
  default = 110  # Premiere IP: 192.168.1.110
}

variable "gateway" {
  default = "192.168.1.1"
}

variable "network_bridge" {
  default = "vmbr0"  # Bridge Proxmox
}
```

### Calcul des IPs

| VM | Calcul | IP Finale |
|----|--------|-----------|
| rancher-1 | base.ip_start | 192.168.1.110 |
| rancher-2 | base.ip_start+1 | 192.168.1.111 |
| rancher-3 | base.ip_start+2 | 192.168.1.112 |
| payload-master-1 | base.ip_start+3 | 192.168.1.113 |
| ... | ... | ... |
| cicd | base.ip_start+9 | 192.168.1.119 |

---

## 3. main.tf - Definition des VMs

### Structure d'une ressource VM

```hcl
resource "proxmox_virtual_environment_vm" "rancher_1" {
  # === IDENTIFICATION ===
  name        = "rancher-1"           # Nom affiche dans Proxmox
  node_name   = var.proxmox_node      # Noeud Proxmox cible
  vm_id       = var.vm_id_start       # ID unique (110)
  description = "Rancher Control Plane Node 1"

  # === CLONAGE DU TEMPLATE ===
  clone {
    vm_id = 9100   # ID du template Rocky Linux 9
    full  = true   # Clone complet (pas linked clone)
  }

  # === CPU ===
  cpu {
    cores = var.rancher_cpu_cores  # 2 coeurs
    type  = "host"                 # Passthrough CPU (meilleures perfs)
  }

  # === MEMOIRE ===
  memory {
    dedicated = var.rancher_memory  # 8192 MB = 8 GB
  }

  # === RESEAU ===
  network_device {
    bridge = var.network_bridge  # vmbr0
    model  = "virtio"            # Driver optimise
  }

  # === CLOUD-INIT ===
  initialization {
    # Configuration IP statique
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start}/24"
        gateway = var.gateway
      }
    }

    # DNS
    dns {
      servers = [var.nameserver]
    }

    # Compte utilisateur
    user_account {
      username = "root"
      keys     = [var.ssh_public_key]  # Cle SSH pour connexion
    }
  }
}
```

### Dependances entre VMs

```hcl
resource "proxmox_virtual_environment_vm" "rancher_2" {
  # ...
  depends_on = [proxmox_virtual_environment_vm.rancher_1]
}

resource "proxmox_virtual_environment_vm" "rancher_3" {
  # ...
  depends_on = [proxmox_virtual_environment_vm.rancher_2]
}
```

**Pourquoi depends_on ?**
- Evite de surcharger Proxmox avec 10 creations simultanees
- Cree les VMs une par une dans l'ordre
- Plus stable et predictible

### Ordre de creation

```
rancher_1 → rancher_2 → rancher_3
    → payload_master_1 → payload_master_2 → payload_master_3
        → payload_worker_1 → payload_worker_2 → payload_worker_3
            → cicd
```

---

## 4. template-init.tf - Creation du Template

```hcl
resource "null_resource" "rocky_template" {
  # Copie le script sur Proxmox
  provisioner "file" {
    source      = "${path.module}/create-rocky9-template.sh"
    destination = "/tmp/create-rocky9-template.sh"

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = var.proxmox_host
    }
  }

  # Execute le script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create-rocky9-template.sh",
      "bash /tmp/create-rocky9-template.sh"
    ]

    connection {
      type     = "ssh"
      user     = "root"
      password = var.proxmox_password
      host     = var.proxmox_host
    }
  }
}
```

### Explication :

1. **null_resource** : Ressource sans provider specifique
2. **provisioner "file"** : Copie un fichier via SSH
3. **provisioner "remote-exec"** : Execute des commandes SSH
4. **connection** : Configuration SSH (user, password, host)

---

## 5. create-rocky9-template.sh - Script Bash

```bash
#!/bin/bash

# Configuration
TEMPLATE_ID=9100
TEMPLATE_NAME="rocky-9-cloud-template"
STORAGE="local-lvm"

# Verifier si le template existe deja
if qm status $TEMPLATE_ID &>/dev/null; then
    echo "Template existe deja"
    exit 0
fi

# Telecharger l'image cloud Rocky Linux 9
wget -O rocky9-cloud.qcow2 \
  https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2

# Creer la VM
qm create $TEMPLATE_ID \
  --name $TEMPLATE_NAME \
  --memory 2048 \
  --cores 2 \
  --cpu host \
  --net0 virtio,bridge=vmbr0

# Importer le disque qcow2
qm importdisk $TEMPLATE_ID rocky9-cloud.qcow2 $STORAGE

# Configurer la VM
qm set $TEMPLATE_ID --scsihw virtio-scsi-pci \
                    --scsi0 $STORAGE:vm-$TEMPLATE_ID-disk-0
qm set $TEMPLATE_ID --ide2 $STORAGE:cloudinit
qm set $TEMPLATE_ID --boot c --bootdisk scsi0
qm set $TEMPLATE_ID --serial0 socket --vga serial0
qm set $TEMPLATE_ID --agent enabled=1
qm set $TEMPLATE_ID --ciuser root
qm set $TEMPLATE_ID --ipconfig0 ip=dhcp

# Convertir en template
qm template $TEMPLATE_ID

# Nettoyer
rm -f rocky9-cloud.qcow2
```

### Commandes Proxmox expliquees :

| Commande | Role |
|----------|------|
| `qm create` | Cree une nouvelle VM |
| `qm importdisk` | Importe un disque qcow2 |
| `qm set` | Modifie la configuration |
| `qm template` | Convertit en template (lecture seule) |

### Options cloud-init :
- **--ide2 cloudinit** : Ajoute un lecteur cloud-init
- **--ciuser** : Utilisateur par defaut
- **--ipconfig0** : Configuration IP

---

## 6. outputs.tf - Affichage des Resultats

### Outputs simples

```hcl
output "rancher_vm_names" {
  description = "Noms des VMs Rancher"
  value = [
    proxmox_virtual_environment_vm.rancher_1.name,
    proxmox_virtual_environment_vm.rancher_2.name,
    proxmox_virtual_environment_vm.rancher_3.name
  ]
}

output "rancher_vm_ids" {
  description = "IDs des VMs Rancher"
  value = [
    proxmox_virtual_environment_vm.rancher_1.vm_id,
    proxmox_virtual_environment_vm.rancher_2.vm_id,
    proxmox_virtual_environment_vm.rancher_3.vm_id
  ]
}
```

### Output de resume (heredoc)

```hcl
output "deployment_summary" {
  value = <<-EOT
    RANCHER NODES:
      rancher-1 → ID ${proxmox_virtual_environment_vm.rancher_1.vm_id}
      rancher-2 → ID ${proxmox_virtual_environment_vm.rancher_2.vm_id}

    PAYLOAD MASTERS:
      payload-master-1 → ID ${proxmox_virtual_environment_vm.payload_master_1.vm_id}

    Total: 10 VMs deployees !
  EOT
}
```

### Syntaxe heredoc :
- `<<-EOT` : Debut du bloc texte (- = ignore indentation)
- `${...}` : Interpolation de variables
- `EOT` : Fin du bloc texte

---

## 7. terraform.tfvars - Valeurs des Variables

```hcl
# ATTENTION : Ne jamais commiter ce fichier !

proxmox_password = "VotreMotDePasse"
ssh_public_key   = "ssh-rsa AAAAB3NzaC1..."
proxmox_host     = "192.168.1.100"
proxmox_node     = "devsecops-dojo"

# Optionnel : surcharger les valeurs par defaut
rancher_cpu_cores = 4
rancher_memory    = 16384
```

---

## 8. Flux d'Execution

```
terraform init
    |
    v
Telecharge providers (bpg/proxmox, hashicorp/null)
    |
    v
terraform plan
    |
    v
Calcule les changements a effectuer
    |
    v
terraform apply
    |
    v
1. null_resource.rocky_template
   - Copie create-rocky9-template.sh sur Proxmox
   - Execute le script (cree template ID 9100)
    |
    v
2. proxmox_virtual_environment_vm.rancher_1
   - Clone template 9100
   - Configure CPU, RAM, reseau
   - Applique cloud-init (IP, SSH key)
    |
    v
3. rancher_2 → rancher_3 → payload_master_1 → ...
    |
    v
4. proxmox_virtual_environment_vm.cicd (derniere VM)
    |
    v
terraform output
    |
    v
Affiche le resume du deploiement
```

---

## 9. Commandes Utiles

```bash
# Initialiser le projet
terraform init

# Voir les changements prevus
terraform plan

# Appliquer les changements
terraform apply

# Appliquer sans confirmation
terraform apply -auto-approve

# Voir l'etat actuel
terraform show

# Lister les ressources
terraform state list

# Voir les outputs
terraform output

# Detruire l'infrastructure
terraform destroy

# Formater le code
terraform fmt

# Valider la syntaxe
terraform validate
```

---

## 10. Bonnes Pratiques Appliquees

| Pratique | Implementation |
|----------|---------------|
| Variables sensibles | `sensitive = true` sur le password |
| Separation des fichiers | 1 fichier = 1 responsabilite |
| Valeurs par defaut | Definis dans variables.tf |
| Secrets exclus de Git | terraform.tfvars dans .gitignore |
| Documentation | Descriptions sur chaque variable |
| Outputs utiles | Resume complet du deploiement |
| Idempotence | Script template verifie si existe deja |
