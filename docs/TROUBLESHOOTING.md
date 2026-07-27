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

### Next step

The observability milestone should measure Jaeger's memory growth, choose an
appropriate local trace-retention and memory configuration, and add validation
for backend restarts and queryability. No Jaeger setting was changed during
the application-image milestone.
