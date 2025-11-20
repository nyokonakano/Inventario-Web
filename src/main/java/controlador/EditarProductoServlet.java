package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;

import java.io.IOException;
import java.sql.*;

@WebServlet("/editar")
public class EditarProductoServlet extends HttpServlet {
    
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
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        Usuario user = (Usuario) sesion.getAttribute("usuario");
        
        // Verificar permisos
        if (!user.puedeEditar()) {
            response.sendRedirect("productos?error=sin_permisos");
            return;
        }
        
        String nombre = request.getParameter("nombre");
        if (nombre == null || nombre.trim().isEmpty()) {
            response.sendRedirect("productos");
            return;
        }
        
        nombre = nombre.trim();
        Producto producto = null;

        try (Connection conn = ConexionMySQL.conectar()){
            String sql = "SELECT * FROM productos WHERE TRIM(nombre) = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, nombre);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                producto = new Producto();
                producto.setNombre(rs.getString("nombre"));
                producto.setCantidad(rs.getInt("cantidad"));
                producto.setPrecio(rs.getDouble("precio"));
                producto.setCategoria(rs.getString("categoria"));
            }
            
            // REGISTRAR EN AUDITORÍA
            if (producto != null) {
                registrarAuditoria(user.getId(), "CONSULTAR_EDITAR", "productos", 
                    nombre, "Accedió al formulario de edición del producto: " + nombre);
            }
            
        } catch (SQLException e) {
            System.out.println("❌ Error al buscar producto: " + e.getMessage());
            e.printStackTrace();
        }

        request.setAttribute("producto", producto);
        request.getRequestDispatcher("editar.jsp").forward(request, response);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Configurar codificación
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        Usuario user = (Usuario) sesion.getAttribute("usuario");
        
        // Verificar permisos
        if (!user.puedeEditar()) {
            response.sendRedirect("productos?error=sin_permisos");
            return;
        }
        
        // Validar parámetros
        String nombre = request.getParameter("nombre");
        String cantidadStr = request.getParameter("cantidad");
        String precioStr = request.getParameter("precio");
        String categoria = request.getParameter("categoria");
        
        if (nombre == null || cantidadStr == null || precioStr == null || categoria == null) {
            response.sendRedirect("productos");
            return;
        }
        
        try {
            Producto producto = new Producto();
            producto.setNombre(nombre.trim());
            producto.setCantidad(Integer.parseInt(cantidadStr));
            producto.setPrecio(Double.parseDouble(precioStr));
            producto.setCategoria(categoria.trim());
            
            // Guardar valores anteriores para auditoría
            String valoresAnteriores = "";

            try (Connection conn = ConexionMySQL.conectar()) {
                // Obtener valores anteriores
                String sqlAntes = "SELECT cantidad, precio, categoria FROM productos WHERE nombre = ?";
                PreparedStatement stmtAntes = conn.prepareStatement(sqlAntes);
                stmtAntes.setString(1, producto.getNombre());
                ResultSet rsAntes = stmtAntes.executeQuery();
                
                if (rsAntes.next()) {
                    valoresAnteriores = String.format(
                        "Antes: Cantidad=%d, Precio=%.2f, Categoría=%s",
                        rsAntes.getInt("cantidad"),
                        rsAntes.getDouble("precio"),
                        rsAntes.getString("categoria")
                    );
                }
                
                // Actualizar producto
                String sql = "UPDATE productos SET cantidad = ?, precio = ?, categoria = ? WHERE nombre = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setInt(1, producto.getCantidad());
                stmt.setDouble(2, producto.getPrecio());
                stmt.setString(3, producto.getCategoria());
                stmt.setString(4, producto.getNombre());
                
                int filasActualizadas = stmt.executeUpdate();
                System.out.println("✅ Filas actualizadas: " + filasActualizadas);
                
                if (filasActualizadas > 0) {
                    // REGISTRAR EN AUDITORÍA
                    String detalles = String.format(
                        "%s | Después: Cantidad=%d, Precio=%.2f, Categoría=%s",
                        valoresAnteriores,
                        producto.getCantidad(),
                        producto.getPrecio(),
                        producto.getCategoria()
                    );
                    
                    registrarAuditoria(user.getId(), "EDITAR_PRODUCTO", "productos", 
                        producto.getNombre(), detalles);
                }
                
            } catch (SQLException e) {
                System.out.println("❌ Error al actualizar: " + e.getMessage());
                e.printStackTrace();
            }
        } catch (NumberFormatException e) {
            System.out.println("❌ Error en formato de números: " + e.getMessage());
        }

        response.sendRedirect("productos");
    }
}