variable "kubeconfig_path" {
  description = "Absolute path to the isolated local kubeconfig."
  type        = string
}

variable "nginx_gateway_fabric_version" {
  description = "NGINX Gateway Fabric release supplying the compatible Gateway API bundle."
  type        = string
}

