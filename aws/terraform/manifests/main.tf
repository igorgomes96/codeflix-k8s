resource "kubernetes_manifest" "storageclass" {
  manifest = yamldecode(file("../../k8s/storageclass.yaml"))
}

resource "kubernetes_manifest" "db" {
  manifest = yamldecode(file("../../k8s/db.yaml"))

  wait {
    fields = {
      "status.readyReplicas" = "1"
    }
  }

  timeouts {
    create = "1m"
    update = "1m"
    delete = "30s"
  }
}

resource "kubernetes_manifest" "db-service" {
  manifest = yamldecode(file("../../k8s/db-service.yaml"))
}

resource "kubernetes_manifest" "keycloak" {
  manifest   = yamldecode(file("../../k8s/keycloak.yaml"))
  depends_on = [kubernetes_manifest.db]
}

resource "kubernetes_manifest" "keycloak_import" {
  manifest        = yamldecode(file("../../k8s/keycloak-import.yaml"))
  computed_fields = ["spec.realm.roles", "spec.realm.components"]
  depends_on      = [kubernetes_manifest.keycloak]
}

resource "kubernetes_manifest" "rmq" {
  manifest = yamldecode(file("../../k8s/rabbitmq.yaml"))
}

locals {
  rmq_objects = [for obj in toset(split("---", file("../../k8s/rabbitmq-topology.yaml"))) : yamldecode(obj) if obj != ""]
}

resource "kubernetes_manifest" "rmq_topology" {
  for_each   = { for definition in local.rmq_objects : definition.metadata.name => definition }
  manifest   = each.value
  depends_on = [kubernetes_manifest.rmq]
}

resource "null_resource" "rmq_resources_wait" {
  triggers = {
    always = "$(timestamp())"
  }
  provisioner "local-exec" {
    command = <<EOF
        while [[ "$(kubectl get users.rabbitmq.com adm-videos -n codeflix -o json | jq '.status.conditions[] | .reason')" != '"SuccessfulCreateOrUpdate"' ]]; do
          echo "Waiting for RabbitMQ resources to be created/updated..."
          sleep 5
        done
    EOF
  }
}

resource "kubernetes_manifest" "admin_catalog" {
  manifest = yamldecode(file("../../k8s/admin-catalog.yaml"))
  wait {
    rollout = true
  }

  depends_on = [null_resource.rmq_resources_wait]
}

resource "kubernetes_manifest" "admin_catalog_service" {
  manifest = yamldecode(file("../../k8s/admin-catalog-service.yaml"))
}

resource "kubernetes_manifest" "ingress" {
  manifest = yamldecode(file("../../k8s/ingress.yaml"))
  depends_on = [ kubernetes_manifest.admin_catalog_service ]
}