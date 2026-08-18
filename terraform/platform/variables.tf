variable "nginx_gateway_fabric_version" {
  description = "Pinned NGINX Gateway Fabric Helm chart and release version."
  type        = string
  default     = "2.6.7"
}

variable "argocd_chart_version" {
  description = "Pinned Argo CD Helm chart version."
  type        = string
  default     = "9.5.17"
}
