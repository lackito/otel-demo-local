locals {
  namespace = "argocd"
}

resource "helm_release" "this" {
  name             = "argocd"
  namespace        = local.namespace
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  atomic          = true
  cleanup_on_fail = true
  timeout         = 600
  wait            = true

  values = [
    yamlencode({
      dex = {
        enabled = false
      }
      notifications = {
        enabled = false
      }
    })
  ]
}

