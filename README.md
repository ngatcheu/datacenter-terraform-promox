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

- Terraform >= 1.12.2
- Proxmox VE >= 7.0
- Acces SSH root au serveur Proxmox
- Reseau configure (vmbr0)

## Structure du projet

```
src/
+-- main.tf                    # Definition des 10 VMs
+-- variables.tf               # Variables Terraform
+-- terraform.tfvars           # Valeurs des variables
+-- providers.tf               # Provider bpg/proxmox v0.50.0
+-- outputs.tf                 # Outputs (IDs, noms, IPs)
+-- template-init.tf           # Creation auto du template Rocky 9
+-- create-rocky9-template.sh  # Script de creation du template
```

## Configuration

### 1. Cloner le projet

```bash
git clone <repo-url>
cd datacenter-terraform-promox/src
```

### 2. Configurer les variables

Editez `terraform.tfvars` :

```hcl
# Connexion Proxmox
proxmox_node     = "devsecops-dojo"
proxmox_host     = "192.168.1.100"
proxmox_password = "votre-mot-de-passe"

# Reseau
ip_address_base = "192.168.1"
ip_start        = 110
gateway         = "192.168.1.1"
nameserver      = "192.168.1.1"
network_bridge  = "vmbr0"

# SSH
ssh_public_key = "ssh-rsa AAAAB3..."

# Stockage
vm_storage = "local-lvm"
```

### 3. Deployer

```bash
terraform init
terraform plan
terraform apply
```

Le template Rocky Linux 9 sera cree automatiquement via SSH si absent.

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

Le template cloud-init est cree automatiquement avec :

- **ID** : 9100
- **Nom** : rocky-9-cloud-template
- **Image** : Rocky-9-GenericCloud-Base
- **Config** : cloud-init, qemu-agent, virtio-scsi

Si le template existe deja (ID 9100), le script ne fait rien.

### Creation manuelle

```bash
# Sur le serveur Proxmox
bash /tmp/create-rocky9-template.sh
```

## Outputs

Apres `terraform apply` :

```bash
# Voir tous les outputs
terraform output

# Outputs disponibles
terraform output rancher_vm_names
terraform output rancher_vm_ids
terraform output payload_vm_names
terraform output payload_vm_ids
terraform output cicd_vm_name
terraform output cicd_vm_id
terraform output all_vm_names
terraform output all_vm_ids
terraform output deployment_summary
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

# Detruire tout
terraform destroy
```

## Depannage

### Template non trouve

```bash
# Verifier sur Proxmox
qm list | grep 9100

# Creer manuellement
bash /tmp/create-rocky9-template.sh
```

### VMs deja existantes

```bash
# Avec Terraform
terraform destroy

# Manuellement sur Proxmox
for i in {110..119}; do qm stop $i; qm destroy $i; done
```

### Erreur de connexion SSH

1. Verifier que la VM est demarree : `qm status <ID>`
2. Verifier cloud-init : Console Proxmox > VM > Console
3. Verifier la cle SSH dans terraform.tfvars

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
- **Documentation** : https://registry.terraform.io/providers/bpg/proxmox/latest/docs

## Prochaines etapes

1. Demarrer les VMs depuis Proxmox UI
2. Se connecter : `ssh root@192.168.1.110`
3. Installer RKE2 sur les nodes Rancher
4. Configurer Rancher Manager
5. Importer le cluster Payload dans Rancher
6. Deployer les workloads

## Licence

MIT
