resource "kubernetes_namespace" "codeflix" {
  metadata {
    name = "codeflix"
  }
  wait_for_default_service_account = true
}


resource "kubernetes_secret" "gcp_credentials_secret" {
  metadata {
    name      = "gcp-credentials-secret"
    namespace = "codeflix"
  }

  data = {
    "gcp_credentials.json" = file("../../.secrets/gcp_credentials.json")
  }
  depends_on = [kubernetes_namespace.codeflix]
}

data "aws_secretsmanager_secret_version" "db_secret" {
  secret_id = "DbSecret"
}

data "aws_secretsmanager_secret_version" "rmq_secret" {
  secret_id = "RmqSecret"
}

locals {
  db_secret_data   = jsondecode(data.aws_secretsmanager_secret_version.db_secret.secret_string)
  rmq_secret_data  = jsondecode(data.aws_secretsmanager_secret_version.rmq_secret.secret_string)
  keycloak_objects = toset(split("---", file("../../k8s/keycloak-operator.yaml")))
}

resource "kubernetes_secret" "db_k8s_secret" {
  metadata {
    name      = "db-secret"
    namespace = "codeflix"
  }

  data = {
    username = local.db_secret_data["username"]
    password = local.db_secret_data["password"]
  }
  depends_on = [kubernetes_namespace.codeflix]
}

resource "kubernetes_secret" "rmq_k8s_secret" {
  metadata {
    name      = "rabbitmq-secret"
    namespace = "codeflix"
  }

  data = {
    username = local.rmq_secret_data["username"]
    password = local.rmq_secret_data["password"]
  }
  depends_on = [kubernetes_namespace.codeflix]
}

data "http" "crds_keycloak" {
  url = "https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/25.0.5/kubernetes/keycloaks.k8s.keycloak.org-v1.yml"
}

data "http" "crds_keycloak_import" {
  url = "https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/25.0.5/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml"
}

resource "kubernetes_manifest" "keycloak_crds" {
  manifest = yamldecode(data.http.crds_keycloak.response_body)
}

resource "kubernetes_manifest" "keycloak_crds_import" {
  manifest = yamldecode(data.http.crds_keycloak_import.response_body)
}

resource "kubernetes_manifest" "keycloak_operator" {
  for_each        = { for k, v in local.keycloak_objects : k => v if v != "" }
  manifest        = yamldecode(each.value)
  computed_fields = ["spec.template.spec", "metadata.annotations"]
}

resource "helm_release" "rmq_operator" {
  name       = "rabbitmq-cluster-operator"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "rabbitmq-cluster-operator"
  depends_on = [ kubernetes_secret.rmq_k8s_secret ]
}