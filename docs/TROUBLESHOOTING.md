# Local Troubleshooting

[Overview](../README.md) · [Operations](OPERATIONS.md) · [Architecture](ARCHITECTURE.md)


## Runtime or context unavailable

Start the Docker-compatible runtime, then run `make prerequisites`.
If the named cluster exists but its context is missing, `make cluster-create`
restores it. Select `kind-otel-demo-local` for interactive kubectl commands.
Use `make validate` before checking platform or workload health.

## Application registration fails because the CRD is missing

Apply and validate the platform stage before planning the applications stage.
See [Create or resume the environment](OPERATIONS.md#2-create-or-resume-the-environment). Argo CD's CRD must
exist for Terraform to plan its Application resource.

For an older checkout that registered the Application from the platform state,
initialize the two stages and use the existing migration helper:

```bash
make platform-init
make applications-init
make applications-adopt
make platform-plan
make applications-plan
make applications-apply
```

The helper adopts the existing Application and forgets the obsolete command
resource without deleting workloads. Use it only for that older state layout,
not as a routine fresh-cluster step.

## Image pull or Recommendation validation fails

Check the deployed image and pod events with the explicit local context:

```bash
kubectl --context kind-otel-demo-local -n opentelemetry-demo get pods
kubectl --context kind-otel-demo-local -n opentelemetry-demo get events --sort-by=.lastTimestamp
```

For GHCR, confirm that the package is public and the referenced full-SHA tag
exists. The local CI workflow builds arm64; an amd64 node needs a matching
image. If CI cannot update GitOps, verify the fine-grained token includes the
local GitOps repository with Contents read/write access.

For direct loading, reload the image after cluster recreation, update both the
repository and tag in GitOps, and push the commit. Keep the sibling application
checkout at the source revision used for the build; the validator compares its
HEAD with the direct-loaded tag.

## GitOps changes do not appear

Commit and push local values to `otel-demo-gitops-local/main`. Inspect the
`otel-demo-local` Application in Argo CD for repository or sync errors, then
compare the desired image with the Deployment. Run `make application-validate`.
Argo CD cannot read uncommitted workstation files.

## Browser route does not respond

Run `make routing-validate` and inspect the Gateway/HTTPRoute conditions.
Use HTTP, not HTTPS; host port 443 alone does not configure a TLS listener.
To isolate application health from Gateway routing:

```bash
kubectl --context kind-otel-demo-local -n opentelemetry-demo \
  port-forward service/frontend-proxy 18080:8080
```

Open `http://localhost:18080` while the command is running. If this works but
`http://otel-demo.localhost` fails, focus on Gateway routing, host port mapping,
and hostname resolution.

## `flagd-ui` OOM on arm64

### Symptom

The `flagd` pod reported `1/2` containers ready. Its main `flagd` container was
healthy, but the optional `flagd-ui` sidecar repeatedly exited with code 137
and `OOMKilled`.

### Evidence

The kind node kernel identified the killed process as the Erlang VM
(`beam.smp`). The process grew to each tested container limit:

- native arm64 image at 768 MiB and 1 GiB;
- amd64 image under Colima's x86_64 emulation at 400 MiB and 768 MiB.

Constraining Erlang schedulers and disabling the sidecar's OpenTelemetry SDK
did not stop the growth. Those experiments did not resolve the observed failure; they do not establish
a definitive upstream root cause.

### Local decision

The local GitOps overlay sets:

```yaml
components:
  flagd:
    sidecarContainers: []
```

This disables only the optional web editor. The main `flagd` service remains
healthy and continues to evaluate feature flags. Flag changes can be managed
declaratively in Git.

The AWS configuration is unchanged.

### Verification

```bash
make application-validate
```

Expected results include:

- Argo CD reports `Synced` and `Healthy`;
- the `flagd` pod reports `1/1 Running`;
- every deployment completes its rollout;
- application validation passes.

## Jaeger memory growth under sustained traffic

### Observation

With the previous 400 MiB limit, sustained
load-generator traffic, Kubernetes reported a previous termination reason of
`OOMKilled` with exit code 137. The pod restarted and returned to Ready.

This was observed during a regression check. It is independent
of the custom Recommendation image rollout, but it means a successful rollout
check alone does not prove long-term observability-backend stability.

### Resolution

The local overlay reduces Jaeger's in-memory retention from 5,000 to 2,000
traces and raises its limit to 512 MiB. Related measured headroom was added for
Prometheus, the OpenTelemetry Collector, Grafana, and Grafana's sidecars.

`make observability-validate` verifies real trace and metric queries.
`make observability-soak` also ensures the observability pods are neither
replaced nor restarted during a 15-minute sustained-load window.
