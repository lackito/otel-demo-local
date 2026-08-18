locals {
  application_name      = "otel-demo-local"
  application_namespace = "argocd"
  destination_namespace = "opentelemetry-demo"

  application_manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = local.application_name
      namespace = local.application_namespace
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
        namespace = local.destination_namespace
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

resource "terraform_data" "this" {
  input = {
    application_name      = local.application_name
    application_namespace = local.application_namespace
    cluster_context       = var.cluster_context
    manifest              = yamlencode(local.application_manifest)
  }

  triggers_replace = [
    var.cluster_context,
    sha256(yamlencode(local.application_manifest)),
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      APPLICATION_MANIFEST = yamlencode(local.application_manifest)
      CLUSTER_CONTEXT      = var.cluster_context
    }

    command = <<-EOT
      for attempt in {1..150}; do
        if kubectl --context "$CLUSTER_CONTEXT" get customresourcedefinition applications.argoproj.io >/dev/null 2>&1; then
          break
        fi

        if ((attempt == 150)); then
          echo "Timed out waiting for the Argo CD Application CRD." >&2
          exit 1
        fi

        sleep 2
      done

      printf '%s\n' "$APPLICATION_MANIFEST" \
        | kubectl --context "$CLUSTER_CONTEXT" apply --server-side --field-manager=terraform-platform -f -
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]

    environment = {
      APPLICATION_NAME      = self.input.application_name
      APPLICATION_NAMESPACE = self.input.application_namespace
      CLUSTER_CONTEXT       = self.input.cluster_context
    }

    command = <<-EOT
      if kubectl --context "$CLUSTER_CONTEXT" get customresourcedefinition applications.argoproj.io >/dev/null 2>&1; then
        kubectl --context "$CLUSTER_CONTEXT" delete application "$APPLICATION_NAME" \
          --namespace "$APPLICATION_NAMESPACE" \
          --ignore-not-found=true
      fi
    EOT
  }
}
