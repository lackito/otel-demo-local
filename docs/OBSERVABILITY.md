# Local Observability Validation

## Data flow

```text
Demo services
      |
      | OTLP
      v
OpenTelemetry Collector
      |
      +-- traces --> Jaeger
      |
      +-- metrics --> Prometheus
                         |
                         v
                      Grafana
```

The load generator continuously exercises this flow. The local configuration
uses memory-backed and ephemeral storage, so stopping or recreating workloads
can discard historical data.

## Why readiness is not enough

A Ready pod proves that its current process passed Kubernetes probes. It does
not prove that:

- telemetry reached the backend;
- Prometheus has active series;
- Jaeger contains recent traces;
- Grafana has working datasource configuration;
- a backend remains within its memory limit under sustained traffic.

The Milestone 8 validator therefore checks the data plane as well as Kubernetes
health.

## Validation

`make observability-validate` checks:

- Argo CD is `Synced` and `Healthy`;
- Jaeger, Prometheus, Grafana, and the Collector completed their rollouts;
- their current pods do not retain an `OOMKilled` state;
- Prometheus returns active `up` series;
- Jaeger lists Recommendation and returns a recent Recommendation trace;
- Grafana reports a healthy database;
- Grafana contains Prometheus and Jaeger datasources;
- Grafana and Jaeger APIs are reachable through the browser route.

`make observability-soak` repeats these checks for 15 minutes and fails if any
observability pod is replaced or any container restart count changes.

## Browser access

- Grafana: `http://otel-demo.localhost/grafana/`
- Jaeger: `http://otel-demo.localhost/jaeger/ui/`

Prometheus stays cluster-internal. Grafana is its intended browser-facing
query and visualization layer, while validation reaches Prometheus through the
Kubernetes API service proxy.
