module "argocd_application" {
  source = "./modules/argocd-application"

  gitops_repo   = "https://github.com/lackito/otel-demo-gitops-local.git"
  gitops_branch = "main"
  gitops_path   = "applications/otel-demo"
}
