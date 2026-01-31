job "revuelta-monolith" {
  datacenters = ["dc1"]

  # GRUPO 1: Base de Datos (Igual que siempre)
  group "database" {
    count = 1
    network {
      port "db" { static = 3306 }
    }

    task "mariadb" {
      driver = "docker"
      config {
        image = "mariadb:12.1.2"
        ports = ["db"]
        args = ["--bind-address=0.0.0.0"]
      }
      env {
        MARIADB_ROOT_PASSWORD = "password"
        MARIADB_DATABASE      = "revuelta_db"
        MARIADB_USER          = "nomad"
        MARIADB_PASSWORD      = "password"
      }
      service {
        name = "mariadb"
        port = "db"
        address_mode = "host"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
      resources { 
        cpu = 500
        memory = 512 
      }
    }
  }

  # GRUPO 2: API Quarkus (Modo Solitario)
  group "backend" {
    count = 1  # <--- Solo UNO. El punto único de fallo.

    network {
      # Puerto ESTÁTICO 8080.
      # Aquí no hay balanceador, conectamos directo a la aplicación.
      port "http" { static = 8080 } 
    }

    task "api" {
      driver = "docker"
      config {
        image = "quarkus/nomad-quarkus-jvm:0.0.1"
        ports = ["http"]
      }

      env {
        # Conexión a la DB
        QUARKUS_DATASOURCE_JDBC_URL = "jdbc:mariadb://${attr.unique.network.ip-address}:3306/revuelta_db?useSSL=false"        
        QUARKUS_DATASOURCE_USERNAME = "nomad"
        QUARKUS_DATASOURCE_PASSWORD = "password"
        QUARKUS_HTTP_HOST           = "0.0.0.0"
      }
      
      # Registramos el servicio solo para salud, pero no hay Fabio escuchando etiquetas
      service {
        name = "api-monolith"
        port = "http"
        address_mode = "host"
        
        check {
          type     = "http"
          path     = "/api/q/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources { 
        cpu = 200
        memory = 256 
      }
    }
  }
}
