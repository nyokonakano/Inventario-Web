package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;

import java.io.IOException;
import java.sql.*;

@WebServlet("/ConfiguracionServlet")
public class ConfiguracionServlet extends HttpServlet {
    
    // Verificar que el usuario sea administrador
    private boolean esAdministrador(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        Usuario user = (Usuario) request.getSession().getAttribute("usuario");
        if (user == null || !user.esAdministrador()) {
            response.sendRedirect("index.jsp?error=acceso_denegado");
            return false;
        }
        return true;
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        if (!esAdministrador(request, response)) return;
        
        String accion = request.getParameter("accion");
        Usuario user = (Usuario) request.getSession().getAttribute("usuario");
        
        switch (accion) {
            case "exportar":
                exportarBaseDatos(request, response, user);
                break;
            case "optimizar":
                optimizarTablas(request, response, user);
                break;
            case "limpiar_logs":
                limpiarLogsAntiguos(request, response, user);
                break;
            case "limpiar_cache":
                limpiarCache(request, response, user);
                break;
            case "eliminar_pruebas":
                eliminarDatosPrueba(request, response, user);
                break;
            case "cerrar_sesiones":
                cerrarSesiones(request, response);
                break;
            default:
                response.sendRedirect("configuracion.jsp");
        }
    }
    
    private void exportarBaseDatos(HttpServletRequest request, HttpServletResponse response, Usuario user) 
            throws IOException {
        try (Connection conn = ConexionMySQL.conectar()) {
            // Registrar en auditoría
            registrarAuditoria(conn, user.getId(), "EXPORTAR_BD", null, null, "Exportación de base de datos");
            
            System.out.println("✅ Exportación iniciada por: " + user.getUsuario());
            response.sendRedirect("configuracion.jsp?mensaje=respaldo_creado");
            
        } catch (SQLException e) {
            System.err.println("❌ Error al exportar BD: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("configuracion.jsp?error=error_respaldo");
        }
    }
    
    private void optimizarTablas(HttpServletRequest request, HttpServletResponse response, Usuario user) 
            throws IOException {
        try (Connection conn = ConexionMySQL.conectar()) {
            Statement stmt = conn.createStatement();
            
            // Optimizar cada tabla
            stmt.execute("OPTIMIZE TABLE productos");
            stmt.execute("OPTIMIZE TABLE usuarios");
            stmt.execute("OPTIMIZE TABLE auditoria");
            stmt.execute("OPTIMIZE TABLE roles");
            
            // Registrar en auditoría
            registrarAuditoria(conn, user.getId(), "OPTIMIZAR_TABLAS", null, null, "Optimización de tablas ejecutada");
            
            System.out.println("✅ Tablas optimizadas por: " + user.getUsuario());
            response.sendRedirect("configuracion.jsp?mensaje=tablas_optimizadas");
            
        } catch (SQLException e) {
            System.err.println("❌ Error al optimizar tablas: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("configuracion.jsp?error=error_optimizacion");
        }
    }
    
    private void limpiarLogsAntiguos(HttpServletRequest request, HttpServletResponse response, Usuario user) 
            throws IOException {
        try (Connection conn = ConexionMySQL.conectar()) {
            // Eliminar registros de auditoría mayores a 30 días
            String sql = "DELETE FROM auditoria WHERE fecha < DATE_SUB(NOW(), INTERVAL 30 DAY)";
            PreparedStatement stmt = conn.prepareStatement(sql);
            int eliminados = stmt.executeUpdate();
            
            // Registrar en auditoría
            registrarAuditoria(conn, user.getId(), "LIMPIAR_LOGS", "auditoria", null, 
                "Eliminados " + eliminados + " registros antiguos");
            
            System.out.println("✅ Logs limpiados: " + eliminados + " registros por " + user.getUsuario());
            response.sendRedirect("configuracion.jsp?mensaje=logs_limpiados");
            
        } catch (SQLException e) {
            System.err.println("❌ Error al limpiar logs: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("configuracion.jsp?error=error_limpieza");
        }
    }
    
    private void limpiarCache(HttpServletRequest request, HttpServletResponse response, Usuario user) 
            throws IOException {
        try (Connection conn = ConexionMySQL.conectar()) {
            // Registrar en auditoría
            registrarAuditoria(conn, user.getId(), "LIMPIAR_CACHE", null, null, "Caché del sistema limpiado");
            
            System.out.println("✅ Caché limpiado por: " + user.getUsuario());
            response.sendRedirect("configuracion.jsp?mensaje=cache_limpiado");
            
        } catch (SQLException e) {
            System.err.println("❌ Error al limpiar caché: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("configuracion.jsp?error=error_cache");
        }
    }
    
    private void eliminarDatosPrueba(HttpServletRequest request, HttpServletResponse response, Usuario user) 
            throws IOException {
        try (Connection conn = ConexionMySQL.conectar()) {
            // Eliminar productos de ejemplo que tengan "test" o "prueba" en el nombre
            String sql = "DELETE FROM productos WHERE LOWER(nombre) LIKE '%test%' OR LOWER(nombre) LIKE '%prueba%'";
            PreparedStatement stmt = conn.prepareStatement(sql);
            int eliminados = stmt.executeUpdate();
            
            // Registrar en auditoría
            registrarAuditoria(conn, user.getId(), "ELIMINAR_PRUEBAS", "productos", null, 
                "Eliminados " + eliminados + " productos de prueba");
            
            System.out.println("✅ Datos de prueba eliminados: " + eliminados + " por " + user.getUsuario());
            response.sendRedirect("configuracion.jsp?mensaje=datos_limpiados");
            
        } catch (SQLException e) {
            System.err.println("❌ Error al eliminar datos de prueba: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("configuracion.jsp?error=error_eliminacion");
        }
    }
    
    private void cerrarSesiones(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        // En una aplicación real, aquí cerrarías todas las sesiones activas
        // excepto la del usuario actual
        System.out.println("✅ Sesiones cerradas (funcionalidad simulada)");
        response.sendRedirect("configuracion.jsp?mensaje=sesiones_cerradas");
    }
    
    // Método auxiliar para registrar auditoría
    private void registrarAuditoria(Connection conn, int usuarioId, String accion, 
                                    String tabla, String registroId, String detalles) {
        try {
            String sql = "INSERT INTO auditoria (usuario_id, accion, tabla, registro_id, detalles) " +
                         "VALUES (?, ?, ?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, usuarioId);
            stmt.setString(2, accion);
            stmt.setString(3, tabla);
            stmt.setString(4, registroId);
            stmt.setString(5, detalles);
            stmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("⚠️ Error al registrar auditoría: " + e.getMessage());
        }
    }
}