output "cluster_context" {
  description = "Kubernetes context targeted by the applications stage."
  value       = local.cluster_context
}

output "kubeconfig_path" {
  description = "Standard kubeconfig used by the applications stage."
  value       = local.kubeconfig_path
}

output "argocd_application_name" {
  description = "Local Argo CD Application registered by Terraform."
  value       = module.argocd_application.name
}
