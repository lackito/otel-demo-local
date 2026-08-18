resource "kubernetes_manifest" "otel_demo" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "otel-demo-local"
      namespace = "argocd"
    }

    spec = {
      project = "default"

      sources = [
        {
          repoURL        = var.helm_repo
          chart          = var.helm_chart
          targetRevision = var.helm_chart_version

          helm = {
            valueFiles = [
              "$values/${var.gitops_path}/values.yaml",
            ]
          }
        },
        {
          repoURL        = var.gitops_repo
          targetRevision = var.gitops_branch
          ref            = "values"
        },
        {
          repoURL        = var.gitops_repo
          targetRevision = var.gitops_branch
          path           = "${var.gitops_path}/manifests"
        },
      ]

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "opentelemetry-demo"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }

        syncOptions = [
          "CreateNamespace=true",
          "ServerSideApply=true",
        ]
      }
    }
  }
}
