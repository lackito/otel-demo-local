locals {
  cluster_context = "kind-otel-demo-local"
  kubeconfig_path = abspath("${path.root}/../../.state/kubeconfig")
}

provider "helm" {
  kubernetes = {
    config_path    = local.kubeconfig_path
    config_context = local.cluster_context
  }
}

provider "kubernetes" {
  config_path    = local.kubeconfig_path
  config_context = local.cluster_context
}
