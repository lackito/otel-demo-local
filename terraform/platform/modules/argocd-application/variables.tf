variable "helm_repo" {
  description = "OpenTelemetry Helm chart repository."
  type        = string
  default     = "https://open-telemetry.github.io/opentelemetry-helm-charts"
}

variable "helm_chart" {
  description = "OpenTelemetry Demo Helm chart name."
  type        = string
  default     = "opentelemetry-demo"
}

variable "helm_chart_version" {
  description = "Pinned OpenTelemetry Demo Helm chart version."
  type        = string
  default     = "0.38.4"
}

variable "cluster_context" {
  description = "Kubernetes context targeted by Argo CD Application lifecycle commands."
  type        = string
}

variable "gitops_repo" {
  description = "Repository containing local Helm values and manifests."
  type        = string
}

variable "gitops_branch" {
  description = "Git revision watched by Argo CD."
  type        = string
  default     = "main"
}

variable "gitops_path" {
  description = "Application path inside the local GitOps repository."
  type        = string
}
