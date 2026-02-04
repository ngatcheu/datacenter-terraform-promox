# Notes du Speaker - Proxmox VE + Terraform

## Informations Générales
- **Sujet** : Mettre en place votre Data Center en local
- **Partie** : I - Proxmox VE + Terraform
- **Speaker** : NGATCHEU Fabrice - Ingenieur DevOps
- **Communaute** : DevSecOps-dojo

---

## SLIDE 1 - Page de Titre

**Points a aborder :**
- Se presenter brievement
- Annoncer le plan de la presentation (5 parties)
- Preciser que c'est la Partie I d'une serie

**Transition :** "Commencons par comprendre ce qu'est Proxmox VE..."

---

## SLIDE 2 - Introduction : Definition Proxmox VE

**Points cles a expliquer :**

1. **Definition**
   - Plateforme de virtualisation open source
   - Basee sur Debian Linux
   - Alternative gratuite a VMware vSphere

2. **5 Caracteristiques principales :**
   - **VMs (KVM/QEMU)** : Virtualisation complete, performances natives
   - **Conteneurs LXC** : Plus legers que les VMs, demarrage rapide
   - **Interface web** : Pas besoin de client lourd, accessible partout
   - **Stockage Ceph** : Stockage distribue, haute disponibilite
   - **Backup integre** : Proxmox Backup Server avec deduplication

**Exemple concret :**
> "Sur mon homelab, j'utilise Proxmox pour heberger 10 VMs qui forment mon cluster Kubernetes"

**Transition :** "Maintenant, voyons pourquoi on a besoin d'automatiser..."

---

## SLIDE 3 - Contexte et Problematique

**Contexte - Situations reelles :**

| Situation | Probleme |
|-----------|----------|
| Tests/Dev | Besoin de VMs rapidement, jetables |
| Multi-env | Dev, staging, prod = 3x le travail |
| Homelab | Experimentation, apprentissage |
| Entreprise | Infrastructure critique a gerer |

**Problematiques a poser comme questions :**
- "Qui a deja recree une VM manuellement parce qu'il avait oublie comment la configurer ?"
- "Qui a deja eu une config differente entre dev et prod ?"

**Les 5 defis :**
1. **Reproductibilite** : Meme config a chaque fois
2. **Derive de configuration** : Eviter les modifications manuelles non tracees
3. **Documentation** : Le code EST la documentation
4. **Versionnement** : Git pour l'infra
5. **Industrialisation** : CI/CD pour l'infrastructure

**Reponse :** Infrastructure as Code avec Terraform

**Transition :** "Avant de choisir Proxmox, comparons les solutions du marche..."

---

## SLIDE 4-5 - Outils du Marche (Comparatif)

**Tableau comparatif - Points a souligner :**

| Solution | Avantage principal | Inconvenient |
|----------|-------------------|--------------|
| **Nutanix AHV** | HCI tout-en-un | Cout eleve |
| **Proxmox VE** | Gratuit, flexible | Demande expertise |
| **VMware vSphere** | Leader, mature | Licences couteuses (Broadcom) |
| **Hyper-V** | Integre Windows | Ecosysteme limite |

**Pourquoi Proxmox ?**
- Open source = gratuit
- KVM = performances natives
- Communaute active
- Parfait pour homelab ET entreprise
- ROI eleve

**Anecdote possible :**
> "Avec le rachat de VMware par Broadcom, beaucoup d'entreprises migrent vers Proxmox"

**Transition :** "Voyons maintenant l'architecture technique..."

---

## SLIDE 6 - Architecture Proxmox

**Schema a expliquer :**

```
User Tools (qm, pct, pvesm, pveum...)
         |
    Services (pveproxy, pvedaemon, pve-cluster...)
         |
   +-----+-----+
   |           |
  VMs      Containers
(QEMU)      (LXC)
   |           |
  KVM      AppArmor/cgroups
         |
    Linux Kernel
```

**Points techniques :**
- **qm** : Gestion des VMs
- **pct** : Gestion des conteneurs
- **pvesm** : Gestion du stockage
- **KVM** : Hyperviseur integre au kernel Linux
- **QEMU** : Emulation materielle

**Transition :** "Maintenant, ajoutons Terraform a l'equation..."

---

## SLIDE 7 - Architecture Proxmox + Terraform

**Schema de l'infrastructure :**

```
Terraform (Local Station)
    |
    | API REST (port 8006)
    v
Proxmox VE (192.168.1.100/24)
    |
    +-- vmbr0 (Bridge reseau)
         |
         +-- 3 VMs Rancher (Control Plane Kubernetes)
         +-- 6 VMs Payload (3 Masters + 3 Workers)
         +-- 1 VM CI/CD
         |
    nic3 -- LAN -- Gateway (192.168.1.1)
```

**Points a expliquer :**
- Terraform communique via l'API Proxmox
- Provider utilise : `bpg/proxmox` (meilleur que telmate)
- Toutes les VMs sur le meme bridge reseau
- IPs statiques attribuees via cloud-init

**Transition :** "Passons a la demonstration concrete..."

---

## SLIDE 8 - Demo : Provisioning

**Structure des fichiers a montrer :**

```
promox-terraform/
├── providers.tf          # Config Terraform + Proxmox
├── variables.tf          # Variables parametrables
├── main.tf               # Definition des 10 VMs
├── outputs.tf            # Affichage post-deploiement
├── template-init.tf      # Creation auto du template
├── create-rocky9-template.sh  # Script bash
└── terraform.tfvars      # Valeurs (NE PAS COMMITER!)
```

**Demonstration en direct :**

1. **Montrer providers.tf**
```hcl
terraform {
  required_version = ">= 1.12.2"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.50.0"
    }
  }
}
```

2. **Montrer une ressource VM (main.tf)**
```hcl
resource "proxmox_virtual_environment_vm" "rancher_1" {
  name      = "rancher-1"
  node_name = var.proxmox_node
  vm_id     = var.vm_id_start

  clone {
    vm_id = 9100  # Template Rocky Linux 9
    full  = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 8192  # 8 GB
  }
}
```

3. **Executer les commandes**
```bash
terraform init     # Telecharge le provider
terraform plan     # Montre ce qui va etre cree
terraform apply    # Cree les 10 VMs
```

4. **Montrer le resultat dans Proxmox UI**

**Ressources deployees :**
| Type | Nombre | CPU | RAM | IP Range |
|------|--------|-----|-----|----------|
| Rancher | 3 | 2 | 8 GB | .110-.112 |
| Payload Masters | 3 | 2 | 4 GB | .113-.115 |
| Payload Workers | 3 | 3 | 8 GB | .116-.118 |
| CI/CD | 1 | 2 | 8 GB | .119 |

**Transition :** "Pour conclure, rappelons les bonnes pratiques..."

---

## SLIDE 9 - Conclusion et Ressources

**Bonnes pratiques IaC :**

1. **Versionner avec Git**
   - Tout le code Terraform dans un repo
   - Branches pour dev/prod

2. **Securite des secrets**
   - Ne JAMAIS commiter `terraform.tfvars`
   - Utiliser des variables d'environnement ou Vault

3. **State Terraform**
   - En local pour homelab
   - Backend distant (S3, Terraform Cloud) en prod

4. **Organisation du code**
   - 1 fichier = 1 responsabilite
   - Utiliser des modules pour la reutilisation

**Ressources a partager :**

| Ressource | Lien |
|-----------|------|
| Code source | github.com/devsecops-dojo/promox-terraform |
| Provider Terraform | registry.terraform.io/providers/bpg/proxmox |
| Docs Proxmox | pve.proxmox.com/pve-docs |
| Discord | discord.gg/MXt7zmTB4 |

**Questions/Reponses :**
- Preparer des reponses pour les questions frequentes
- "Et pour la haute disponibilite ?" -> Proxmox Cluster
- "Et les backups ?" -> Proxmox Backup Server
- "Pourquoi pas Ansible ?" -> Terraform pour provisionner, Ansible pour configurer

---

## Checklist Pre-Presentation

- [ ] Proxmox accessible (https://192.168.1.100:8006)
- [ ] Terraform installe et configure
- [ ] Template Rocky 9 cree (ID 9100)
- [ ] Code pret a etre execute
- [ ] Terminal ouvert avec le bon repertoire
- [ ] Interface Proxmox ouverte dans le navigateur

---

## Timing Suggere

| Section | Duree |
|---------|-------|
| Introduction | 5 min |
| Contexte/Problematique | 5 min |
| Comparatif outils | 5 min |
| Architecture | 10 min |
| Demo | 15 min |
| Conclusion + Q&A | 10 min |
| **Total** | **50 min** |

---

## Contact

- **GitHub** : github.com/devsecops-dojo
- **Discord** : discord.gg/MXt7zmTB4
- **LinkedIn** : DevSecOps Dojo Group
