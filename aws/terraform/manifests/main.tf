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
    create = "2m"
    update = "2m"
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

  wait {
    fields = {
      "status.conditions[3].reason" = "Success"
    }
  }

  timeouts {
    create = "2m"
    update = "2m"
    delete = "30s"
  }
}

locals {
  rmq_objects = [for obj in split("---", file("../../k8s/rabbitmq-topology.yaml")) : yamldecode(obj) if obj != ""]
  beats_rbac_objects = [for obj in split("---", file("../../k8s/beats-rbac.yaml")) : yamldecode(obj) if obj != ""]
}

resource "kubernetes_manifest" "rmq_topology" {
  for_each   = { for definition in local.rmq_objects : definition.metadata.name => definition }
  manifest   = each.value
  depends_on = [kubernetes_manifest.rmq]
  wait {
    fields = {
      "status.conditions[0].reason" = "SuccessfulCreateOrUpdate"
    }
  }

  timeouts {
    create = "2m"
    update = "2m"
    delete = "30s"
  }

  computed_fields = ["spec.autoDelete", "spec.realm.components"]
}

resource "kubernetes_manifest" "admin_catalog" {
  manifest = yamldecode(file("../../k8s/admin-catalog.yaml"))
  wait {
    rollout = true
  }

  timeouts {
    create = "1m"
    update = "1m"
    delete = "30s"
  }

  depends_on = [kubernetes_manifest.rmq_topology]
}

resource "kubernetes_manifest" "admin_catalog_service" {
  manifest = yamldecode(file("../../k8s/admin-catalog-service.yaml"))
}

resource "kubernetes_manifest" "elasticsearch" {
  manifest = yamldecode(file("../../k8s/elasticsearch.yaml"))
  computed_fields = ["spec.nodeSets"]
}

resource "kubernetes_manifest" "beats_rbac" {
  for_each   = { for definition in local.beats_rbac_objects : definition.metadata.name => definition }
  manifest   = each.value
}

resource "kubernetes_manifest" "beats" {
  manifest = yamldecode(file("../../k8s/beats.yaml"))
  field_manager {
    force_conflicts = true
  }
  depends_on = [kubernetes_manifest.beats_rbac, kubernetes_manifest.elasticsearch]
}

resource "kubernetes_manifest" "kibana" {
  manifest = yamldecode(file("../../k8s/kibana.yaml"))
  field_manager {
    force_conflicts = true
  }
  depends_on = [kubernetes_manifest.elasticsearch]
  
}

resource "kubernetes_manifest" "front_admin_catalog" {
  manifest = yamldecode(file("../../k8s/front.yaml"))
  wait {
    rollout = true
  }

  timeouts {
    create = "2m"
    update = "2m"
    delete = "30s"
  }

  depends_on = [kubernetes_manifest.admin_catalog]
}

resource "kubernetes_manifest" "front_admin_catalog_service" {
  manifest = yamldecode(file("../../k8s/front-service.yaml"))
}

resource "kubernetes_manifest" "ingress" {
  manifest = yamldecode(file("../../k8s/ingress.yaml"))
  depends_on = [ kubernetes_manifest.admin_catalog_service ]
}