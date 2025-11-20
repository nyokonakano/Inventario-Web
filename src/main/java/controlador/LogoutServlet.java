package controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import modelo.*;
import java.io.IOException;
import java.sql.*;

@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {
    
    /**
     * Registra una acción en la tabla de auditoría
     */
    private void registrarAuditoria(int usuarioId, String accion, String tabla, 
                                    String registroId, String detalles) {
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "INSERT INTO auditoria (usuario_id, accion, tabla, registro_id, detalles) " +
                         "VALUES (?, ?, ?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, usuarioId);
            stmt.setString(2, accion);
            stmt.setString(3, tabla);
            stmt.setString(4, registroId);
            stmt.setString(5, detalles);
            stmt.executeUpdate();
            System.out.println("📝 Auditoría registrada: " + accion);
        } catch (SQLException e) {
            System.err.println("⚠️ Error al registrar auditoría: " + e.getMessage());
        }
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession sesion = request.getSession(false);
        
        if (sesion != null) {
            // Obtener información del usuario antes de cerrar sesión
            Usuario user = (Usuario) sesion.getAttribute("usuario");
            
            if (user != null) {
                // REGISTRAR LOGOUT EN AUDITORÍA
                String detalles = String.format(
                    "Cierre de sesión - Usuario: %s, Rol: %s, IP: %s",
                    user.getUsuario(),
                    user.getRolNombre(),
                    request.getRemoteAddr()
                );
                
                registrarAuditoria(user.getId(), "LOGOUT", "usuarios", 
                    String.valueOf(user.getId()), detalles);
                
                System.out.println("👋 Logout: " + user.getUsuario());
            }
            
            // Invalidar sesión
            sesion.invalidate();
        }
        
        response.sendRedirect("login.jsp");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doPost(request, response);
    }
}