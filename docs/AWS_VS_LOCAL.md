# AWS and Local Platform Comparison

| Responsibility | AWS implementation | Local implementation |
|---|---|---|
| Kubernetes cluster | Amazon EKS | kind |
| Network foundation | VPC, subnets, routes, NAT | Docker network and kind port mappings |
| Traffic controller | AWS Load Balancer Controller | NGINX Gateway Fabric |
| Traffic API | Ingress and AWS annotations | Kubernetes Gateway API |
| External data plane | AWS ALB | NGINX pods and NodePort Service |
| Browser entry point | ALB DNS name | `http://otel-demo.localhost` |
| Application route | AWS-specific Ingress | `Gateway` and `HTTPRoute` |
| Workload identity | IRSA and AWS OIDC | Not required |
| Terraform backend | Amazon S3 | Local state |
| GitOps engine | Argo CD | Argo CD |
| Workload owner | Argo CD | Argo CD |
| Feature-flag evaluation | `flagd` | `flagd` |
| Feature-flag editor | `flagd-ui` sidecar | Disabled in the local arm64 overlay |

The local platform is not intended to imitate AWS networking internals.
Instead, it preserves the same responsibility boundary: Terraform installs the
traffic controller, while GitOps defines how application traffic is routed.

The local `HTTPRoute` is the equivalent of the AWS application Ingress at the
responsibility level: both are GitOps-owned desired state that connect an
external traffic controller to the frontend service. Their provider-specific
fields remain completely separate.

Disabling `flagd-ui` does not disable feature-flag evaluation. The main `flagd`
container remains deployed, and its flag document can be changed through
GitOps. This local exception isolates an image/runtime compatibility problem
without changing the completed AWS configuration.
