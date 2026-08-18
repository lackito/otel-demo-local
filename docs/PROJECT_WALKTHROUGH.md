# AWS and Local Project Walkthrough

The AWS and local implementations use the same delivery model. They differ in
infrastructure and registry choices, while preserving the same ownership
boundaries.

## Shared flow

```text
Application source
        |
        v
GitHub Actions builds an immutable commit-tagged image
        |
        v
Environment-specific image registry
        |
        v
GitHub Actions updates environment-specific GitOps values
        |
        v
Argo CD detects the Git commit
        |
        v
Argo CD reconciles the Kubernetes workload
```

## Environment mapping

| Stage | AWS | Local |
|---|---|---|
| Source | `otel-demo-apps/main` | `otel-demo-apps/local` |
| Registry | Amazon ECR | GitHub Container Registry |
| GitOps repository | `otel-demo-gitops` | `otel-demo-gitops-local` |
| Cluster | Amazon EKS | kind |
| Traffic controller | AWS Load Balancer Controller | NGINX Gateway Fabric |
| Public route | AWS ALB and Ingress | NodePort, Gateway, and HTTPRoute |

## Terraform ownership

Both implementations install platform components before registering
applications:

```text
Platform Terraform state
        |
        +-- traffic controller
        +-- Argo CD and its CRDs
        |
        v
Applications Terraform state
        |
        +-- kubernetes_manifest: Argo CD Application
        |
        v
GitOps repository
        |
        +-- declarative Argo CD Application definition
        +-- Helm values
        +-- environment-specific routing manifests
        |
        v
Argo CD-owned workloads
```

Terraform registers the Argo CD Applications. Both GitOps repositories retain
matching declarative Application YAML alongside the desired application state
so the AWS and local implementations can be compared directly.

## Implementation order

For either environment:

1. Create the Kubernetes cluster.
2. Apply the platform Terraform stage.
3. Confirm Argo CD and required CRDs are healthy.
4. Apply the applications Terraform stage.
5. Confirm the Argo CD Application is `Synced` and `Healthy`.
6. Promote application changes by updating GitOps through the release
   workflow, not by changing workloads directly.
