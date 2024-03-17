resource "kubernetes_secret" "github_token" {
  metadata {
    name      = "github.token"
    namespace = "global-secrets"

    annotations = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  data = {
    token      = var.auth.token
  }
}
