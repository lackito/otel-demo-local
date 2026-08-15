output "cluster_context" {
  description = "Kubernetes context used by all platform providers."
  value       = local.cluster_context
}

output "kubeconfig_path" {
  description = "Standard kubeconfig used by the local platform."
  value       = local.kubeconfig_path
}

output "argocd_namespace" {
  description = "Namespace containing Argo CD."
  value       = module.argocd.namespace
}

output "nginx_gateway_namespace" {
  description = "Namespace containing the NGINX Gateway Fabric control plane."
  value       = module.nginx_gateway_fabric.namespace
}

output "argocd_application_name" {
  description = "Local Argo CD Application registered by Terraform."
  value       = module.argocd_application.name
}
