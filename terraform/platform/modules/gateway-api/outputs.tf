output "release_version" {
  description = "NGINX release used to select the compatible Gateway API bundle."
  value       = terraform_data.standard_crds.output.release_version
}

