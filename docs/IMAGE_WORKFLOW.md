# Local Container Image Workflow

## Options

### Direct image loading into kind

Advantages:

- no registry installation or credentials;
- fastest edit-build-test loop;
- works offline after base images and dependencies are cached;
- makes architecture mismatches visible immediately.

Limitations:

- the image exists only in the current kind node;
- a recreated cluster must load it again;
- Git desired state alone cannot reproduce the deployment;
- GitHub-hosted Actions cannot access the local image.

This is the Milestone 7 workflow.

### Local registry connected to kind

Advantages:

- teaches registry push and Kubernetes pull behavior;
- supports repeated local builds without loading image archives into nodes;
- can serve multiple local nodes or clusters.

Limitations:

- adds registry lifecycle, addressing, and trust configuration;
- remains workstation-local state;
- is not reachable from GitHub-hosted Actions;
- does not solve portfolio or remote CI distribution.

A connected registry is useful as an optional Kubernetes networking lab, but
it is not the primary delivery path for this project.

### GitHub Container Registry

Advantages:

- one registry is reachable from the workstation, GitHub Actions, and clusters;
- supports immutable commit tags;
- is used by a workflow owned specifically by the local project;
- makes a fresh cluster reproducible from Git plus registry artifacts.

Tradeoffs:

- requires package permissions and authentication decisions;
- local pulls depend on network access;
- emulated arm64 builds are slower on GitHub-hosted runners.

GHCR is the recommended durable registry.

## Recommended progression

1. Build the Recommendation image for the kind node's native architecture and
   load it directly into kind.
2. Validate the complete image-to-GitOps-to-Argo rollout locally.
3. Push a Recommendation commit to the `otel-demo-apps/local` branch.
4. Let its local release workflow build `linux/arm64`, publish the immutable
   image to GHCR, and update local desired state.
5. Optionally run a connected local registry later as a focused registry and
   container-runtime learning exercise.

This progression keeps the first feedback loop small while ending with a
workflow that is independent of the AWS GitOps and ECR pipeline.

## Current delivery policy

The local project supports two independent feedback loops.

Direct kind loading is the fastest development loop:

```bash
make recommendation-build-load
make recommendation-validate
```

The durable loop begins when Recommendation code is pushed to the
`otel-demo-apps/local` branch. Its local GitHub Actions workflow:

1. uses the pushed commit SHA automatically;
2. builds and publishes
   `ghcr.io/lackito/otel-demo-local-recommendation:<full-sha>`;
3. updates only `gitops/otel-demo/values.yaml`;
4. commits the desired-state change to `otel-demo-local`;
5. leaves deployment to local Argo CD.

AWS credentials, ECR, and `otel-demo-gitops` are outside this workflow.
