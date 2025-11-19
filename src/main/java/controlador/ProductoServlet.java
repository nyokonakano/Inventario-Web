package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Future;

@WebServlet("/productos")
public class ProductoServlet extends HttpServlet{
    
    // ============ MÉTODO DE AUDITORÍA ============
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
        } catch (SQLException e) {
            System.err.println("⚠️ Error al registrar auditoría: " + e.getMessage());
        }
    }
    
    // ============ GET: LISTAR PRODUCTOS CON CACHÉ ============
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException{
        
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        Usuario user = (Usuario) sesion.getAttribute("usuario");
        String busqueda = request.getParameter("busqueda");
        
        List<Producto> lista;
        
        // 🎯 USAR CACHÉ para mejorar rendimiento
        if (busqueda == null || busqueda.trim().isEmpty()) {
            System.out.println("💾 Usando CacheManager para obtener productos...");
            lista = CacheManager.obtenerTodosLosProductos();
            
            registrarAuditoria(user.getId(), "VER_INVENTARIO", "productos", null, 
                "Consulta de inventario completo (CACHÉ)");
        } else {
            // Para búsquedas, consultar directamente la BD
            lista = buscarProductosBD(busqueda);
            
            registrarAuditoria(user.getId(), "BUSCAR_PRODUCTOS", "productos", null, 
                "Búsqueda: " + busqueda);
        }

        request.setAttribute("listaProductos", lista);
        request.getRequestDispatcher("inventario.jsp").forward(request, response);
    }
    
    // Método auxiliar para búsqueda
    private List<Producto> buscarProductosBD(String busqueda) {
        List<Producto> lista = new ArrayList<>();
        
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "SELECT * FROM productos WHERE LOWER(nombre) LIKE ? OR LOWER(categoria) LIKE ? ORDER BY nombre";
            PreparedStatement stmt = conn.prepareStatement(sql);
            String termino = "%" + busqueda.toLowerCase().trim() + "%";
            stmt.setString(1, termino);
            stmt.setString(2, termino);

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
            System.out.println("❌ Error al buscar productos: " + e.getMessage());
        }
        
        return lista;
    }
    
    // ============ POST: AGREGAR/ELIMINAR CON CONCURRENCIA ============
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        Usuario user = (Usuario) sesion.getAttribute("usuario");
        String accion = request.getParameter("accion");

        if ("eliminar".equals(accion)) {
            eliminarProducto(request, response, user);
        } else if ("actualizar_stock".equals(accion)) {
            // 🔒 USAR CONTROL DE CONCURRENCIA
            actualizarStockConcurrente(request, response, user);
        } else {
            agregarProducto(request, response, user);
        }
    }
    
    // ============ ELIMINAR PRODUCTO ============
    private void eliminarProducto(HttpServletRequest request, HttpServletResponse response, Usuario user) 
            throws IOException {
        
        if (!user.puedeEliminar()) {
            response.sendRedirect("productos?error=sin_permisos");
            return;
        }
        
        String nombreEliminar = request.getParameter("nombre");
        
        if (nombreEliminar == null || nombreEliminar.trim().isEmpty()) {
            response.sendRedirect("productos");
            return;
        }

        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "DELETE FROM productos WHERE nombre = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, nombreEliminar.trim());
            int filas = stmt.executeUpdate();
            
            if (filas > 0) {
                // 🗑️ INVALIDAR CACHÉ
                CacheManager.invalidarProducto(nombreEliminar);
                
                // 📝 REGISTRAR AUDITORÍA
                registrarAuditoria(user.getId(), "ELIMINAR_PRODUCTO", "productos", 
                    nombreEliminar, "Producto eliminado: " + nombreEliminar);
                
                // 🌐 NOTIFICAR VÍA WEBSOCKET
                InventarioWebSocket.notificarCambioProducto(nombreEliminar, "ELIMINADO", user.getUsuario());
                
                System.out.println("✅ Producto eliminado: " + nombreEliminar);
            }
            
        } catch (SQLException e) {
            System.out.println("❌ Error al eliminar producto: " + e.getMessage());
        }
        
        response.sendRedirect("productos");
    }
    
    // ============ AGREGAR PRODUCTO ============
    private void agregarProducto(HttpServletRequest request, HttpServletResponse response, Usuario user) 
            throws IOException {
        
        String nombre = request.getParameter("nombre");
        String cantidadStr = request.getParameter("cantidad");
        String precioStr = request.getParameter("precio");
        String categoria = request.getParameter("categoria");
        
        if (nombre == null || cantidadStr == null || precioStr == null || categoria == null ||
            nombre.trim().isEmpty() || categoria.trim().isEmpty()) {
            response.sendRedirect("index.jsp?error=datos_incompletos");
            return;
        }

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
                // Verificar si existe
                String sqlCheck = "SELECT COUNT(*) FROM productos WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(?))";
                PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck);
                stmtCheck.setString(1, producto.getNombre());
                ResultSet rsCheck = stmtCheck.executeQuery();
                
                if (rsCheck.next() && rsCheck.getInt(1) > 0) {
                    response.sendRedirect("index.jsp?error=producto_existe");
                    return;
                }
                
                // Insertar
                String sql = "INSERT INTO productos(nombre, cantidad, precio, categoria) VALUES (?, ?, ?, ?)";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setString(1, producto.getNombre());
                stmt.setInt(2, producto.getCantidad());
                stmt.setDouble(3, producto.getPrecio());
                stmt.setString(4, producto.getCategoria());
                stmt.executeUpdate();
                
                // 💾 AGREGAR AL CACHÉ
                CacheManager.actualizarProducto(producto);
                
                // 📝 REGISTRAR AUDITORÍA
                registrarAuditoria(user.getId(), "CREAR_PRODUCTO", "productos", 
                    producto.getNombre(), 
                    String.format("Producto: %s, Cantidad: %d, Precio: $%.2f, Categoría: %s", 
                    producto.getNombre(), producto.getCantidad(), producto.getPrecio(), producto.getCategoria()));
                
                // 🌐 NOTIFICAR VÍA WEBSOCKET
                InventarioWebSocket.notificarCambioProducto(producto.getNombre(), "CREADO", user.getUsuario());
                
                System.out.println("✅ Producto insertado: " + producto.getNombre());
                
            } catch (SQLException e) {
                System.out.println("❌ ERROR al insertar: " + e.getMessage());
                response.sendRedirect("index.jsp?error=base_datos");
                return;
            }
            
            response.sendRedirect("index.jsp?mensaje=agregado");
            
        } catch (NumberFormatException e) {
            response.sendRedirect("index.jsp?error=formato_numeros");
        }
    }
    
    // ============ ACTUALIZAR STOCK CON CONTROL DE CONCURRENCIA ============
    private void actualizarStockConcurrente(HttpServletRequest request, HttpServletResponse response, Usuario user) 
            throws IOException {
        
        String nombreProducto = request.getParameter("nombre");
        String cantidadStr = request.getParameter("cantidad_cambio");
        
        if (nombreProducto == null || cantidadStr == null) {
            response.sendRedirect("productos?error=datos_incompletos");
            return;
        }
        
        try {
            int cantidadCambio = Integer.parseInt(cantidadStr);
            
            // 🔒 ACTUALIZACIÓN THREAD-SAFE
            boolean exito = ProductoConcurrenteManager.actualizarStockSeguro(
                nombreProducto, cantidadCambio, user.getId()
            );
            
            if (exito) {
                // 🗑️ INVALIDAR CACHÉ
                CacheManager.invalidarProducto(nombreProducto);
                
                // 🌐 NOTIFICAR VÍA WEBSOCKET
                InventarioWebSocket.notificarCambioProducto(nombreProducto, "STOCK_ACTUALIZADO", user.getUsuario());
                
                // Verificar si quedó con stock bajo
                int stockActual = ProductoConcurrenteManager.obtenerStockActual(nombreProducto);
                if (stockActual < 10 && stockActual > 0) {
                    InventarioWebSocket.notificarStockBajo(nombreProducto, stockActual);
                }
                
                response.sendRedirect("productos?mensaje=stock_actualizado");
            } else {
                response.sendRedirect("productos?error=stock_insuficiente");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect("productos?error=formato_invalido");
        }
    }
}