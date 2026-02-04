# Cloud-Init et Templates Proxmox - Guide Complet

## Sommaire
1. [Qu'est-ce qu'un Template ?](#1-quest-ce-quun-template-)
2. [Qu'est-ce que Cloud-Init ?](#2-quest-ce-que-cloud-init-)
3. [Creation du Template Rocky Linux 9](#3-creation-du-template-rocky-linux-9)
4. [Configuration Cloud-Init dans Terraform](#4-configuration-cloud-init-dans-terraform)
5. [Flux Complet de Deploiement](#5-flux-complet-de-deploiement)

---

## 1. Qu'est-ce qu'un Template ?

### Definition
Un **template** est une VM "modele" en lecture seule qui sert de base pour creer d'autres VMs par clonage.

### Analogie
```
Template = Image Docker
Clone    = Container Docker
```

### Avantages

| Sans Template | Avec Template |
|---------------|---------------|
| Installer l'OS a chaque VM | Cloner en quelques secondes |
| Configuration manuelle | Configuration automatique |
| Risque d'erreurs | Reproductibilite garantie |
| Long et repetitif | Rapide et efficace |

### Types de clones

```
TEMPLATE (ID 9100)
      |
      +-- Full Clone (copie complete)
      |     └── VM independante, plus d'espace disque
      |
      +-- Linked Clone (copie liee)
            └── Partage le disque de base, moins d'espace
```

Dans notre code, on utilise `full = true` :
```hcl
clone {
  vm_id = 9100
  full  = true  # Clone complet
}
```

---

## 2. Qu'est-ce que Cloud-Init ?

### Definition
**Cloud-Init** est un outil standard pour initialiser automatiquement une VM au premier demarrage.

### Origine
- Cree par Canonical (Ubuntu) en 2010
- Standard de facto dans le cloud (AWS, Azure, GCP)
- Supporte par toutes les distributions Linux majeures

### Ce que Cloud-Init peut configurer

```
┌─────────────────────────────────────────────┐
│              CLOUD-INIT                      │
├─────────────────────────────────────────────┤
│  ✓ Hostname                                 │
│  ✓ Utilisateurs et mots de passe            │
│  ✓ Cles SSH                                 │
│  ✓ Configuration reseau (IP, DNS, gateway)  │
│  ✓ Packages a installer                     │
│  ✓ Scripts a executer                       │
│  ✓ Fichiers a creer                         │
│  ✓ Montages disques                         │
└─────────────────────────────────────────────┘
```

### Comment ca fonctionne

```
1. VM demarre
      |
      v
2. Cloud-Init detecte un disque cloud-init (ISO virtuel)
      |
      v
3. Cloud-Init lit la configuration (meta-data, user-data)
      |
      v
4. Cloud-Init applique la configuration
      |
      v
5. VM prete a l'emploi !
```

### Sources de donnees Cloud-Init

| Source | Description |
|--------|-------------|
| NoCloud | Disque ISO local (utilise par Proxmox) |
| AWS EC2 | Metadata service AWS |
| Azure | Metadata service Azure |
| GCP | Metadata service Google Cloud |
| OpenStack | Metadata service OpenStack |

**Proxmox utilise NoCloud** : un disque virtuel IDE contenant la configuration.

---

## 3. Creation du Template Rocky Linux 9

### Le script complet explique

```bash
#!/bin/bash

# === CONFIGURATION ===
TEMPLATE_ID=9100                    # ID unique du template
TEMPLATE_NAME="rocky-9-cloud-template"
STORAGE="local-lvm"                 # Stockage Proxmox
MEMORY=2048                         # RAM pour le template
BRIDGE="vmbr0"                      # Bridge reseau

echo "========================================="
echo "Creation du template Rocky Linux 9"
echo "========================================="
```

### Etape 1 : Verification si le template existe

```bash
if qm status $TEMPLATE_ID &>/dev/null; then
    echo "Template existe deja (ID: $TEMPLATE_ID)"
    exit 0
fi
```

**Explication :**
- `qm status` : Verifie l'etat d'une VM
- `&>/dev/null` : Redirige stdout et stderr vers null (silence)
- `exit 0` : Sort avec succes si existe deja (idempotence)

### Etape 2 : Telecharger l'image Cloud

```bash
cd /tmp
wget -O rocky9-cloud.qcow2 \
  https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
```

**Qu'est-ce qu'une image Cloud ?**

| Image Standard | Image Cloud |
|----------------|-------------|
| ISO d'installation | Disque pre-installe |
| Installation interactive | Pret a demarrer |
| Sans cloud-init | Cloud-init pre-installe |
| Grande taille (~10 GB) | Petite taille (~1 GB) |

**Format qcow2 :**
- QEMU Copy-On-Write version 2
- Compression native
- Snapshots supportes
- Standard pour KVM/Proxmox

### Etape 3 : Creer la VM

```bash
qm create $TEMPLATE_ID \
  --name $TEMPLATE_NAME \
  --memory $MEMORY \
  --net0 virtio,bridge=$BRIDGE \
  --cores 2 \
  --cpu host
```

| Option | Valeur | Description |
|--------|--------|-------------|
| `--name` | rocky-9-cloud-template | Nom affiche |
| `--memory` | 2048 | RAM en MB |
| `--net0` | virtio,bridge=vmbr0 | Carte reseau virtio |
| `--cores` | 2 | Coeurs CPU |
| `--cpu` | host | Passthrough CPU |

### Etape 4 : Importer le disque

```bash
qm importdisk $TEMPLATE_ID rocky9-cloud.qcow2 $STORAGE
```

**Resultat :**
- Convertit qcow2 en format raw ou qcow2 Proxmox
- Stocke dans `local-lvm`
- Cree `vm-9100-disk-0`

### Etape 5 : Configurer la VM

```bash
# Controleur SCSI virtio (meilleures performances)
qm set $TEMPLATE_ID --scsihw virtio-scsi-pci \
                    --scsi0 $STORAGE:vm-$TEMPLATE_ID-disk-0

# Ajouter le disque Cloud-Init
qm set $TEMPLATE_ID --ide2 $STORAGE:cloudinit

# Configuration de boot
qm set $TEMPLATE_ID --boot c --bootdisk scsi0

# Console serie (pour debug)
qm set $TEMPLATE_ID --serial0 socket --vga serial0

# Activer QEMU Guest Agent
qm set $TEMPLATE_ID --agent enabled=1

# Configuration Cloud-Init par defaut
qm set $TEMPLATE_ID --ciuser root
qm set $TEMPLATE_ID --ipconfig0 ip=dhcp
```

**Explication des options :**

| Option | Description |
|--------|-------------|
| `--scsihw virtio-scsi-pci` | Controleur disque performant |
| `--scsi0` | Attache le disque importe |
| `--ide2 cloudinit` | Disque cloud-init (IDE obligatoire) |
| `--boot c` | Boot sur disque |
| `--bootdisk scsi0` | Disque de boot |
| `--serial0 socket` | Console serie |
| `--agent enabled=1` | QEMU Guest Agent |
| `--ciuser` | Utilisateur cloud-init |
| `--ipconfig0` | Config IP (DHCP par defaut) |

### Etape 6 : Convertir en Template

```bash
qm template $TEMPLATE_ID
```

**Effet :**
- VM devient en lecture seule
- Ne peut plus etre demarree directement
- Peut uniquement etre clonee
- Icone change dans l'interface Proxmox

### Etape 7 : Nettoyer

```bash
rm -f /tmp/rocky9-cloud.qcow2
```

---

## 4. Configuration Cloud-Init dans Terraform

### Bloc initialization

```hcl
resource "proxmox_virtual_environment_vm" "rancher_1" {
  # ... autres configs ...

  initialization {
    # === CONFIGURATION IP ===
    ip_config {
      ipv4 {
        address = "${var.ip_address_base}.${var.ip_start}/24"
        gateway = var.gateway
      }
    }

    # === SERVEURS DNS ===
    dns {
      servers = [var.nameserver]
    }

    # === COMPTE UTILISATEUR ===
    user_account {
      username = "root"
      keys     = [var.ssh_public_key]
    }
  }
}
```

### Decomposition de chaque partie

#### Configuration IP

```hcl
ip_config {
  ipv4 {
    address = "192.168.1.110/24"  # IP statique avec masque
    gateway = "192.168.1.1"       # Passerelle par defaut
  }
}
```

**Ce que Proxmox genere :**
```yaml
# meta-data
network-interfaces: |
  auto eth0
  iface eth0 inet static
    address 192.168.1.110
    netmask 255.255.255.0
    gateway 192.168.1.1
```

#### Configuration DNS

```hcl
dns {
  servers = ["192.168.1.1"]
}
```

**Ce que Proxmox genere :**
```yaml
# Dans /etc/resolv.conf
nameserver 192.168.1.1
```

#### Compte Utilisateur

```hcl
user_account {
  username = "root"
  keys     = ["ssh-rsa AAAAB3NzaC1yc2E..."]
}
```

**Ce que Proxmox genere :**
```yaml
# user-data
users:
  - name: root
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2E...
```

### Options avancees disponibles

```hcl
initialization {
  # Hostname personnalise
  hostname = "my-server"

  # Domaine
  domain = "example.com"

  # Configuration IP (IPv4 + IPv6)
  ip_config {
    ipv4 {
      address = "192.168.1.110/24"
      gateway = "192.168.1.1"
    }
    ipv6 {
      address = "fd00::110/64"
      gateway = "fd00::1"
    }
  }

  # Plusieurs serveurs DNS
  dns {
    servers = ["8.8.8.8", "8.8.4.4"]
    domain  = "example.com"
  }

  # Compte utilisateur avec mot de passe
  user_account {
    username = "admin"
    password = "hashed_password"
    keys     = [var.ssh_public_key]
  }

  # Script personnalise (user-data)
  user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
}
```

---

## 5. Flux Complet de Deploiement

### Diagramme de sequence

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│Terraform │    │ Proxmox  │    │ Template │    │   VM     │
└────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │               │
     │ 1. Clone      │               │               │
     │──────────────>│               │               │
     │               │ 2. Copie      │               │
     │               │──────────────>│               │
     │               │               │ 3. Nouveau    │
     │               │               │    disque     │
     │               │               │──────────────>│
     │               │               │               │
     │ 4. Config     │               │               │
     │──────────────>│               │               │
     │               │ 5. Cloud-init │               │
     │               │    disk       │               │
     │               │──────────────────────────────>│
     │               │               │               │
     │ 6. Start      │               │               │
     │──────────────>│               │               │
     │               │ 7. Boot       │               │
     │               │──────────────────────────────>│
     │               │               │               │
     │               │               │    8. Cloud-  │
     │               │               │       Init    │
     │               │               │       runs    │
     │               │               │               │
     │               │               │    9. VM      │
     │               │               │       Ready   │
     └───────────────┴───────────────┴───────────────┘
```

### Etapes detaillees

| Etape | Action | Duree |
|-------|--------|-------|
| 1 | Terraform demande le clonage | instant |
| 2 | Proxmox copie le disque du template | 10-30s |
| 3 | Nouveau disque cree pour la VM | inclus |
| 4 | Terraform configure la VM (CPU, RAM) | instant |
| 5 | Proxmox cree le disque cloud-init | instant |
| 6 | Terraform demarre la VM | instant |
| 7 | VM boot sur le disque | 10-20s |
| 8 | Cloud-init s'execute | 5-15s |
| 9 | VM prete avec IP et SSH | - |

### Verification dans Proxmox

**Voir la config cloud-init :**
```bash
# Sur le serveur Proxmox
qm cloudinit dump 110 user   # user-data
qm cloudinit dump 110 meta   # meta-data
qm cloudinit dump 110 network # network-config
```

**Exemple de sortie user-data :**
```yaml
#cloud-config
hostname: rancher-1
manage_etc_hosts: true
users:
  - name: root
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2E...
```

### Debug Cloud-Init dans la VM

```bash
# Se connecter a la VM
ssh root@192.168.1.110

# Voir les logs cloud-init
cat /var/log/cloud-init.log
cat /var/log/cloud-init-output.log

# Status cloud-init
cloud-init status

# Re-executer cloud-init (debug)
cloud-init clean
cloud-init init
```

---

## Resume

```
TEMPLATE                          CLOUD-INIT
   |                                  |
   | = Image de base                  | = Configuration au boot
   | = OS pre-installe                | = IP, DNS, SSH keys
   | = Cloud-init inclus              | = Utilisateurs
   | = Lecture seule                  | = Scripts custom
   |                                  |
   +---> CLONE ---> VM + CLOUD-INIT ---> VM PRETE
```

**Avantages combines :**
- Deploiement en secondes (pas d'installation)
- Configuration automatique (pas d'intervention manuelle)
- Reproductibilite (meme resultat a chaque fois)
- Scalabilite (10, 100, 1000 VMs identiques)
