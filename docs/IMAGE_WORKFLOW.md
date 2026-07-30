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
- supports immutable commit tags and multi-architecture image indexes;
- can support a future workflow owned specifically by the local project;
- makes a fresh cluster reproducible from Git plus registry artifacts.

Tradeoffs:

- requires package permissions and authentication decisions;
- local pulls depend on network access;
- CI must build and test both target architectures.

GHCR is the recommended durable registry.

## Recommended progression

1. Build the Recommendation image for the kind node's native architecture and
   load it directly into kind.
2. Validate the complete image-to-GitOps-to-Argo rollout locally.
3. Optionally run a connected local registry as a focused registry and
   container-runtime learning exercise.
4. Consider GHCR only after the standalone local workflow is understood and a
   remote CI use case is needed.

This progression keeps the first feedback loop small while ending with a
workflow that is independent of the AWS GitOps and ECR pipeline.

## Current delivery policy

The local project uses direct kind loading. The image override lives at
`gitops/otel-demo/values.yaml` in this repository, and the local Argo CD
Application watches this repository only.

Direct kind loading remains available for the fastest development loop:

```bash
make recommendation-build-load
make recommendation-validate
```
