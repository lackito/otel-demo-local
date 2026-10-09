# OpenTelemetry Demo on Local Kubernetes

A platform engineering lab that deploys the upstream OpenTelemetry Demo on
**kind** using **Terraform, Helm, Argo CD, and GitOps**. It provides a local
counterpart to the AWS EKS implementation.

The engineering work focuses on platform provisioning, application delivery,
routing, and validation. The demo application comes from OpenTelemetry.

## How it works

```text
Application commit → GitHub Actions → GHCR image
                           ↓
                    GitOps values commit
                           ↓
                        Argo CD → kind workloads
```

Terraform installs Gateway API, NGINX Gateway Fabric, and Argo CD, then
registers the Application in a separate stage. Argo CD owns the workloads.
Direct image loading into kind is also available for development.

## Start here

| Goal | Guide |
|---|---|
| Resume a test run or build a fresh environment | [Operations](docs/OPERATIONS.md) |
| Understand ownership, delivery choices, and AWS differences | [Architecture](docs/ARCHITECTURE.md) |
| Diagnose a failed check or known limitation | [Troubleshooting](docs/TROUBLESHOOTING.md) |

The operations guide covers prerequisites, deployment, validation, image
updates, browser access, and teardown in execution order.

## What is checked

[CI](.github/workflows/ci.yml) checks Terraform configuration and formatting,
YAML and shell syntax, and GitHub Actions workflows. Runtime validation checks
cluster readiness, routing, application delivery, and real metrics and traces.
A 15-minute observability soak checks for restarts and pod replacement.

The local GHCR release currently builds for arm64. Telemetry storage is
ephemeral, and the optional `flagd-ui` editor is disabled after an arm64 OOM
investigation. See the guides for details; successful static CI does not prove
that a cluster is running.

## Related repositories

- [otel-demo-apps](https://github.com/lackito/otel-demo-apps): application source and release workflows.
- [otel-demo-gitops-local](https://github.com/lackito/otel-demo-gitops-local): local values and routing manifests.
- [otel-demo-infra-aws](https://github.com/lackito/otel-demo-infra-aws): AWS infrastructure and platform.
- [otel-demo-gitops](https://github.com/lackito/otel-demo-gitops): AWS desired state.
