# OpenTelemetry Demo - Local Kubernetes Platform

Local counterpart to the AWS EKS OpenTelemetry Demo platform.

This repository creates a disposable local Kubernetes cluster while preserving
the ownership model used by the AWS implementation:

- local cluster and platform bootstrapping belong here;
- application source belongs in `otel-demo-apps`;
- Kubernetes desired state belongs in `otel-demo-gitops`;
- Argo CD, rather than lifecycle scripts or Terraform, owns application
  workloads.

## Current milestone

Milestone 5 deploys and validates the OpenTelemetry Demo through Argo CD:

- Terraform registers the local Argo CD Application;
- Argo CD reconciles the Helm chart and local GitOps values;
- the Gateway is accepted and programmed;
- all application deployments are healthy;
- the frontend responds successfully through `frontend-proxy`.

The optional `flagd-ui` editor sidecar is disabled only in the local overlay
because the chart's 2.1.3 image grows until it is OOM-killed on this arm64
environment. The `flagd` evaluation service remains enabled.

## Prerequisites

- Docker-compatible runtime
- kind
- kubectl
- Helm
- Terraform
- Make

Check the workstation:

```bash
make prerequisites
```

## Cluster lifecycle

Create the cluster:

```bash
make cluster-create
```

Validate the cluster:

```bash
make validate
```

Delete the cluster:

```bash
make cluster-destroy
```

## Context isolation

The cluster is named `otel-demo-local` and its Kubernetes context is
`kind-otel-demo-local`.

Its kubeconfig is written to:

```text
.state/kubeconfig
```

Lifecycle commands always pass this path explicitly. They do not change the
current context in the default kubeconfig, which may still point to AWS EKS.

To inspect the local cluster manually:

```bash
kubectl --kubeconfig .state/kubeconfig get nodes
```

## Local networking

The kind control-plane maps host ports 80 and 443 to fixed NodePorts used by
NGINX Gateway Fabric:

| Workstation | kind NodePort | Gateway listener |
|---|---|---|
| 80 | 31437 | HTTP 80 |
| 443 | 30478 | HTTPS 443 |

The GitOps repository now provides the Gateway resource, which causes NGINX
Gateway Fabric to create the local data plane.

## Platform lifecycle

Initialize and review the Terraform plan:

```bash
make platform-init
make platform-plan
```

Install the platform:

```bash
make platform-apply
make platform-validate
```

Remove the platform before deleting the cluster:

```bash
make platform-destroy
make cluster-destroy
```

Terraform owns platform services. Argo CD owns the registered application and
its workloads.

## Application validation

Validate Argo CD, the Gateway, every deployment, and the local Recommendation
image source:

```bash
make application-validate
```

For a temporary direct frontend test:

```bash
kubectl \
  --kubeconfig .state/kubeconfig \
  port-forward \
  --namespace opentelemetry-demo \
  service/frontend-proxy \
  18080:8080
```

Then open `http://localhost:18080`.

See `docs/TROUBLESHOOTING.md` for the `flagd-ui` investigation and the local
fallback decision.

## Why Gateway API instead of ingress-nginx

The original local design selected the Kubernetes community's
`ingress-nginx`. That project was retired in March 2026 and no longer receives
security updates.

The local platform therefore uses maintained NGINX Gateway Fabric and the
Kubernetes Gateway API. This preserves NGINX as the local data plane while
teaching the current replacement for the legacy Ingress API.
