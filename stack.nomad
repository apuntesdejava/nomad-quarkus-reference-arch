job "revuelta-stack" {
  datacenters = ["dc1"]

  # GRUPO 1: Load Balancer (Singleton)
  group "loadbalancer" {
    count = 1
    network {
      port "lb" { static = 9999 }
      port "ui" { static = 9998 }
    }
    task "fabio" {
      driver = "docker"
      config {
        image = "fabiolb/fabio:1.6.11"
        ports = ["lb", "ui"]
      }
      env {
        FABIO_REGISTRY_CONSUL_ADDR = "${attr.unique.network.ip-address}:8500"
       FABIO_REGISTRY_CONSUL_REGISTER = "false"
      }
      resources { 
        cpu = 200 
        memory = 128 
      }
      service {
        name = "fabio-ui"
        port = "ui"
        tags = ["fabio-ui"]
        address_mode = "host" # <--- CLAVE: Usa la IP 172.25...
        
        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }

  # GRUPO 2: Base de Datos (Singleton - NO SE ESCALA)
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
        args = [
          "--bind-address=0.0.0.0" 
        ]
      }

      env {
        MARIADB_ROOT_PASSWORD = "rootpassword"
        MARIADB_DATABASE      = "revuelta_db"
        MARIADB_USER          = "nomad"
        MARIADB_PASSWORD      = "password"
      }
      
      service {
        name     = "database"
        port     = "db"
        provider = "nomad"
        
        # Un check simple de TCP es suficiente
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

  # GRUPO 3: API Quarkus (¡ESTE ES EL QUE ESCALA!)
  group "backend" {
    count = 3  # <--- ¡Aquí está la magia! Ya nacemos con 3

    network {
      # Puerto dinámico: Nomad asignará uno libre a cada réplica
      port "http" { to = 8080 }
    }

    task "api" {
      driver = "docker"
      config {
        image = "quarkus/nomad-quarkus-jvm:0.0.1"
        ports = ["http"]
      }

      env {
        # TRUCO MAESTRO:
        # Como separamos los grupos, ya no podemos usar ${NOMAD_PORT_db} directo.
        # Pero sabemos que la DB está en el puerto 3306 de la IP del nodo.
        # ${attr.unique.network.ip-address} es la IP de tu WSL.
        QUARKUS_DATASOURCE_JDBC_URL = "jdbc:mariadb://${attr.unique.network.ip-address}:3306/revuelta_db?useSSL=false"        
        QUARKUS_DATASOURCE_USERNAME = "nomad"
        QUARKUS_DATASOURCE_PASSWORD = "password"
        QUARKUS_HTTP_HOST           = "0.0.0.0"
        QUARKUS_HTTP_PORT           = "${NOMAD_PORT_http}"
      }

      service {
        name = "api-quarkus"
        port = "http"
        tags = ["urlprefix-/api", "quarkus"] # Fabio leerá esto
        # provider = "nomad"
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
