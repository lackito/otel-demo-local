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
otel-demo-gitops
        |
        v
OpenTelemetry Demo workloads
```

`otel-demo-local` owns the cluster and shared platform. `otel-demo-gitops`
owns application desired state. `otel-demo-apps` owns application source and
container builds.

## Networking

NGINX Gateway Fabric has separate control and data planes.

- Terraform installs the control plane.
- The GitOps-owned Gateway causes NGINX Gateway Fabric to create the data
  plane.
- HTTPRoute resources attach application routes to that Gateway.
- Fixed NodePorts connect the generated data plane to kind's host port
  mappings.

Gateway and HTTPRoute resources belong with application desired state in the
GitOps repository.

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
Local GitOps image override
        |
        v
Argo CD Recommendation rollout
```

Direct image loading is the first local-development stage. GHCR will replace
the machine-local image handoff when the workflow is automated for CI.

## Context isolation

All platform commands use `.state/kubeconfig` and the
`kind-otel-demo-local` context. The default kubeconfig is never used by
Terraform or the repository lifecycle scripts.
