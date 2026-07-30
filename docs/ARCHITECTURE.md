# Local Platform Architecture

## Ownership

```text
kind configuration
        |
        v
Local Kubernetes cluster
        |
        v
Terraform
        |
        +-- Gateway API CRDs
        +-- NGINX Gateway Fabric
        +-- Argo CD
        |
        v
Argo CD Application registration
        |
        v
gitops/otel-demo in this repository
        |
        v
OpenTelemetry Demo workloads
```

`otel-demo-local` owns the cluster, platform, local Argo CD registration, and
local application desired state. `otel-demo-apps` remains only the source used
when rebuilding a demo service.

## Networking

NGINX Gateway Fabric has separate control and data planes.

- Terraform installs the control plane.
- The locally owned Gateway causes NGINX Gateway Fabric to create the data
  plane.
- HTTPRoute resources attach application routes to that Gateway.
- Fixed NodePorts connect the generated data plane to kind's host port
  mappings.

Gateway and HTTPRoute resources live with the other local application desired
state under `gitops/otel-demo`.

## Local application image flow

```text
otel-demo-apps
        |
        v
Native Docker build tagged with the apps Git revision
        |
        v
kind image load
        |
        v
Local image override in gitops/otel-demo/values.yaml
        |
        v
Argo CD Recommendation rollout
```

Direct image loading is the intentionally small local-development workflow.
Registry automation can be added later without coupling this repository to the
AWS delivery pipeline.

## Context isolation

All platform commands use `.state/kubeconfig` and the
`kind-otel-demo-local` context. The default kubeconfig is never used by
Terraform or the repository lifecycle scripts.
