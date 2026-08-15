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

  application_name      = "otel-demo-local"
  chart_version         = var.opentelemetry_demo_chart_version
  cluster_context       = local.cluster_context
  gitops_repository_url = var.gitops_repository_url
  gitops_revision       = var.gitops_revision
  values_file           = "gitops/otel-demo/values.yaml"
  manifests_path        = "gitops/otel-demo/manifests"
  destination_namespace = "opentelemetry-demo"

  depends_on = [
    module.argocd,
    module.nginx_gateway_fabric,
  ]
}
