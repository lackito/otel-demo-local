# Local Kubernetes Operations

[Overview](../README.md) · [Architecture](ARCHITECTURE.md) · [Troubleshooting](TROUBLESHOOTING.md)

Run commands from `otel-demo-local` unless another repository is named.
Repository scripts explicitly target `kind-otel-demo-local` in `~/.kube/config`.

## 1. Check prerequisites

Install Docker with a running compatible runtime, kind, kubectl, Helm,
Terraform, Make, curl, and jq. Keep `otel-demo-apps` beside this repository:
Recommendation build and validation scripts read it by default. Set
`APPS_REPOSITORY` if it lives elsewhere.

```bash
make prerequisites
kind get clusters
kubectl config current-context
```

Argo CD needs access to `otel-demo-gitops-local` on GitHub. For the GHCR path,
the image referenced by its values file must already exist and be anonymously
pullable. The current local release builds `linux/arm64`; an amd64 cluster
needs a matching image, such as the direct-load path below.

## 2. Create or resume the environment

Use the output of `kind get clusters` to choose **one** path below.
`otel-demo-local` here means the kind cluster name, not the repository folder.

### A. No local cluster exists

If the output says `No kind clusters found`, or does not list `otel-demo-local`,
create the cluster and check it:

```bash
make cluster-create
make validate
```

Once both succeed, continue to **Install the platform and register the application**
below. Do not run `platform-validate` before installing the platform.

### B. The local cluster already exists

If the output lists `otel-demo-local`, check the cluster:

```bash
make cluster-create
make validate
```

Despite its name, `cluster-create` reuses an existing cluster and restores a
missing kubeconfig context; it does not recreate the cluster.

If you previously installed the platform, run `make platform-validate`.
If it passes and the application was registered, continue to
[Validate the deployment](#3-validate-the-deployment).
If the platform has not been installed, use the installation sequence below.
If it is installed but fails validation, use [Troubleshooting](TROUBLESHOOTING.md)
before changing or recreating anything.

### Install the platform and register the application

Start here after the cluster passes `make validate`. Use an existing published
GHCR image in local GitOps values, or prepare a direct-loaded image as described
under [Update an image](#5-update-an-image).
Review each Terraform plan and confirmation prompt before applying.

Install the platform:

```bash
make platform-init
make platform-plan
make platform-apply
make platform-validate
```

After platform validation succeeds, register the application. If the platform
was already healthy and only registration is missing, start at this block:

```bash
make applications-init
make applications-plan
make applications-apply
```

Keep these stages separate: Argo CD and its CRDs must exist before Terraform
can plan the Application registration. For direct loading, build/load the
image and push the matching GitOps values before `applications-apply`.
Then continue to [Validate the deployment](#3-validate-the-deployment).

For manual inspection, explicitly select the local context:

```bash
kubectl config use-context kind-otel-demo-local
kubectl get nodes
kubectl get pods --all-namespaces
helm list --all-namespaces
```

## 3. Validate the deployment

```bash
make application-validate
make routing-validate
make recommendation-validate
make observability-validate
```

| Check | What it verifies |
|---|---|
| `validate` | Cluster readiness |
| `platform-validate` | Installed platform components |
| `application-validate` | Argo CD sync/health, Gateway, deployments, and image source |
| `routing-validate` | Route attachment, backend references, demo response, and hostname isolation |
| `recommendation-validate` | Deployed image format/source, rollout, and Recommendation API data |
| `observability-validate` | Backend rollouts, OOM status, actual metrics/traces, and Grafana health/datasources |

For sustained-load validation:

```bash
make observability-soak
```

This runs for 15 minutes and fails if an observability pod is replaced or a
container restart count changes. Ready pods alone do not prove telemetry is
flowing. The observability check queries active Prometheus `up` series,
Recommendation traces in Jaeger, and Grafana's Prometheus/Jaeger datasources.

The Recommendation validator accepts GHCR tags shaped as full commit SHAs;
compare the tag with the intended release SHA yourself. Direct-load validation
compares against the sibling application repository's current commit.

## 4. Open the interfaces

| Interface | URL |
|---|---|
| Demo | http://otel-demo.localhost |
| Grafana | http://otel-demo.localhost/grafana/ |
| Jaeger | http://otel-demo.localhost/jaeger/ui/ |

Prometheus stays cluster-internal; use Grafana for browser-based queries.
Telemetry storage is ephemeral, so workload recreation can discard history.

For Argo CD, retrieve the initial admin password locally:

```bash
kubectl --context kind-otel-demo-local -n argocd \
  get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode
echo
```

Keep this running in a separate terminal:

```bash
kubectl --context kind-otel-demo-local -n argocd \
  port-forward service/argocd-server 8080:443
```

Open `https://localhost:8080`, accept the local certificate warning, and sign
in as `admin` using the initial password unless you have changed it.

## 5. Update an image

### GitHub Actions and GHCR

In `otel-demo-apps`, configure these repository secrets for release publishing:

| Secret | Required access |
|---|---|
| `LOCAL_GITOPS_REPOSITORY_TOKEN` | Fine-grained token with Contents read/write for `otel-demo-gitops-local` |
| `GHCR_PAT` | Classic token owned by the publishing account with `write:packages` |

If the GitOps repository was created after the token, add it to the token's
selected repositories. These credentials are needed by CI, not for anonymous
pulls of an already-published public image.

1. Commit Recommendation changes on the `otel-demo-apps/local` branch.
2. Push that branch and watch **Release recommendation service to local Kubernetes**.
3. Confirm it publishes `ghcr.io/lackito/otel-demo-local-recommendation:<full-sha>`.
4. Confirm its generated commit updates `otel-demo-gitops-local/main`.
5. In Argo CD, refresh `otel-demo-local` and wait for `Synced` and `Healthy`.
6. Run `make application-validate` and `make recommendation-validate` here.

The workflow verifies anonymous image access before updating GitOps. If that
step fails, make the GHCR package public and rerun the workflow.

### Direct kind loading

Use this for a faster development loop or a native-architecture image:

1. Commit source changes in the sibling `otel-demo-apps` checkout so the image
   receives a distinct Git-based tag; the commit can remain local.
2. Run `make recommendation-build-load` here. It builds for the kind node's
   architecture and loads `otel-demo/recommendation:local-<short-sha>`.
3. In `otel-demo-gitops-local/applications/otel-demo/values.yaml`, set the
   Recommendation image override's **repository and tag** to the printed values.
4. Commit and push that values change; Argo CD cannot see unpushed local files.
5. Wait for reconciliation, then run `make recommendation-validate` here.

The build command does not update GitOps or trigger a rollout itself. Reload
the image after recreating a cluster. To return to GHCR delivery, publish a
local release and let its generated commit restore the GHCR repository/tag.

### Verify the complete delivery trail

Run in `otel-demo-gitops-local`:

```bash
git fetch origin main
git log --oneline -3 origin/main -- applications/otel-demo/values.yaml
git show origin/main:applications/otel-demo/values.yaml
```

For a CI release, look for `chore(recommendation): deploy <commit-sha>` and
match the full tag to the triggering application commit and published image.
In Argo CD, inspect **History and Rollback** and the Recommendation Deployment.
Its deployed image must match that release. Save the run URL, GitOps commit,
and deployment evidence when recording a test run.

## 6. Tear down

Destroy the application registration and platform before deleting the cluster:

```bash
make applications-destroy
make platform-destroy
make cluster-destroy
```

Deleting the cluster discards workloads and ephemeral data. The destroy script
refuses deletion while either local Terraform state still lists resources.
Keep Terraform state until the managed resources have been destroyed.
