output "name" {
  description = "Name of the registered Argo CD Application."
  value       = kubernetes_manifest.this.object.metadata.name
}

