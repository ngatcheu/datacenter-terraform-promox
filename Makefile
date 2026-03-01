.PHONY: help \
        init plan apply destroy fmt validate \
        cicd-init cicd-fmt cicd-validate cicd-plan cicd-apply cicd-destroy \
        rancher-init rancher-fmt rancher-validate rancher-plan rancher-apply rancher-destroy \
        payload-init payload-fmt payload-validate payload-plan payload-apply payload-destroy

CICD_DIR    := src/cicd
RANCHER_DIR := src/rancher
PAYLOAD_DIR := src/payload

TF := terraform -chdir

help:
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "  Globaux (les 3 modules) :"
	@echo "    init       fmt       validate"
	@echo "    plan       apply     destroy"
	@echo ""
	@echo "  Module cicd    (GitLab + OpenLDAP) :"
	@echo "    cicd-init  cicd-fmt  cicd-validate"
	@echo "    cicd-plan  cicd-apply  cicd-destroy"
	@echo ""
	@echo "  Module rancher (Control Plane K8s) :"
	@echo "    rancher-init  rancher-fmt  rancher-validate"
	@echo "    rancher-plan  rancher-apply  rancher-destroy"
	@echo ""
	@echo "  Module payload (Masters + Workers) :"
	@echo "    payload-init  payload-fmt  payload-validate"
	@echo "    payload-plan  payload-apply  payload-destroy"
	@echo ""

# ─── GLOBAUX ─────────────────────────────────────────────────────────────────

init:     cicd-init     rancher-init     payload-init
fmt:      cicd-fmt      rancher-fmt      payload-fmt
validate: cicd-validate rancher-validate payload-validate
plan:     cicd-plan     rancher-plan     payload-plan
apply:    cicd-apply    rancher-apply    payload-apply
destroy:  payload-destroy rancher-destroy cicd-destroy

# ─── MODULE : cicd ───────────────────────────────────────────────────────────

cicd-init:
	$(TF)=$(CICD_DIR) init

cicd-fmt:
	$(TF)=$(CICD_DIR) fmt

cicd-validate:
	$(TF)=$(CICD_DIR) validate

cicd-plan:
	$(TF)=$(CICD_DIR) plan

cicd-apply:
	$(TF)=$(CICD_DIR) apply -auto-approve

cicd-destroy:
	$(TF)=$(CICD_DIR) destroy -auto-approve

# ─── MODULE : rancher ────────────────────────────────────────────────────────

rancher-init:
	$(TF)=$(RANCHER_DIR) init

rancher-fmt:
	$(TF)=$(RANCHER_DIR) fmt

rancher-validate:
	$(TF)=$(RANCHER_DIR) validate

rancher-plan:
	$(TF)=$(RANCHER_DIR) plan

rancher-apply:
	$(TF)=$(RANCHER_DIR) apply -auto-approve

rancher-destroy:
	$(TF)=$(RANCHER_DIR) destroy -auto-approve

# ─── MODULE : payload ────────────────────────────────────────────────────────

payload-init:
	$(TF)=$(PAYLOAD_DIR) init

payload-fmt:
	$(TF)=$(PAYLOAD_DIR) fmt

payload-validate:
	$(TF)=$(PAYLOAD_DIR) validate

payload-plan:
	$(TF)=$(PAYLOAD_DIR) plan

payload-apply:
	$(TF)=$(PAYLOAD_DIR) apply -auto-approve

payload-destroy:
	$(TF)=$(PAYLOAD_DIR) destroy -auto-approve
