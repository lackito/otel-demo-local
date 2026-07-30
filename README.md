# OpenTelemetry Demo - Local Kubernetes Platform

Local counterpart to the AWS EKS OpenTelemetry Demo platform.

This repository creates a disposable local Kubernetes cluster while preserving
the ownership model used by the AWS implementation:

- local cluster and platform bootstrapping belong here;
- local Kubernetes desired state and Argo CD registration belong here;
- application source belongs in `otel-demo-apps`;
- Argo CD, rather than lifecycle scripts or Terraform, owns application
  workloads.

## Current milestone

Milestone 8 stabilizes and validates the local observability backends:

- Jaeger retains 2,000 in-memory traces with a 512 MiB limit;
- Prometheus has a 512 MiB limit;
- the OpenTelemetry Collector has a 300 MiB limit;
- Grafana has a 384 MiB limit and 128 MiB sidecar limits;
- validation queries real metrics, traces, health, and datasources;
- a 15-minute soak detects backend restarts and OOMs.

The optional `flagd-ui` editor sidecar is disabled only in the local overlay
because the chart's 2.1.3 image grows until it is OOM-killed on this arm64
environment. The `flagd` evaluation service remains enabled.

## How local GitOps works

Local Argo CD watches this repository:

```text
https://github.com/lackito/otel-demo-local.git
```

The repository has separate areas of responsibility:

```text
otel-demo-local
├── kind/ and terraform/
│   └── Create the cluster, install platform components, and register Argo CD
│
├── config/ and .github/workflows/
│   └── Select, build, and publish a local Recommendation release
│
└── gitops/otel-demo/
    ├── values.yaml
    └── manifests/
        ├── gateway.yaml
        └── httproute.yaml
            └── Desired state continuously monitored by local Argo CD
```

The control flow is:

```text
Commit and push a change to otel-demo-local/main
                       |
                       v
Local Argo CD reads otel-demo-local from GitHub
                       |
                       v
Argo combines the upstream OpenTelemetry Demo Helm chart
with gitops/otel-demo/values.yaml and manifests/
                       |
                       v
Argo reconciles the local kind cluster
```

Terraform installs Argo CD and registers the Application, but it does not
manage the OpenTelemetry Demo workloads. After registration, Argo CD owns
those workloads.

Argo CD runs inside Kubernetes and cannot read uncommitted files from the
workstation. Desired-state changes must be committed and pushed before Argo
can see them. The GitHub repository must either be public or configured in
Argo CD with private-repository credentials.

`otel-demo-gitops` is not part of this local flow. It is reserved for the AWS
EKS environment.

## Local CI workflow

The local release workflow is owned entirely by this repository:

```text
config/recommendation-source-ref
                |
                v
.github/workflows/recommendation-local-release.yml
                |
                +-- checks out that exact otel-demo-apps commit
                +-- builds linux/arm64 with GitHub Actions
                +-- publishes an immutable image to GHCR
                +-- updates gitops/otel-demo/values.yaml
                |
                v
Local Argo CD detects the generated values commit
                |
                v
kind pulls and deploys the GHCR image
```

To select a new Recommendation version, put its full 40-character commit SHA
in `config/recommendation-source-ref`, then commit and push that change to
`otel-demo-local/main`. The selected commit must exist on GitHub so the runner
can check it out.

This workflow never updates `otel-demo-gitops`, pushes to Amazon ECR, or
changes the AWS environment.

## Prerequisites

- Docker-compatible runtime
- kind
- kubectl
- Helm
- Terraform
- Make
- anonymous read access to `lackito/otel-demo-local` from Argo CD, or
  separately configured private-repository credentials
- a public `ghcr.io/lackito/otel-demo-local-recommendation` package for
  anonymous image pulls from kind

Check the workstation:

```bash
make prerequisites
```

## Fresh cluster order

After the local CI workflow has published the GHCR image and updated the
values file, a brand-new cluster uses this order:

```bash
make cluster-create
make platform-init
make platform-plan
make platform-apply
make application-validate
make recommendation-validate
```

Argo CD reads the GHCR image reference from Git and kind pulls the image. No
workstation-local image survives or is required.

Direct kind loading remains available as the faster development loop. When
using that mode on a new cluster, run `make recommendation-build-load` after
`make cluster-create` and before `make platform-apply`.

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

This repository's `gitops/otel-demo` directory provides the Gateway resource,
which causes NGINX Gateway Fabric to create the local data plane. Its
`HTTPRoute` exposes the demo at `http://otel-demo.localhost`.

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

Validate the Gateway, route attachment, backend references, successful demo
response, and hostname isolation:

```bash
make routing-validate
```

### Fast development: direct kind loading

Build Recommendation from the sibling `otel-demo-apps` repository and load it
into kind:

```bash
make recommendation-build-load
```

This command does not update Git, GitHub, or Argo CD. It only:

1. reads the current commit from the sibling `otel-demo-apps` repository;
2. builds `otel-demo/recommendation:local-<short-commit>`;
3. loads that image into the kind node.

To deploy a new Recommendation build:

1. commit the Recommendation source change in `otel-demo-apps` so it has a new
   Git SHA; the commit can remain on a local development branch;
2. run `make recommendation-build-load`;
3. copy the printed tag into `gitops/otel-demo/values.yaml`;
4. commit and push the `otel-demo-local` values change;
5. let Argo CD detect the commit and roll out the new image;
6. run:

```bash
make recommendation-validate
```

This manual loop remains useful while editing code because it avoids waiting
for a remote build.

### Repeatable delivery: local CI and GHCR

To publish and deploy through local CI:

1. push the desired `otel-demo-apps` commit to GitHub;
2. copy its full SHA into `config/recommendation-source-ref`;
3. commit and push that file to `otel-demo-local/main`;
4. wait for `Release Recommendation to local Kubernetes`;
5. let its generated values commit reach Argo CD;
6. run `make recommendation-validate`.

The workflow uses the repository `GITHUB_TOKEN`; it requires `contents: write`
and `packages: write`. No AWS credentials or cross-repository write token are
used.

Before the first run, confirm **Settings → Actions → General → Workflow
permissions** allows read and write access.

The first workflow run creates the GHCR package. New packages may initially be
private, so the workflow deliberately stops before changing Git desired state
if anonymous pull access fails. Make
`otel-demo-local-recommendation` public in its GitHub package settings, then
rerun the failed workflow. Later source-reference changes are fully automatic.

Validate the observability backends and real telemetry data:

```bash
make observability-validate
```

Run the 15-minute stability test:

```bash
make observability-soak
```

Open the demo:

```text
http://otel-demo.localhost
```

Open the observability UIs:

```text
http://otel-demo.localhost/grafana/
http://otel-demo.localhost/jaeger/ui/
```

For direct service debugging, a temporary port-forward can still bypass the
Gateway:

```bash
kubectl --kubeconfig .state/kubeconfig \
  port-forward --namespace opentelemetry-demo \
  service/frontend-proxy 18080:8080
```

See `docs/TROUBLESHOOTING.md` for the `flagd-ui` investigation and the local
fallback decision.

See `docs/IMAGE_WORKFLOW.md` for the direct-load, local-registry, and GHCR
tradeoffs and progression.

## Why Gateway API instead of ingress-nginx

The original local design selected the Kubernetes community's
`ingress-nginx`. That project was retired in March 2026 and no longer receives
security updates.

The local platform therefore uses maintained NGINX Gateway Fabric and the
Kubernetes Gateway API. This preserves NGINX as the local data plane while
teaching the current replacement for the legacy Ingress API.
