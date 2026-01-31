package com.revuelta;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.HashMap;
import java.util.Map;

@Path("/hello")
public class RevueltaResource {

    @Inject
    DataSource dataSource;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, String> hello() {
        Map<String, String> response = new HashMap<>();
        
        // 1. Verificar identidad del nodo (Hostname/IP)
        try {
            response.put("node", InetAddress.getLocalHost().getHostName());
            response.put("framework", "Quarkus - Supersonic Subatomic Java");
            response.put("orchestrator", "HashiCorp Nomad");
        } catch (UnknownHostException e) {
            response.put("error_host", e.getMessage());
        }

        // 2. Verificar conexión a BD (Postgres en Docker via Consul)
        try (Connection con = dataSource.getConnection()) {
            boolean valid = con.isValid(2);
            response.put("database_status", valid ? "CONECTADO 🟢" : "FALLO 🔴");
            response.put("db_metadata", con.getMetaData().getDatabaseProductVersion());
        } catch (SQLException e) {
            response.put("database_status", "ERROR: " + e.getMessage());
        }

        return response;
    }
}
