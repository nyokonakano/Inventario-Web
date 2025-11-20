package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonArray;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.*;

@WebServlet("/CarritoServlet")
public class CarritoServlet extends HttpServlet {
    
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
            stmt.setString(3, "carritos");
            stmt.setString(4, null);
            stmt.setString(5, detalles);
            stmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("⚠️ Error en auditoría: " + e.getMessage());
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        Usuario user = (Usuario) request.getSession().getAttribute("usuario");
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        String accion = request.getParameter("accion");
        
        if ("listar".equals(accion)) {
            listarCarrito(request, response, user);
        } else if ("contar".equals(accion)) {
            contarItems(response, user);
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
        
        switch (accion) {
            case "agregar":
                agregarAlCarrito(request, response, user);
                break;
            case "actualizar":
                actualizarCantidad(request, response, user);
                break;
            case "eliminar":
                eliminarDelCarrito(request, response, user);
                break;
            case "vaciar":
                vaciarCarrito(request, response, user);
                break;
            default:
                enviarRespuestaJSON(response, false, "Acción no válida");
        }
    }
    
    /**
     * Lista todos los items del carrito
     */
    private void listarCarrito(HttpServletRequest request, HttpServletResponse response, Usuario user)
            throws IOException {
        
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "SELECT producto_nombre, cantidad, precio_unitario " +
                         "FROM carritos WHERE usuario_id = ? ORDER BY fecha_agregado DESC";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, user.getId());
            ResultSet rs = stmt.executeQuery();
            
            JsonObject respuesta = new JsonObject();
            JsonArray items = new JsonArray();
            double total = 0;
            
            while (rs.next()) {
                JsonObject item = new JsonObject();
                item.addProperty("producto", rs.getString("producto_nombre"));
                item.addProperty("cantidad", rs.getInt("cantidad"));
                item.addProperty("precio", rs.getDouble("precio_unitario"));
                
                double subtotal = rs.getInt("cantidad") * rs.getDouble("precio_unitario");
                total += subtotal;
                
                items.add(item);
            }
            
            respuesta.add("items", items);
            respuesta.addProperty("total", total);
            respuesta.addProperty("itemCount", items.size());
            
            out.print(gson.toJson(respuesta));
            
        } catch (SQLException e) {
            System.err.println("❌ Error listando carrito: " + e.getMessage());
            e.printStackTrace();
            enviarRespuestaJSON(response, false, "Error al cargar carrito");
        }
    }
    
    /**
     * Agrega un producto al carrito
     */
    private void agregarAlCarrito(HttpServletRequest request, HttpServletResponse response, Usuario user)
            throws IOException {
        
        String producto = request.getParameter("producto");
        String cantidadStr = request.getParameter("cantidad");
        String precioStr = request.getParameter("precio");
        
        if (producto == null || cantidadStr == null || precioStr == null) {
            enviarRespuestaJSON(response, false, "Parámetros incompletos");
            return;
        }
        
        try {
            int cantidad = Integer.parseInt(cantidadStr);
            double precio = Double.parseDouble(precioStr);
            
            if (cantidad <= 0) {
                enviarRespuestaJSON(response, false, "Cantidad inválida");
                return;
            }
            
            try (Connection conn = ConexionMySQL.conectar()) {
                // Verificar stock disponible
                String sqlStock = "SELECT cantidad FROM productos WHERE nombre = ?";
                PreparedStatement stmtStock = conn.prepareStatement(sqlStock);
                stmtStock.setString(1, producto);
                ResultSet rsStock = stmtStock.executeQuery();
                
                if (!rsStock.next()) {
                    enviarRespuestaJSON(response, false, "Producto no encontrado");
                    return;
                }
                
                int stockDisponible = rsStock.getInt("cantidad");
                
                // Verificar si ya está en el carrito
                String sqlCheck = "SELECT cantidad FROM carritos WHERE usuario_id = ? AND producto_nombre = ?";
                PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck);
                stmtCheck.setInt(1, user.getId());
                stmtCheck.setString(2, producto);
                ResultSet rsCheck = stmtCheck.executeQuery();
                
                int cantidadEnCarrito = 0;
                if (rsCheck.next()) {
                    cantidadEnCarrito = rsCheck.getInt("cantidad");
                }
                
                int cantidadTotal = cantidadEnCarrito + cantidad;
                
                if (cantidadTotal > stockDisponible) {
                    enviarRespuestaJSON(response, false, 
                        "Stock insuficiente. Disponible: " + stockDisponible + 
                        ", En carrito: " + cantidadEnCarrito);
                    return;
                }
                
                // Insertar o actualizar
                String sql;
                if (cantidadEnCarrito > 0) {
                    sql = "UPDATE carritos SET cantidad = cantidad + ?, precio_unitario = ? " +
                          "WHERE usuario_id = ? AND producto_nombre = ?";
                } else {
                    sql = "INSERT INTO carritos (cantidad, precio_unitario, usuario_id, producto_nombre) " +
                          "VALUES (?, ?, ?, ?)";
                }
                
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setInt(1, cantidad);
                stmt.setDouble(2, precio);
                stmt.setInt(3, user.getId());
                stmt.setString(4, producto);
                stmt.executeUpdate();
                
                // Registrar en auditoría
                registrarAuditoria(user.getId(), "AGREGAR_AL_CARRITO", 
                    String.format("Producto: %s, Cantidad: %d", producto, cantidad));
                
                System.out.println("✅ Producto agregado al carrito: " + producto);
                enviarRespuestaJSON(response, true, "Producto agregado al carrito");
                
            } catch (SQLException e) {
                System.err.println("❌ Error agregando al carrito: " + e.getMessage());
                e.printStackTrace();
                enviarRespuestaJSON(response, false, "Error en la base de datos");
            }
            
        } catch (NumberFormatException e) {
            enviarRespuestaJSON(response, false, "Formato de número inválido");
        }
    }
    
    /**
     * Actualiza la cantidad de un producto en el carrito
     */
    private void actualizarCantidad(HttpServletRequest request, HttpServletResponse response, Usuario user)
            throws IOException {
        
        String producto = request.getParameter("producto");
        String cantidadStr = request.getParameter("cantidad");
        
        if (producto == null || cantidadStr == null) {
            enviarRespuestaJSON(response, false, "Parámetros incompletos");
            return;
        }
        
        try {
            int cantidad = Integer.parseInt(cantidadStr);
            
            if (cantidad <= 0) {
                eliminarDelCarrito(request, response, user);
                return;
            }
            
            try (Connection conn = ConexionMySQL.conectar()) {
                // Verificar stock
                String sqlStock = "SELECT cantidad FROM productos WHERE nombre = ?";
                PreparedStatement stmtStock = conn.prepareStatement(sqlStock);
                stmtStock.setString(1, producto);
                ResultSet rsStock = stmtStock.executeQuery();
                
                if (!rsStock.next()) {
                    enviarRespuestaJSON(response, false, "Producto no encontrado");
                    return;
                }
                
                int stockDisponible = rsStock.getInt("cantidad");
                
                if (cantidad > stockDisponible) {
                    enviarRespuestaJSON(response, false, 
                        "Stock insuficiente. Disponible: " + stockDisponible);
                    return;
                }
                
                // Actualizar
                String sql = "UPDATE carritos SET cantidad = ? WHERE usuario_id = ? AND producto_nombre = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setInt(1, cantidad);
                stmt.setInt(2, user.getId());
                stmt.setString(3, producto);
                stmt.executeUpdate();
                
                registrarAuditoria(user.getId(), "ACTUALIZAR_CARRITO", 
                    String.format("Producto: %s, Nueva cantidad: %d", producto, cantidad));
                
                enviarRespuestaJSON(response, true, "Cantidad actualizada");
                
            } catch (SQLException e) {
                System.err.println("❌ Error actualizando carrito: " + e.getMessage());
                enviarRespuestaJSON(response, false, "Error en la base de datos");
            }
            
        } catch (NumberFormatException e) {
            enviarRespuestaJSON(response, false, "Formato de número inválido");
        }
    }
    
    /**
     * Elimina un producto del carrito
     */
    private void eliminarDelCarrito(HttpServletRequest request, HttpServletResponse response, Usuario user)
            throws IOException {
        
        String producto = request.getParameter("producto");
        
        if (producto == null) {
            enviarRespuestaJSON(response, false, "Producto no especificado");
            return;
        }
        
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "DELETE FROM carritos WHERE usuario_id = ? AND producto_nombre = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, user.getId());
            stmt.setString(2, producto);
            int filas = stmt.executeUpdate();
            
            if (filas > 0) {
                registrarAuditoria(user.getId(), "ELIMINAR_DEL_CARRITO", 
                    "Producto: " + producto);
                
                System.out.println("✅ Producto eliminado del carrito: " + producto);
                enviarRespuestaJSON(response, true, "Producto eliminado");
            } else {
                enviarRespuestaJSON(response, false, "Producto no encontrado en el carrito");
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error eliminando del carrito: " + e.getMessage());
            enviarRespuestaJSON(response, false, "Error en la base de datos");
        }
    }
    
    /**
     * Vacía completamente el carrito
     */
    private void vaciarCarrito(HttpServletRequest request, HttpServletResponse response, Usuario user)
            throws IOException {
        
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "DELETE FROM carritos WHERE usuario_id = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, user.getId());
            int filas = stmt.executeUpdate();
            
            registrarAuditoria(user.getId(), "VACIAR_CARRITO", 
                "Eliminados " + filas + " productos");
            
            System.out.println("✅ Carrito vaciado: " + filas + " items");
            enviarRespuestaJSON(response, true, "Carrito vaciado");
            
        } catch (SQLException e) {
            System.err.println("❌ Error vaciando carrito: " + e.getMessage());
            enviarRespuestaJSON(response, false, "Error en la base de datos");
        }
    }
    
    /**
     * Cuenta los items en el carrito
     */
    private void contarItems(HttpServletResponse response, Usuario user) throws IOException {
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "SELECT SUM(cantidad) FROM carritos WHERE usuario_id = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, user.getId());
            ResultSet rs = stmt.executeQuery();
            
            int count = 0;
            if (rs.next()) {
                count = rs.getInt(1);
            }
            
            JsonObject respuesta = new JsonObject();
            respuesta.addProperty("count", count);
            
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().print(gson.toJson(respuesta));
            
        } catch (SQLException e) {
            System.err.println("❌ Error contando items: " + e.getMessage());
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