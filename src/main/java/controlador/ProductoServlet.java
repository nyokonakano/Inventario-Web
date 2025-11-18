package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/productos")
public class ProductoServlet extends HttpServlet{
    
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
    
    // GET para mostrar los productos
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException{
        
        // Configurar codificación
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        Usuario user = (Usuario) sesion.getAttribute("usuario");
        List<Producto> lista = new ArrayList<>();
        String busqueda = request.getParameter("busqueda");
        
        try (Connection conn = ConexionMySQL.conectar()) {
            PreparedStatement stmt;
            if (busqueda != null && !busqueda.trim().isEmpty()) {
                // Búsqueda con LIKE (compatible con MySQL)
                String sql = "SELECT * FROM productos WHERE LOWER(nombre) LIKE ? OR LOWER(categoria) LIKE ? ORDER BY nombre";
                stmt = conn.prepareStatement(sql);
                String termino = "%" + busqueda.toLowerCase().trim() + "%";
                stmt.setString(1, termino);
                stmt.setString(2, termino);
                
                // Registrar búsqueda en auditoría
                registrarAuditoria(user.getId(), "BUSCAR_PRODUCTOS", "productos", null, 
                    "Búsqueda: " + busqueda);
            } else {
                String sql = "SELECT * FROM productos ORDER BY nombre";
                stmt = conn.prepareStatement(sql);
                
                // Registrar consulta general
                registrarAuditoria(user.getId(), "VER_INVENTARIO", "productos", null, 
                    "Consulta de inventario completo");
            }

            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Producto p = new Producto();
                p.setNombre(rs.getString("nombre"));
                p.setCantidad(rs.getInt("cantidad"));
                p.setPrecio(rs.getDouble("precio"));
                p.setCategoria(rs.getString("categoria"));
                lista.add(p);
            }

        } catch (SQLException e) {
            System.out.println("❌ Error al consultar productos: " + e.getMessage());
            e.printStackTrace();
        }

        request.setAttribute("listaProductos", lista);
        request.getRequestDispatcher("inventario.jsp").forward(request, response);
    }
    
    // POST para agregar/eliminar productos
    @Override
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
        String accion = request.getParameter("accion");
        System.out.println("📌 Acción: " + accion);

        if ("eliminar".equals(accion)) {
            // ELIMINAR PRODUCTO
            if (!user.puedeEliminar()) {
                response.sendRedirect("productos?error=sin_permisos");
                return;
            }
            
            String nombreEliminar = request.getParameter("nombre");
            
            if (nombreEliminar == null || nombreEliminar.trim().isEmpty()) {
                response.sendRedirect("productos");
                return;
            }
            
            System.out.println("🗑️ Producto a eliminar: " + nombreEliminar);

            try (Connection conn = ConexionMySQL.conectar()) {
                String sql = "DELETE FROM productos WHERE nombre = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setString(1, nombreEliminar.trim());
                int filas = stmt.executeUpdate();
                
                if (filas > 0) {
                    System.out.println("✅ Filas eliminadas: " + filas);
                    
                    // REGISTRAR EN AUDITORÍA
                    registrarAuditoria(user.getId(), "ELIMINAR_PRODUCTO", "productos", 
                        nombreEliminar, "Producto eliminado: " + nombreEliminar);
                }
                
            } catch (SQLException e) {
                System.out.println("❌ Error al eliminar producto: " + e.getMessage());
                e.printStackTrace();
            }
            
            response.sendRedirect("productos");
            
        } else {
            // AGREGAR PRODUCTO
            String nombre = request.getParameter("nombre");
            String cantidadStr = request.getParameter("cantidad");
            String precioStr = request.getParameter("precio");
            String categoria = request.getParameter("categoria");
            
            // Validar
            if (nombre == null || cantidadStr == null || precioStr == null || categoria == null ||
                nombre.trim().isEmpty() || categoria.trim().isEmpty()) {
                response.sendRedirect("index.jsp?error=datos_incompletos");
                return;
            }

            System.out.println("📝 Nombre: " + nombre);
            System.out.println("📝 Cantidad: " + cantidadStr);
            System.out.println("📝 Precio: " + precioStr);
            System.out.println("📝 Categoría: " + categoria);

            try {
                int cantidad = Integer.parseInt(cantidadStr);
                double precio = Double.parseDouble(precioStr);
                
                if (cantidad < 0 || precio < 0) {
                    response.sendRedirect("index.jsp?error=valores_negativos");
                    return;
                }

                Producto producto = new Producto();
                producto.setNombre(nombre.trim());
                producto.setCantidad(cantidad);
                producto.setPrecio(precio);
                producto.setCategoria(categoria.trim());

                try (Connection conn = ConexionMySQL.conectar()) {
                    // Verificar si el producto ya existe
                    String sqlCheck = "SELECT COUNT(*) FROM productos WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(?))";
                    PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck);
                    stmtCheck.setString(1, producto.getNombre());
                    ResultSet rsCheck = stmtCheck.executeQuery();
                    
                    if (rsCheck.next() && rsCheck.getInt(1) > 0) {
                        response.sendRedirect("index.jsp?error=producto_existe");
                        return;
                    }
                    
                    // Insertar producto
                    String sql = "INSERT INTO productos(nombre, cantidad, precio, categoria) VALUES (?, ?, ?, ?)";
                    PreparedStatement stmt = conn.prepareStatement(sql);
                    stmt.setString(1, producto.getNombre());
                    stmt.setInt(2, producto.getCantidad());
                    stmt.setDouble(3, producto.getPrecio());
                    stmt.setString(4, producto.getCategoria());
                    stmt.executeUpdate();
                    System.out.println("✅ Producto insertado correctamente");
                    
                    // REGISTRAR EN AUDITORÍA
                    registrarAuditoria(user.getId(), "CREAR_PRODUCTO", "productos", 
                        producto.getNombre(), 
                        "Producto: " + producto.getNombre() + ", Cantidad: " + producto.getCantidad() + 
                        ", Precio: $" + producto.getPrecio() + ", Categoría: " + producto.getCategoria());
                    
                } catch (SQLException e) {
                    System.out.println("❌ ERROR al insertar producto: " + e.getMessage());
                    e.printStackTrace();
                    response.sendRedirect("index.jsp?error=base_datos");
                    return;
                }
                
                response.sendRedirect("index.jsp?mensaje=agregado");
                
            } catch (NumberFormatException e) {
                System.out.println("❌ Error en formato de números: " + e.getMessage());
                response.sendRedirect("index.jsp?error=formato_numeros");
            }
        }
    }
}