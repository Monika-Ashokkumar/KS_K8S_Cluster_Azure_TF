resource "kubernetes_deployment" "java_web_app" {
  metadata {
    name = "java-web-app"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "java-web-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "java-web-app"
        }
      }

      spec {
        container {
          name  = "app"
          image = "monikaashokkumar/java-web-app:5"

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "java_web_app_service" {
  metadata {
    name = "java-web-app-service"
  }

  spec {
    selector = {
      app = "java-web-app"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}
