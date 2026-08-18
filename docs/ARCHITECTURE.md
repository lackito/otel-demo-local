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
Separate Terraform applications stage
        |
        v
Argo CD Application registration via kubernetes_manifest
        |
        v
otel-demo-gitops-local/applications/otel-demo
        |
        v
OpenTelemetry Demo workloads
```

`otel-demo-local` owns the cluster, platform, and local Argo CD registration in
separate Terraform states.
`otel-demo-gitops-local` owns local application desired state, while
`otel-demo-apps` owns the service source.

## Networking

NGINX Gateway Fabric has separate control and data planes.

- Terraform installs the control plane.
- The locally owned Gateway causes NGINX Gateway Fabric to create the data
  plane.
- HTTPRoute resources attach application routes to that Gateway.
- Fixed NodePorts connect the generated data plane to kind's host port
  mappings.

Gateway and HTTPRoute resources live with the other local application desired
state under `applications/otel-demo` in `otel-demo-gitops-local`.

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
Local image override in otel-demo-gitops-local
        |
        v
Argo CD Recommendation rollout
```

Direct image loading is the intentionally small local-development workflow.
Registry automation can be added later without coupling this repository to the
AWS delivery pipeline.

## Kubernetes context

The cluster registers `kind-otel-demo-local` in the standard
`~/.kube/config`. Terraform and repository automation select that context
explicitly, while interactive users can activate it once with
`kubectl config use-context kind-otel-demo-local` and then use normal
`kubectl` and `helm` commands.
