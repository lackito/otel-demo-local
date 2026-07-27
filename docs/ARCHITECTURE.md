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
- A future Gateway resource causes NGINX Gateway Fabric to create the data
  plane.
- HTTPRoute resources attach application routes to that Gateway.
- Fixed NodePorts connect the generated data plane to kind's host port
  mappings.

This milestone installs only the control plane. Gateway and HTTPRoute resources
belong with application desired state in the GitOps repository.

## Context isolation

All platform commands use `.state/kubeconfig` and the
`kind-otel-demo-local` context. The default kubeconfig is never used by
Terraform or the repository lifecycle scripts.

