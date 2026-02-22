# Datacenter Terraform Proxmox

Infrastructure as Code pour deployer un homelab Kubernetes sur Proxmox VE avec Terraform.

## Architecture

```
+-------------------------------------------------------------+
|                       Proxmox VE                            |
+-------------------------------------------------------------+
|                                                             |
|  CLUSTER RANCHER (Control Plane RKE2)                       |
|  +- rancher-1      -> 192.168.1.110 -> 2C/8GB/25G          |
|  +- rancher-2      -> 192.168.1.111 -> 2C/8GB/25G          |
|  +- rancher-3      -> 192.168.1.112 -> 2C/8GB/25G          |
|                                                             |
|  CLUSTER PAYLOAD (Workloads)                                |
|  +- payload-master-1 -> 192.168.1.113 -> 2C/4GB/25G        |
|  +- payload-master-2 -> 192.168.1.114 -> 2C/4GB/25G        |
|  +- payload-master-3 -> 192.168.1.115 -> 2C/4GB/25G        |
|  +- payload-worker-1 -> 192.168.1.116 -> 3C/8GB/25G        |
|  +- payload-worker-2 -> 192.168.1.117 -> 3C/8GB/25G        |
|  +- payload-worker-3 -> 192.168.1.118 -> 3C/8GB/25G        |
|                                                             |
|  SERVICES                                                   |
|  +- cicd             -> 192.168.1.119 -> 2C/8GB/25G        |
|                                                             |
+-------------------------------------------------------------+
```

## Ressources

| VM | Role | ID | IP | CPU | RAM | Disque |
|----|------|----|----|-----|-----|--------|
| rancher-1 | Control Plane | 110 | 192.168.1.110 | 2 | 8 GB | 25 GB |
| rancher-2 | Control Plane | 111 | 192.168.1.111 | 2 | 8 GB | 25 GB |
| rancher-3 | Control Plane | 112 | 192.168.1.112 | 2 | 8 GB | 25 GB |
| payload-master-1 | K8s Master | 113 | 192.168.1.113 | 2 | 4 GB | 25 GB |
| payload-master-2 | K8s Master | 114 | 192.168.1.114 | 2 | 4 GB | 25 GB |
| payload-master-3 | K8s Master | 115 | 192.168.1.115 | 2 | 4 GB | 25 GB |
| payload-worker-1 | K8s Worker | 116 | 192.168.1.116 | 3 | 8 GB | 25 GB |
| payload-worker-2 | K8s Worker | 117 | 192.168.1.117 | 3 | 8 GB | 25 GB |
| payload-worker-3 | K8s Worker | 118 | 192.168.1.118 | 3 | 8 GB | 25 GB |
| cicd | CI/CD Server | 119 | 192.168.1.119 | 2 | 8 GB | 25 GB |

**Total : 10 VMs - 22 vCPUs - 68 GB RAM - 250 GB Stockage**

## Prerequis

- Terraform >= 1.2.0
- Proxmox VE >= 7.0
- Acces SSH root au serveur Proxmox
- Reseau configure (vmbr0)

## Structure du projet

```
src/
+-- rancher/                      # Workspace independant - 3 VMs Control Plane
|   +-- main.tf                   # Template Rocky 9 + 3 VMs Rancher
|   +-- providers.tf              # Provider bpg/proxmox + null
|   +-- variables.tf              # Variables
|   +-- terraform.tfvars          # Valeurs
|   +-- outputs.tf                # Outputs
|   +-- create-rocky9-template.sh # Script creation template
|
+-- payload/                      # Workspace independant - 6 VMs Workloads
|   +-- main.tf                   # Template Rocky 9 + 3 Masters + 3 Workers
|   +-- providers.tf
|   +-- variables.tf
|   +-- terraform.tfvars
|   +-- outputs.tf
|   +-- create-rocky9-template.sh
|
+-- cicd/                         # Workspace independant - 1 VM CI/CD
    +-- main.tf                   # Template Rocky 9 + VM CI/CD
    +-- providers.tf
    +-- variables.tf
    +-- terraform.tfvars
    +-- outputs.tf
    +-- create-rocky9-template.sh
```

Chaque workspace est **completement autonome** : il cree le template Rocky 9 si absent, puis deploie ses VMs.

## Deploiement

### 1. Configurer les variables

Dans chaque dossier, editez `terraform.tfvars` :

```hcl
proxmox_host     = "192.168.1.100"
proxmox_password = "votre-mot-de-passe"
proxmox_node     = "devsecops-dojo"
ssh_public_key   = "ssh-rsa AAAAB3..."
```

### 2. Deployer workspace par workspace

```bash
# Cluster Rancher (Control Plane)
cd src/rancher
terraform init
terraform apply

# Cluster Payload (Masters + Workers)
cd ../payload
terraform init
terraform apply

# Serveur CI/CD
cd ../cicd
terraform init
terraform apply
```

### Apres le deploiement

```bash
# Verifier que toutes les VMs sont accessibles
for i in {110..119}; do ping -c 1 192.168.1.$i; done

# Se connecter a la premiere VM Rancher
ssh root@192.168.1.110
```

## Variables disponibles

### Proxmox

| Variable | Description | Default |
|----------|-------------|---------|
| `proxmox_node` | Nom du noeud Proxmox | `devsecops-dojo` |
| `proxmox_host` | IP du serveur Proxmox | `192.168.1.100` |
| `proxmox_password` | Mot de passe root | - |
| `vm_id_start` | ID de depart des VMs | `110` |

### Reseau

| Variable | Description | Default |
|----------|-------------|---------|
| `network_bridge` | Bridge reseau | `vmbr0` |
| `ip_address_base` | Base IP (ex: 192.168.1) | `192.168.1` |
| `ip_start` | Premiere IP | `110` |
| `gateway` | Passerelle | `192.168.1.1` |
| `nameserver` | Serveur DNS | `192.168.1.1` |

### Ressources VMs

| Variable | Description | Default |
|----------|-------------|---------|
| `rancher_cpu_cores` | CPU Rancher | `2` |
| `rancher_memory` | RAM Rancher (MB) | `8192` |
| `payload_master_cpu_cores` | CPU Payload Masters | `2` |
| `payload_master_memory` | RAM Payload Masters (MB) | `4096` |
| `payload_worker_cpu_cores` | CPU Payload Workers | `3` |
| `payload_worker_memory` | RAM Payload Workers (MB) | `8192` |
| `cicd_cpu_cores` | CPU CI/CD | `2` |
| `cicd_memory` | RAM CI/CD (MB) | `8192` |

## Template Rocky Linux 9

Le template cloud-init est cree automatiquement au premier `terraform apply` de chaque workspace via SSH sur le Proxmox.

- **ID** : 9100
- **Nom** : rocky-9-cloud-template
- **Image** : Rocky-9-GenericCloud-Base
- **Config** : cloud-init, qemu-agent, virtio-scsi

Si le template existe deja (ID 9100), le script ne fait rien.

### Creation manuelle sur le serveur Proxmox

```bash
bash /tmp/create-rocky9-template.sh
```

## Outputs

Apres `terraform apply` dans chaque workspace :

```bash
# Rancher
cd src/rancher
terraform output vm_names
terraform output vm_ids

# Payload
cd src/payload
terraform output vm_names
terraform output vm_ids

# CI/CD
cd src/cicd
terraform output vm_name
terraform output vm_id
terraform output vm_ip
```

## Commandes utiles

```bash
# Initialiser
terraform init

# Planifier
terraform plan

# Appliquer
terraform apply

# Appliquer sans confirmation
terraform apply -auto-approve

# Voir l'etat
terraform show

# Detruire une VM specifique
terraform destroy -target=proxmox_virtual_environment_vm.cicd

# Detruire tout le workspace
terraform destroy
```

## Depannage

### Template non trouve

```bash
# Verifier sur Proxmox
qm list | grep 9100

# Creer manuellement
scp src/cicd/create-rocky9-template.sh root@192.168.1.100:/tmp/
ssh root@192.168.1.100 bash /tmp/create-rocky9-template.sh
```

### VMs deja existantes

```bash
# Manuellement sur Proxmox
for i in {110..119}; do qm stop $i; qm destroy $i; done
```

### Erreur provider Proxmox

```bash
# Reinitialiser les providers
rm -rf .terraform .terraform.lock.hcl
terraform init
```

## Securite

- `terraform.tfvars` contient des secrets - **ne pas committer**
- `terraform.tfstate` contient l'etat complet - utiliser un backend distant en production
- Le dossier `.terraform/` est genere automatiquement

## Provider

- **Provider** : [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest)
- **Version** : 0.50.0

## Prochaines etapes

1. Demarrer les VMs depuis Proxmox UI
2. Se connecter : `ssh root@192.168.1.110`
3. Installer RKE2 sur les nodes Rancher
4. Configurer Rancher Manager
5. Importer le cluster Payload dans Rancher
6. Deployer les workloads

## Licence

MIT
