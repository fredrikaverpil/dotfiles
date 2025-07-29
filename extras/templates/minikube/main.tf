provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "gohello" {
  metadata {
    name = "gohello"
  }
}

resource "kubernetes_pod" "gohello_pod" {
  metadata {
    name      = "gohello-pod"
    namespace = kubernetes_namespace.gohello.metadata[0].name
  }

  spec {
    container {
      image = "docker.io/fredrikaverpil/gohello:0.0.1"
      name  = "gohello-container"

      port {
        container_port = 9090
      }
    }
  }
}
