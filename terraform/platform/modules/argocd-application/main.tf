resource "kubernetes_manifest" "this" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = var.application_name
      namespace = "argocd"
    }

    spec = {
      project = "default"

      sources = [
        {
          repoURL        = "https://open-telemetry.github.io/opentelemetry-helm-charts"
          chart          = "opentelemetry-demo"
          targetRevision = var.chart_version

          helm = {
            valueFiles = [
              "$values/${var.values_file}",
            ]
          }
        },
        {
          repoURL        = var.gitops_repository_url
          targetRevision = var.gitops_revision
          ref            = "values"
        },
        {
          repoURL        = var.gitops_repository_url
          targetRevision = var.gitops_revision
          path           = var.manifests_path
        },
      ]

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.destination_namespace
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

