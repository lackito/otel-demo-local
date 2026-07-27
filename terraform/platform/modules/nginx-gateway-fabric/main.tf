locals {
  namespace = "nginx-gateway"
}

resource "helm_release" "this" {
  name             = "ngf"
  namespace        = local.namespace
  create_namespace = true

  repository = "oci://ghcr.io/nginx/charts"
  chart      = "nginx-gateway-fabric"
  version    = var.chart_version

  atomic          = true
  cleanup_on_fail = true
  timeout         = 600
  wait            = true

  values = [
    yamlencode({
      nginxGateway = {
        productTelemetry = {
          enable = false
        }
      }
      nginx = {
        service = {
          type = "NodePort"
          nodePorts = [
            {
              port         = 31437
              listenerPort = 80
            },
            {
              port         = 30478
              listenerPort = 443
            },
          ]
        }
      }
    })
  ]
}

