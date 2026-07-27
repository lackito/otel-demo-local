resource "terraform_data" "standard_crds" {
  input = {
    kubeconfig_path = var.kubeconfig_path
    release_version = var.nginx_gateway_fabric_version
  }

  triggers_replace = [
    var.nginx_gateway_fabric_version,
    var.kubeconfig_path,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      KUBECONFIG = var.kubeconfig_path
    }

    command = <<-EOT
      kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v${var.nginx_gateway_fabric_version}" \
        | kubectl apply --server-side --field-manager=terraform-platform -f -
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]

    environment = {
      KUBECONFIG = self.input.kubeconfig_path
    }

    command = <<-EOT
      kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v${self.input.release_version}" \
        | kubectl delete --ignore-not-found=true -f -
    EOT
  }
}

