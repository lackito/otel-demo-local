# Local Troubleshooting Notes

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
did not stop the growth. This ruled out ordinary capacity pressure, an
incorrect image selection, scheduler sizing, and telemetry export as practical
causes.

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
- Milestone 5 application validation passes.

## Jaeger memory growth under sustained traffic

### Observation

The Jaeger all-in-one pod is currently limited to 400 MiB. After sustained
load-generator traffic, Kubernetes reported a previous termination reason of
`OOMKilled` with exit code 137. The pod restarted and returned to Ready.

This was observed during the Milestone 7 regression sweep. It is independent
of the custom Recommendation image rollout, but it means a successful rollout
check alone does not prove long-term observability-backend stability.

### Resolution

The local overlay reduces Jaeger's in-memory retention from 5,000 to 2,000
traces and raises its limit to 512 MiB. Related measured headroom was added for
Prometheus, the OpenTelemetry Collector, Grafana, and Grafana's sidecars.

`make observability-validate` verifies real trace and metric queries.
`make observability-soak` also ensures the observability pods are neither
replaced nor restarted during a 15-minute sustained-load window.
