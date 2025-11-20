package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;
import com.google.gson.Gson;
import com.google.gson.JsonObject;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

@WebServlet("/TarjetaServlet")
public class TarjetaServlet extends HttpServlet {
    
    
    private final Gson gson = new Gson();
    
    /**
     * Registra en auditoría
     */
    private void registrarAuditoria(int usuarioId, String accion, String detalles) {
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "INSERT INTO auditoria (usuario_id, accion, tabla, registro_id, detalles) " +
                         "VALUES (?, ?, ?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, usuarioId);
            stmt.setString(2, accion);
            stmt.setString(3, "tarjetas");
            stmt.setString(4, null);
            stmt.setString(5, detalles);
            stmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("⚠️ Error en auditoría: " + e.getMessage());
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        Usuario user = (Usuario) request.getSession().getAttribute("usuario");
        if (user == null) {
            enviarRespuestaJSON(response, false, "Sesión expirada");
            return;
        }
        
        String accion = request.getParameter("accion");
        
        if ("agregar".equals(accion)) {
            agregarTarjeta(request, response, user);
        } else if ("eliminar".equals(accion)) {
            eliminarTarjeta(request, response, user);
        } else {
            enviarRespuestaJSON(response, false, "Acción no válida");
        }
    }
    
    /**
     * Agrega una nueva tarjeta
     */
    private void agregarTarjeta(HttpServletRequest request, HttpServletResponse response, Usuario user)
            throws IOException {
        
        String numero = request.getParameter("numero");
        String titular = request.getParameter("titular");
        String expiracion = request.getParameter("expiracion");
        String cvv = request.getParameter("cvv");
        String tipo = request.getParameter("tipo");
        String banco = request.getParameter("banco");
        
        // Validaciones
        if (numero == null || titular == null || expiracion == null || 
            cvv == null || tipo == null || banco == null) {
            enviarRespuestaJSON(response, false, "Datos incompletos");
            return;
        }
        
        // Validar formato de número de tarjeta
        if (!numero.matches("[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}")) {
            enviarRespuestaJSON(response, false, "Formato de tarjeta inválido");
            return;
        }
        
        // Validar formato de expiración
        if (!expiracion.matches("[0-9]{2}/[0-9]{4}")) {
            enviarRespuestaJSON(response, false, "Formato de fecha inválido (MM/YYYY)");
            return;
        }
        
        // Validar CVV
        if (!cvv.matches("[0-9]{3,4}")) {
            enviarRespuestaJSON(response, false, "CVV inválido");
            return;
        }
        
        // Validar que no esté expirada
        String[] partes = expiracion.split("/");
        int mes = Integer.parseInt(partes[0]);
        int anio = Integer.parseInt(partes[1]);
        
        java.util.Calendar cal = java.util.Calendar.getInstance();
        int mesActual = cal.get(java.util.Calendar.MONTH) + 1;
        int anioActual = cal.get(java.util.Calendar.YEAR);
        
        if (anio < anioActual || (anio == anioActual && mes < mesActual)) {
            enviarRespuestaJSON(response, false, "Tarjeta expirada");
            return;
        }
        
        try (Connection conn = ConexionMySQL.conectar()) {
            // Verificar si la tarjeta ya existe
            String sqlCheck = "SELECT id FROM tarjetas WHERE numero_tarjeta = ?";
            PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck);
            stmtCheck.setString(1, numero);
            ResultSet rsCheck = stmtCheck.executeQuery();
            
            if (rsCheck.next()) {
                enviarRespuestaJSON(response, false, "Esta tarjeta ya está registrada");
                return;
            }
            
            // Insertar tarjeta (encriptación básica - en producción usar encriptación real)
            String sql = "INSERT INTO tarjetas (usuario_id, numero_tarjeta, nombre_titular, " +
                         "fecha_expiracion, cvv, tipo, banco) VALUES (?, ?, ?, ?, ?, ?, ?)";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, user.getId());
            stmt.setString(2, numero);
            stmt.setString(3, titular.toUpperCase());
            stmt.setString(4, expiracion);
            stmt.setString(5, cvv);
            stmt.setString(6, tipo);
            stmt.setString(7, banco);
            
            stmt.executeUpdate();
            
            // Registrar en auditoría (sin datos sensibles)
            String ultimos4 = numero.substring(numero.length() - 4);
            registrarAuditoria(user.getId(), "AGREGAR_TARJETA", 
                String.format("Tarjeta agregada: ****%s, Banco: %s", ultimos4, banco));
            
            System.out.println("✅ Tarjeta agregada: ****" + ultimos4);
            enviarRespuestaJSON(response, true, "Tarjeta agregada exitosamente");
            
        } catch (SQLException e) {
            System.err.println("❌ Error agregando tarjeta: " + e.getMessage());
            e.printStackTrace();
            enviarRespuestaJSON(response, false, "Error en la base de datos");
        }
    }
    
    /**
     * Elimina una tarjeta
     */
    private void eliminarTarjeta(HttpServletRequest request, HttpServletResponse response, Usuario user)
            throws IOException {
        
        String idStr = request.getParameter("id");
        
        if (idStr == null) {
            enviarRespuestaJSON(response, false, "ID no especificado");
            return;
        }
        
        try {
            int id = Integer.parseInt(idStr);
            
            try (Connection conn = ConexionMySQL.conectar()) {
                // Verificar que la tarjeta pertenezca al usuario
                String sqlCheck = "SELECT numero_tarjeta FROM tarjetas WHERE id = ? AND usuario_id = ?";
                PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck);
                stmtCheck.setInt(1, id);
                stmtCheck.setInt(2, user.getId());
                ResultSet rsCheck = stmtCheck.executeQuery();
                
                if (!rsCheck.next()) {
                    enviarRespuestaJSON(response, false, "Tarjeta no encontrada");
                    return;
                }
                
                String numero = rsCheck.getString("numero_tarjeta");
                String ultimos4 = numero.substring(numero.length() - 4);
                
                // Eliminar
                String sql = "DELETE FROM tarjetas WHERE id = ? AND usuario_id = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setInt(1, id);
                stmt.setInt(2, user.getId());
                stmt.executeUpdate();
                
                registrarAuditoria(user.getId(), "ELIMINAR_TARJETA", 
                    "Tarjeta eliminada: ****" + ultimos4);
                
                System.out.println("✅ Tarjeta eliminada: ****" + ultimos4);
                enviarRespuestaJSON(response, true, "Tarjeta eliminada");
                
            } catch (SQLException e) {
                System.err.println("❌ Error eliminando tarjeta: " + e.getMessage());
                enviarRespuestaJSON(response, false, "Error en la base de datos");
            }
            
        } catch (NumberFormatException e) {
            enviarRespuestaJSON(response, false, "ID inválido");
        }
    }
    
    /**
     * Envía respuesta JSON
     */
    private void enviarRespuestaJSON(HttpServletResponse response, boolean success, String message) 
            throws IOException {
        
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        JsonObject json = new JsonObject();
        json.addProperty("success", success);
        json.addProperty("message", message);
        
        out.print(gson.toJson(json));
    }
}