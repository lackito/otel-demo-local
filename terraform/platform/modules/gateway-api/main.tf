resource "terraform_data" "standard_crds" {
  input = {
    cluster_context = var.cluster_context
    release_version = var.nginx_gateway_fabric_version
  }

  triggers_replace = [
    var.nginx_gateway_fabric_version,
    var.cluster_context,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v${var.nginx_gateway_fabric_version}" \
        | kubectl --context "${var.cluster_context}" apply --server-side --field-manager=terraform-platform -f -
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v${self.input.release_version}" \
        | kubectl --context "${self.input.cluster_context}" delete --ignore-not-found=true -f -
    EOT
  }
}
