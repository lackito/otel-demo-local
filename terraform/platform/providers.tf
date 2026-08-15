locals {
  cluster_context = "kind-otel-demo-local"
  kubeconfig_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes = {
    config_path    = local.kubeconfig_path
    config_context = local.cluster_context
  }
}
