# OpenTelemetry Demo - Local Kubernetes Platform

Local counterpart to the AWS EKS OpenTelemetry Demo platform.

This repository creates a disposable local Kubernetes cluster while preserving
the ownership model used by the AWS implementation:

- local cluster and platform bootstrapping belong here;
- local Argo CD registration belongs here;
- local Kubernetes desired state belongs in `otel-demo-gitops-local`;
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

For a side-by-side view of the complete AWS and local delivery paths, see
[`docs/PROJECT_WALKTHROUGH.md`](docs/PROJECT_WALKTHROUGH.md).

## How local GitOps works

Local Argo CD watches the dedicated GitOps repository:

```text
https://github.com/lackito/otel-demo-gitops-local.git
```

The repositories have the same responsibility boundary as the AWS version:

```text
otel-demo-local/
├── kind/
└── terraform/
    ├── platform/
    │   └── Install CRDs, NGINX Gateway Fabric, and Argo CD
    └── applications/
        └── Register the local Argo CD Application

otel-demo-gitops-local/
├── argocd/applications/
│   └── otel-demo.yaml
└── applications/otel-demo/
    ├── values.yaml
    └── manifests/
        ├── gateway.yaml
        └── httproute.yaml
            └── Desired state continuously monitored by local Argo CD
```

The control flow is:

```text
Commit and push a change to otel-demo-gitops-local/main
                       |
                       v
Local Argo CD reads otel-demo-gitops-local from GitHub
                       |
                       v
Argo combines the upstream OpenTelemetry Demo Helm chart
with applications/otel-demo/values.yaml and manifests/
                       |
                       v
Argo reconciles the local kind cluster
```

The platform Terraform stage installs Argo CD. The separate applications stage
registers the Application with `kubernetes_manifest`, but Terraform does not
manage the OpenTelemetry Demo workloads. After registration, Argo CD owns
those workloads.

Argo CD runs inside Kubernetes and cannot read uncommitted files from the
workstation. Desired-state changes must be committed and pushed before Argo
can see them. The GitHub repository must either be public or configured in
Argo CD with private-repository credentials.

`otel-demo-gitops` remains reserved for AWS; `otel-demo-gitops-local` contains
only local desired state.

## Local CI workflow

The local release workflow lives beside the application code in
`otel-demo-apps`. A branch determines which environment receives a release:

```text
Push Recommendation code to otel-demo-apps/local
                       |
                       v
otel-demo-apps local release workflow
                       |
                       +-- uses the pushed commit SHA
                       +-- builds linux/arm64
                       +-- publishes an immutable GHCR image
                       +-- updates otel-demo-gitops-local values.yaml
                       |
                       v
Local Argo CD detects the generated commit on otel-demo-gitops-local/main
                       |
                       v
kind pulls and deploys the GHCR image
```

The workflow uses the commit that triggered it; there is no SHA selection or
copying step. It never updates `otel-demo-gitops`, pushes to Amazon ECR, or
changes the AWS environment.

## Prerequisites

- Docker-compatible runtime
- kind
- kubectl
- Helm
- Terraform
- Make
- anonymous read access to `lackito/otel-demo-gitops-local` from Argo CD, or
  separately configured private-repository credentials
- a public `ghcr.io/lackito/otel-demo-local-recommendation` package for
  anonymous image pulls from kind
- a fine-grained `LOCAL_GITOPS_REPOSITORY_TOKEN` secret in `otel-demo-apps`,
  with **Contents: Read and write** access to `otel-demo-gitops-local`; if the
  token was created before the repository, add the new repository to the
  token's selected repository access
- a classic `GHCR_PAT` secret in `otel-demo-apps`, owned by `lackito` and
  scoped to `write:packages`

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
make platform-validate
make applications-init
make applications-plan
make applications-apply
make application-validate
make recommendation-validate
```

Argo CD reads the GHCR image reference from Git and kind pulls the image. No
workstation-local image survives or is required.

Direct kind loading remains available as the faster development loop. When
using that mode on a new cluster, run `make recommendation-build-load` after
`make cluster-create` and before `make applications-apply`.

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

## Kubernetes context

The cluster is named `otel-demo-local` and its Kubernetes context is
`kind-otel-demo-local`.

The cluster registers that context in the standard kubeconfig:

```text
~/.kube/config
```

Repository automation selects `kind-otel-demo-local` explicitly, so it does
not depend on whichever context is currently active. Terraform uses the same
dedicated context in `~/.kube/config`.

For interactive work, select the context once and then use normal Kubernetes
and Helm commands:

```bash
kubectl config use-context kind-otel-demo-local
kubectl get nodes
kubectl get pods --all-namespaces
helm list --all-namespaces
```

Run `make cluster-create` if the kind cluster already exists but the context
needs to be restored in `~/.kube/config`.

## Local networking

The kind control-plane maps host ports 80 and 443 to fixed NodePorts used by
NGINX Gateway Fabric:

| Workstation | kind NodePort | Gateway listener |
|---|---|---|
| 80 | 31437 | HTTP 80 |
| 443 | 30478 | HTTPS 443 |

The `otel-demo-gitops-local` repository provides the Gateway resource,
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

Register the Argo CD Application after the platform is healthy:

```bash
make applications-init
make applications-plan
make applications-apply
```

For an existing checkout created before the stage split, adopt the running
Application into the new state before planning:

```bash
make applications-adopt
make platform-plan
make applications-plan
make applications-apply
```

The adoption command imports the existing Kubernetes object and forgets the
obsolete command resource without deleting the Application or its workloads.

Remove the application registration and then the platform before deleting the
cluster:

```bash
make applications-destroy
make platform-destroy
make cluster-destroy
```

Terraform's platform stage owns platform services. Its applications stage owns
only the Argo CD Application registration. Argo CD owns the workloads.

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
3. copy the printed tag into
   `otel-demo-gitops-local/applications/otel-demo/values.yaml`;
4. commit and push the `otel-demo-gitops-local` values change;
5. let Argo CD detect the commit and roll out the new image;
6. run:

```bash
make recommendation-validate
```

This manual loop remains useful while editing code because it avoids waiting
for a remote build.

### Repeatable delivery: local CI and GHCR

To publish and deploy through local CI:

1. commit Recommendation changes on the `otel-demo-apps/local` branch;
2. push that branch;
3. wait for `Release recommendation service to local Kubernetes`;
4. let its generated values commit reach Argo CD;
5. run `make recommendation-validate`.

The workflow uses `GHCR_PAT` to publish to GHCR and
`LOCAL_GITOPS_REPOSITORY_TOKEN` to update only `otel-demo-gitops-local`.

The GHCR package must be public. New packages may initially be private, so the
workflow deliberately stops before changing Git desired state if anonymous
pull access fails. Make `otel-demo-local-recommendation` public in its GitHub
package settings, then rerun the failed workflow.

Later pushes to the `local` branch are fully automatic.

### Observe an end-to-end GitOps update

After the application workflow succeeds, verify that its generated desired
state reached the `otel-demo-gitops-local` repository:

```bash
git fetch origin main
git log --oneline -3 origin/main -- applications/otel-demo/values.yaml
git show origin/main:applications/otel-demo/values.yaml |
  sed -n '/^  recommendation:/,/^  [a-z]/p'
```

Expected evidence:

- a generated commit named `chore(recommendation): deploy <commit-sha>`;
- repository `ghcr.io/lackito/otel-demo-local-recommendation`;
- a full 40-character tag matching the triggering `otel-demo-apps` commit.

To observe reconciliation in the Argo CD GUI, first obtain the password:

```bash
kubectl \
  get secret argocd-initial-admin-secret \
  --namespace argocd \
  --output jsonpath='{.data.password}' |
  base64 --decode
echo
```

In another terminal, keep this port-forward running:

```bash
kubectl \
  port-forward --namespace argocd service/argocd-server 8080:443
```

Open `https://localhost:8080`, accept the local certificate warning, and log
in as `admin`. Select `otel-demo-local` and observe:

1. **Refresh** discovers the generated `otel-demo-gitops-local/main` commit;
2. sync briefly changes through `OutOfSync` or `Progressing`;
3. automated synchronization updates the Recommendation Deployment;
4. the application returns to `Synced` and `Healthy`;
5. **History and Rollback** records the deployed source revision;
6. the resource tree shows the replacement Recommendation pod becoming
   healthy.

Finally, validate from the workstation:

```bash
make application-validate
make recommendation-validate
```

`make recommendation-validate` prints the deployed GHCR image and reports
`Delivery: local CI and GHCR`. The GitHub workflow run, Git commit, Argo CD
history, Deployment image, and API response together form the complete audit
trail.

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
kubectl \
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
