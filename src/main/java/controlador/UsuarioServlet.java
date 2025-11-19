package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/usuarios")
public class UsuarioServlet extends HttpServlet {
    
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
    
    // Verificar que el usuario sea administrador
    private boolean esAdministrador(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        HttpSession session = request.getSession(false);
        
        System.out.println("🔍 DEBUG - Verificando sesión...");
        System.out.println("   Sesión: " + (session != null ? "existe" : "null"));
        
        if (session == null) {
            System.out.println("❌ Sesión es null, redirigiendo a login");
            response.sendRedirect("login.jsp");
            return false;
        }
        
        Usuario user = (Usuario) session.getAttribute("usuario");
        System.out.println("   Usuario en sesión: " + (user != null ? user.getUsuario() : "null"));
        
        if (user == null) {
            System.out.println("❌ Usuario es null, redirigiendo a login");
            response.sendRedirect("login.jsp");
            return false;
        }
        
        System.out.println("   Rol: " + user.getRolNombre());
        System.out.println("   Es administrador: " + user.esAdministrador());
        
        if (!user.esAdministrador()) {
            System.out.println("❌ Usuario no es administrador, acceso denegado");
            response.sendRedirect("index.jsp?error=acceso_denegado");
            return false;
        }
        
        System.out.println("✅ Usuario autorizado");
        return true;
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        System.out.println("\n🔵 ========== INICIO UsuarioServlet.doGet() ==========");
        
        if (!esAdministrador(request, response)) {
            System.out.println("❌ No pasó verificación de administrador");
            return;
        }
        
        Usuario adminUser = (Usuario) request.getSession().getAttribute("usuario");
        List<Usuario> listaUsuarios = new ArrayList<>();
        
        System.out.println("🔗 Intentando conectar a la base de datos...");
        
        try (Connection conn = ConexionMySQL.conectar()) {
            
            System.out.println("✅ Conexión establecida");
            
            String sql = "SELECT u.id, u.usuario, u.nombre_completo, u.email, " +
                         "u.activo, u.fecha_creacion, r.nombre as rol_nombre " +
                         "FROM usuarios u " +
                         "INNER JOIN roles r ON u.rol_id = r.id " +
                         "ORDER BY u.fecha_creacion DESC";
            
            System.out.println("📋 Ejecutando SQL: " + sql);
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            ResultSet rs = stmt.executeQuery();
            
            int contador = 0;
            while (rs.next()) {
                contador++;
                Usuario u = new Usuario();
                u.setId(rs.getInt("id"));
                u.setUsuario(rs.getString("usuario"));
                u.setNombreCompleto(rs.getString("nombre_completo"));
                u.setEmail(rs.getString("email"));
                u.setActivo(rs.getBoolean("activo"));
                u.setRolNombre(rs.getString("rol_nombre"));
                u.setFechaCreacion(rs.getTimestamp("fecha_creacion"));
                listaUsuarios.add(u);
                
                System.out.println("   👤 Usuario " + contador + ": " + u.getUsuario() + " - " + u.getNombreCompleto());
            }
            
            System.out.println("📊 Total usuarios encontrados: " + listaUsuarios.size());
            
            if (listaUsuarios.isEmpty()) {
                System.out.println("⚠️ ADVERTENCIA: No se encontraron usuarios en la base de datos");
                System.out.println("   Verifica que las tablas 'usuarios' y 'roles' tengan datos");
            }
            
            // REGISTRAR CONSULTA EN AUDITORÍA
            registrarAuditoria(adminUser.getId(), "CONSULTAR_USUARIOS", "usuarios", null, 
                "Consultó la lista de usuarios (" + listaUsuarios.size() + " usuarios)");
            
        } catch (SQLException e) {
            System.err.println("❌ ERROR SQL: " + e.getMessage());
            System.err.println("   SQLState: " + e.getSQLState());
            System.err.println("   ErrorCode: " + e.getErrorCode());
            e.printStackTrace();
        }
        
        System.out.println("📦 Enviando " + listaUsuarios.size() + " usuarios al JSP");
        request.setAttribute("listaUsuarios", listaUsuarios);
        
        System.out.println("➡️ Redirigiendo a usuarios.jsp");
        request.getRequestDispatcher("usuarios.jsp").forward(request, response);
        
        System.out.println("🔵 ========== FIN UsuarioServlet.doGet() ==========\n");
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        if (!esAdministrador(request, response)) return;
        
        request.setCharacterEncoding("UTF-8");
        String accion = request.getParameter("accion");
        
        System.out.println("📝 POST recibido - Acción: " + accion);
        
        if ("crear".equals(accion)) {
            crearUsuario(request, response);
        } else if ("eliminar".equals(accion)) {
            eliminarUsuario(request, response);
        } else if ("cambiar_estado".equals(accion)) {
            cambiarEstado(request, response);
        }
    }
    
    private void crearUsuario(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        
        Usuario adminUser = (Usuario) request.getSession().getAttribute("usuario");
        String usuario = request.getParameter("usuario");
        String clave = request.getParameter("clave");
        String nombreCompleto = request.getParameter("nombre_completo");
        String email = request.getParameter("email");
        String rolIdStr = request.getParameter("rol_id");
        
        if (usuario == null || clave == null || nombreCompleto == null || rolIdStr == null) {
            response.sendRedirect("usuarios?error=datos_incompletos");
            return;
        }
        
        try (Connection conn = ConexionMySQL.conectar()) {
            // Verificar si el usuario ya existe
            String sqlCheck = "SELECT COUNT(*) FROM usuarios WHERE usuario = ?";
            PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck);
            stmtCheck.setString(1, usuario);
            ResultSet rs = stmtCheck.executeQuery();
            
            if (rs.next() && rs.getInt(1) > 0) {
                response.sendRedirect("usuarios?error=usuario_existe");
                return;
            }
            
            // Insertar nuevo usuario
            String sql = "INSERT INTO usuarios (usuario, clave, nombre_completo, email, rol_id) " +
                         "VALUES (?, ?, ?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            stmt.setString(1, usuario);
            stmt.setString(2, clave);
            stmt.setString(3, nombreCompleto);
            stmt.setString(4, email);
            stmt.setInt(5, Integer.parseInt(rolIdStr));
            stmt.executeUpdate();
            
            // Obtener el ID del nuevo usuario
            ResultSet rsKeys = stmt.getGeneratedKeys();
            int nuevoId = 0;
            if (rsKeys.next()) {
                nuevoId = rsKeys.getInt(1);
            }
            
            // REGISTRAR EN AUDITORÍA
            String detalles = String.format(
                "Usuario creado: %s, Nombre: %s, Email: %s, Rol ID: %s",
                usuario, nombreCompleto, email, rolIdStr
            );
            registrarAuditoria(adminUser.getId(), "CREAR_USUARIO", "usuarios", 
                String.valueOf(nuevoId), detalles);
            
            System.out.println("✅ Usuario creado: " + usuario);
            response.sendRedirect("usuarios?mensaje=usuario_creado");
            
        } catch (SQLException e) {
            System.err.println("❌ Error al crear usuario: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("usuarios?error=sistema");
        }
    }
    
    private void eliminarUsuario(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        
        Usuario adminUser = (Usuario) request.getSession().getAttribute("usuario");
        String idStr = request.getParameter("id");
        
        if (idStr == null) {
            response.sendRedirect("usuarios");
            return;
        }
        
        int userId = Integer.parseInt(idStr);
        String usuarioEliminado = "";
        
        try (Connection conn = ConexionMySQL.conectar()) {
            // Obtener información del usuario antes de eliminar
            String sqlInfo = "SELECT usuario, nombre_completo FROM usuarios WHERE id = ?";
            PreparedStatement stmtInfo = conn.prepareStatement(sqlInfo);
            stmtInfo.setInt(1, userId);
            ResultSet rsInfo = stmtInfo.executeQuery();
            
            if (rsInfo.next()) {
                usuarioEliminado = rsInfo.getString("usuario") + " (" + rsInfo.getString("nombre_completo") + ")";
            }
            
            // Eliminar usuario
            String sql = "DELETE FROM usuarios WHERE id = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, userId);
            int filas = stmt.executeUpdate();
            
            if (filas > 0) {
                // REGISTRAR EN AUDITORÍA
                registrarAuditoria(adminUser.getId(), "ELIMINAR_USUARIO", "usuarios", 
                    idStr, "Usuario eliminado: " + usuarioEliminado);
            }
            
            System.out.println("✅ Usuario eliminado. Filas: " + filas);
            response.sendRedirect("usuarios?mensaje=usuario_eliminado");
            
        } catch (SQLException e) {
            System.err.println("❌ Error al eliminar usuario: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("usuarios?error=sistema");
        }
    }
    
    private void cambiarEstado(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        
        Usuario adminUser = (Usuario) request.getSession().getAttribute("usuario");
        String idStr = request.getParameter("id");
        String activoStr = request.getParameter("activo");
        
        if (idStr == null || activoStr == null) {
            response.sendRedirect("usuarios");
            return;
        }
        
        int userId = Integer.parseInt(idStr);
        boolean nuevoEstado = Boolean.parseBoolean(activoStr);
        String usuarioAfectado = "";
        
        try (Connection conn = ConexionMySQL.conectar()) {
            // Obtener información del usuario
            String sqlInfo = "SELECT usuario FROM usuarios WHERE id = ?";
            PreparedStatement stmtInfo = conn.prepareStatement(sqlInfo);
            stmtInfo.setInt(1, userId);
            ResultSet rsInfo = stmtInfo.executeQuery();
            
            if (rsInfo.next()) {
                usuarioAfectado = rsInfo.getString("usuario");
            }
            
            // Cambiar estado
            String sql = "UPDATE usuarios SET activo = ? WHERE id = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setBoolean(1, nuevoEstado);
            stmt.setInt(2, userId);
            stmt.executeUpdate();
            
            // REGISTRAR EN AUDITORÍA
            String detalles = String.format(
                "Estado cambiado a %s para el usuario: %s",
                nuevoEstado ? "ACTIVO" : "INACTIVO",
                usuarioAfectado
            );
            registrarAuditoria(adminUser.getId(), "CAMBIAR_ESTADO_USUARIO", "usuarios", 
                idStr, detalles);
            
            System.out.println("✅ Estado de usuario actualizado");
            response.sendRedirect("usuarios?mensaje=estado_actualizado");
            
        } catch (SQLException e) {
            System.err.println("❌ Error al cambiar estado: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("usuarios?error=sistema");
        }
    }
}