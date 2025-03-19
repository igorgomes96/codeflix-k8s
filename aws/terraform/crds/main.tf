resource "kubernetes_namespace" "codeflix" {
  metadata {
    name = "codeflix"
  }
  wait_for_default_service_account = true
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
  keycloak_objects = [for obj in split("---", file("../../k8s/keycloak-operator.yaml")) : yamldecode(obj) if obj != ""]
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
  for_each        = { for definition in local.keycloak_objects : "${definition.kind}-${definition.metadata.name}" => definition }
  manifest        = each.value
  computed_fields = ["spec.template.spec", "metadata.annotations"]
  depends_on      = [kubernetes_namespace.codeflix]
}

resource "helm_release" "rmq_operator" {
  name       = "rabbitmq-cluster-operator"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "rabbitmq-cluster-operator"
  depends_on = [kubernetes_namespace.codeflix]
}

resource "helm_release" "eck" {
  name       = "eck-operator"
  repository = "https://helm.elastic.co"
  chart      = "eck-operator"
  depends_on = [kubernetes_namespace.codeflix]
}
