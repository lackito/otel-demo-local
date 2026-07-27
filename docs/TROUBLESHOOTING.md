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
