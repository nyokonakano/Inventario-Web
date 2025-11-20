package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;

import java.io.IOException;
import java.sql.*;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    
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

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String usuario = request.getParameter("usuario");
        String clave = request.getParameter("clave");
        
        if (usuario == null || clave == null || usuario.trim().isEmpty() || clave.trim().isEmpty()) {
            response.sendRedirect("login.jsp?error=datos_vacios");
            return;
        }

        try (Connection conn = ConexionMySQL.conectar()) {
            // Consulta que une usuarios con roles
            String sql = "SELECT u.id, u.usuario, u.nombre_completo, u.email, u.rol_id, r.nombre as rol_nombre, u.activo " +
                         "FROM usuarios u " +
                         "INNER JOIN roles r ON u.rol_id = r.id " +
                         "WHERE u.usuario = ? AND u.clave = ?";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, usuario);
            stmt.setString(2, clave);
            
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                // Verificar si el usuario está activo
                boolean activo = rs.getBoolean("activo");
                int userId = rs.getInt("id");
                
                if (!activo) {
                    // REGISTRAR INTENTO DE LOGIN FALLIDO (usuario inactivo)
                    registrarAuditoria(userId, "LOGIN_FALLIDO", "usuarios", 
                        String.valueOf(userId), 
                        "Intento de login con cuenta inactiva desde IP: " + request.getRemoteAddr());
                    
                    response.sendRedirect("login.jsp?error=usuario_inactivo");
                    return;
                }
                
                // Crear objeto Usuario
                Usuario user = new Usuario();
                user.setId(userId);
                user.setUsuario(rs.getString("usuario"));
                user.setNombreCompleto(rs.getString("nombre_completo"));
                user.setEmail(rs.getString("email"));
                user.setRolId(rs.getInt("rol_id"));
                user.setRolNombre(rs.getString("rol_nombre"));
                
                // Actualizar último acceso
                String sqlUpdate = "UPDATE usuarios SET ultimo_acceso = NOW() WHERE id = ?";
                PreparedStatement stmtUpdate = conn.prepareStatement(sqlUpdate);
                stmtUpdate.setInt(1, user.getId());
                stmtUpdate.executeUpdate();
                
                // CREAR SESIÓN con objeto Usuario completo
                HttpSession sesion = request.getSession();
                sesion.setAttribute("usuario", user);
                sesion.setAttribute("nombreUsuario", user.getUsuario());
                sesion.setAttribute("nombreCompleto", user.getNombreCompleto());
                sesion.setAttribute("rol", user.getRolNombre());
                sesion.setAttribute("usuarioId", user.getId());
                
                // REGISTRAR LOGIN EXITOSO EN AUDITORÍA
                String detalles = String.format(
                    "Login exitoso - IP: %s, Navegador: %s, Rol: %s",
                    request.getRemoteAddr(),
                    request.getHeader("User-Agent") != null ? 
                        request.getHeader("User-Agent").substring(0, Math.min(50, request.getHeader("User-Agent").length())) : "Desconocido",
                    user.getRolNombre()
                );
                
                registrarAuditoria(user.getId(), "LOGIN", "usuarios", 
                    String.valueOf(user.getId()), detalles);
                
                System.out.println("✅ Login exitoso: " + user.getUsuario() + " - Rol: " + user.getRolNombre());
                
                // Redirigir según el rol
                if (user.esAdministrador()) {
                    response.sendRedirect("admin.jsp");
                } else {
                    response.sendRedirect("index.jsp");
                }
                
            } else {
                // Credenciales incorrectas
                // Intentar encontrar el usuario para registrar el intento fallido
                String sqlUsuario = "SELECT id FROM usuarios WHERE usuario = ?";
                PreparedStatement stmtUsuario = conn.prepareStatement(sqlUsuario);
                stmtUsuario.setString(1, usuario);
                ResultSet rsUsuario = stmtUsuario.executeQuery();
                
                if (rsUsuario.next()) {
                    int userId = rsUsuario.getInt("id");
                    // REGISTRAR INTENTO FALLIDO
                    registrarAuditoria(userId, "LOGIN_FALLIDO", "usuarios", 
                        String.valueOf(userId), 
                        "Intento de login con contraseña incorrecta desde IP: " + request.getRemoteAddr());
                }
                
                response.sendRedirect("login.jsp?error=credenciales");
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error en login: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("login.jsp?error=sistema");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("login.jsp");
    }
}