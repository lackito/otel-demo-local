variable "cluster_context" {
  description = "Kubernetes context targeted by Gateway API lifecycle commands."
  type        = string
}

variable "nginx_gateway_fabric_version" {
  description = "NGINX Gateway Fabric release supplying the compatible Gateway API bundle."
  type        = string
}
