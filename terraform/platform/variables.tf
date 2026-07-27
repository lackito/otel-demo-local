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

variable "opentelemetry_demo_chart_version" {
  description = "Pinned OpenTelemetry Demo Helm chart version."
  type        = string
  default     = "0.38.4"
}

variable "gitops_repository_url" {
  description = "GitOps repository watched by the local Argo CD Application."
  type        = string
  default     = "https://github.com/lackito/otel-demo-gitops.git"
}

variable "gitops_revision" {
  description = "Git revision watched by the local Argo CD Application."
  type        = string
  default     = "main"
}
