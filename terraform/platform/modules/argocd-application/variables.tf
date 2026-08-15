variable "application_name" {
  description = "Name of the Argo CD Application."
  type        = string
}

variable "cluster_context" {
  description = "Kubernetes context targeted by Argo CD Application lifecycle commands."
  type        = string
}

variable "chart_version" {
  description = "Pinned OpenTelemetry Demo Helm chart version."
  type        = string
}

variable "gitops_repository_url" {
  description = "Repository containing local Helm values and manifests."
  type        = string
}

variable "gitops_revision" {
  description = "Git revision watched by Argo CD."
  type        = string
}

variable "values_file" {
  description = "Local repository path to the Helm values."
  type        = string
}

variable "manifests_path" {
  description = "GitOps repository path containing local Kubernetes manifests."
  type        = string
}

variable "destination_namespace" {
  description = "Namespace where Argo CD deploys the application."
  type        = string
}
