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
- fits the existing GitHub repositories and GitOps promotion workflow;
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
4. Publish `linux/amd64` and `linux/arm64` under one immutable commit tag in
   GHCR.
5. Have CI update only the local GitOps image tag; Argo CD remains the workload
   deployer.

This progression keeps the first feedback loop small while ending with a
workflow suitable for both the Apple Silicon development cluster and amd64
GitHub/AWS environments.
