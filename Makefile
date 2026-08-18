SHELL := /bin/bash

.PHONY: prerequisites cluster-create cluster-destroy validate \
	platform-init platform-plan platform-apply platform-validate platform-destroy \
	applications-adopt applications-init applications-plan applications-apply applications-destroy \
	application-validate routing-validate recommendation-build-load \
	recommendation-validate observability-validate observability-soak

prerequisites:
	./scripts/prerequisites

cluster-create: prerequisites
	./scripts/cluster-create

cluster-destroy:
	./scripts/cluster-destroy

validate:
	./scripts/validate

platform-init:
	terraform -chdir=terraform/platform init

platform-plan:
	terraform -chdir=terraform/platform plan

platform-apply:
	terraform -chdir=terraform/platform apply

platform-validate:
	./scripts/platform-validate

platform-destroy:
	terraform -chdir=terraform/platform destroy

applications-adopt:
	./scripts/applications-adopt

applications-init:
	terraform -chdir=terraform/applications init

applications-plan:
	terraform -chdir=terraform/applications plan

applications-apply:
	terraform -chdir=terraform/applications apply

applications-destroy:
	terraform -chdir=terraform/applications destroy

application-validate:
	./scripts/application-validate

routing-validate:
	./scripts/routing-validate

recommendation-build-load:
	./scripts/recommendation-build-load

recommendation-validate:
	./scripts/recommendation-validate

observability-validate:
	./scripts/observability-validate

observability-soak:
	OBSERVABILITY_SOAK_SECONDS=900 ./scripts/observability-validate
