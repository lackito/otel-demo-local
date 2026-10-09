# Local Platform Architecture

[Overview](../README.md) · [Operations](OPERATIONS.md) · [Troubleshooting](TROUBLESHOOTING.md)

## Ownership

| Component | Owner |
|---|---|
| kind cluster and host port mappings | This repository's cluster scripts and `kind/cluster.yaml` |
| Gateway API CRDs, NGINX Gateway Fabric, Argo CD | `terraform/platform` |
| Argo CD Application registration | `terraform/applications` using `kubernetes_manifest` |
| Local Helm values, Gateway, and HTTPRoute | `otel-demo-gitops-local` |
| Application source and release workflows | `otel-demo-apps` |
| Application workload reconciliation | Argo CD |

Platform installation and Application registration use separate local
Terraform states so Argo CD's CRDs exist before registration is planned.
The GitOps repository retains a declarative Application YAML copy at
`argocd/applications/otel-demo.yaml`; Terraform registers the Application.

Argo CD combines the upstream OpenTelemetry Demo Helm chart with local values
and routing manifests. It reads pushed commits from GitHub, not files on the
workstation. AWS and local environments use separate desired-state repositories.

## Delivery choices

The durable local release path is implemented in `otel-demo-apps`:

```text
Push Recommendation changes to local branch
    → GitHub Actions builds linux/arm64 with the triggering commit tag
    → GHCR publishes the image
    → CI updates otel-demo-gitops-local/main
    → Argo CD reconciles kind workloads
```

| Method | Use | Tradeoff |
|---|---|---|
| GHCR and GitHub Actions | Repeatable releases and fresh clusters | Requires CI publishing credentials, public package access, and network connectivity; arm64 emulation can slow builds |
| Direct kind loading | Fast development and native-architecture builds | Images live in the current node and must be reloaded after recreation; Git alone cannot reproduce them |
| Connected local registry | Optional networking exercise, not the implemented primary path | Adds registry lifecycle and trust configuration; remains unavailable to GitHub-hosted runners without additional connectivity |

Direct loading builds from the sibling application checkout and tags the image
with its Git revision. Loading alone does not change desired state: update and
push the GitOps repository/tag, then let Argo CD deploy it. The operations guide
contains the commands for both supported paths.

## Networking and context

Terraform installs the NGINX Gateway Fabric control plane. The GitOps-owned
Gateway creates its data plane, and HTTPRoute attaches the frontend service.
The configured browser route uses HTTP at `http://otel-demo.localhost`.

| Host port | kind NodePort |
|---|---|
| 80 | 31437 |
| 443 | 30478 |

Port mappings alone do not configure TLS. The current Gateway manifest has
an HTTP listener; HTTPS requires additional listener and certificate setup.
Gateway API expresses local traffic routing while the AWS counterpart uses
Ingress and AWS Load Balancer Controller annotations.

The cluster context is `kind-otel-demo-local` in `~/.kube/config`. Repository
scripts and Terraform target it explicitly; interactive commands should select
it or use `--context` to avoid acting on a different cluster.

## AWS and local comparison

| Responsibility | AWS | Local |
|---|---|---|
| Cluster and network | EKS, VPC, subnets, routes, NAT | kind, Docker network, host port mappings |
| Traffic controller | AWS Load Balancer Controller | NGINX Gateway Fabric |
| Route and entry point | Ingress, ALB DNS | Gateway/HTTPRoute, `otel-demo.localhost` |
| Workload AWS identity | IRSA with AWS OIDC | Not required for the local workload path |
| Terraform state | S3 | Local files |
| Terraform stages | Bootstrap, infrastructure, platform, applications | Platform, applications; scripts create kind |
| Application registration | `kubernetes_manifest` | `kubernetes_manifest` |
| Source branch and registry | `otel-demo-apps/main`, ECR | `otel-demo-apps/local`, GHCR |
| Desired state | `otel-demo-gitops` | `otel-demo-gitops-local` |
| Workload owner | Argo CD | Argo CD |
| Feature flags | `flagd` and editor sidecar | `flagd`; editor sidecar disabled |

The local environment preserves ownership and delivery boundaries without
recreating AWS networking internals. Its release workflow does not publish to
ECR or update the AWS GitOps repository.

## Observability and resource limits

Demo services send OTLP telemetry to the Collector; traces go to Jaeger and
metrics to Prometheus. Grafana exposes the configured datasources. The load
generator exercises the application continuously.

The local overlay configures Jaeger to retain 2,000 in-memory traces with a
512 MiB limit. Prometheus has a 512 MiB limit, the Collector 300 MiB, and Grafana
384 MiB with 128 MiB sidecar limits. Storage is ephemeral; these settings are
local operating choices rather than guarantees for arbitrary loads.

Validation queries actual metrics and traces as well as Kubernetes health.
The soak check catches restarts and pod replacements over 15 minutes. The
optional `flagd-ui` editor is disabled following an arm64 OOM investigation;
feature-flag evaluation remains enabled. See [Troubleshooting](TROUBLESHOOTING.md)
for the evidence and [Operations](OPERATIONS.md) for validation commands.
