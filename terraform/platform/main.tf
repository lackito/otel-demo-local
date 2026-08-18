module "gateway_api" {
  source = "./modules/gateway-api"

  cluster_context              = local.cluster_context
  nginx_gateway_fabric_version = var.nginx_gateway_fabric_version
}

module "nginx_gateway_fabric" {
  source = "./modules/nginx-gateway-fabric"

  chart_version = var.nginx_gateway_fabric_version

  depends_on = [module.gateway_api]
}

module "argocd" {
  source = "./modules/argocd"

  chart_version = var.argocd_chart_version
}

module "argocd_application" {
  source = "./modules/argocd-application"

  cluster_context = local.cluster_context
  gitops_repo     = "https://github.com/lackito/otel-demo-gitops-local.git"
  gitops_branch   = "main"
  gitops_path     = "applications/otel-demo"

  depends_on = [
    module.argocd,
    module.nginx_gateway_fabric,
  ]
}
