SHELL := /bin/bash

.PHONY: prerequisites cluster-create cluster-destroy validate \
	platform-init platform-plan platform-apply platform-validate platform-destroy \
	application-validate routing-validate

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

application-validate:
	./scripts/application-validate

routing-validate:
	./scripts/routing-validate
