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

@WebServlet("/PedidoServlet")
public class PedidoServlet extends HttpServlet {
    
    private final Gson gson = new Gson();
    
    /**
     * Registra en auditoría
     */
    private void registrarAuditoria(Connection conn, int usuarioId, String accion, String detalles) {
        try {
            String sql = "INSERT INTO auditoria (usuario_id, accion, tabla, registro_id, detalles) " +
                         "VALUES (?, ?, ?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, usuarioId);
            stmt.setString(2, accion);
            stmt.setString(3, "pedidos");
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
        
        procesarPedido(request, response, user);
    }
    
    /**
     * Procesa un pedido completo usando TRANSACCIONES
     */
    private void procesarPedido(HttpServletRequest request, HttpServletResponse response, Usuario user)
            throws IOException {
        
        String tarjetaIdStr = request.getParameter("tarjeta_id");
        String direccion = request.getParameter("direccion");
        String telefono = request.getParameter("telefono");
        
        if (tarjetaIdStr == null || direccion == null) {
            enviarRespuestaJSON(response, false, "Datos incompletos");
            return;
        }
        
        Connection conn = null;
        
        try {
            int tarjetaId = Integer.parseInt(tarjetaIdStr);
            conn = ConexionMySQL.conectar();
            
            // ========================================
            // INICIAR TRANSACCIÓN
            // ========================================
            conn.setAutoCommit(false);
            
            System.out.println("\n🛒 ========== PROCESANDO PEDIDO ==========");
            System.out.println("   Usuario: " + user.getUsuario());
            System.out.println("   Tarjeta ID: " + tarjetaId);
            
            // 1. Obtener items del carrito
            String sqlCarrito = "SELECT producto_nombre, cantidad, precio_unitario FROM carritos WHERE usuario_id = ?";
            PreparedStatement stmtCarrito = conn.prepareStatement(sqlCarrito);
            stmtCarrito.setInt(1, user.getId());
            ResultSet rsCarrito = stmtCarrito.executeQuery();
            
            // Clase auxiliar para items
            class ItemCarrito {
                String producto;
                int cantidad;
                double precio;
            }
            
            java.util.List<ItemCarrito> items = new java.util.ArrayList<>();
            double total = 0;
            
            while (rsCarrito.next()) {
                ItemCarrito item = new ItemCarrito();
                item.producto = rsCarrito.getString("producto_nombre");
                item.cantidad = rsCarrito.getInt("cantidad");
                item.precio = rsCarrito.getDouble("precio_unitario");
                items.add(item);
                total += item.cantidad * item.precio;
            }
            
            if (items.isEmpty()) {
                conn.rollback();
                enviarRespuestaJSON(response, false, "El carrito está vacío");
                return;
            }
            
            System.out.println("   Items en carrito: " + items.size());
            System.out.println("   Total: $" + String.format("%.2f", total));
            
            // 2. Verificar stock y actualizar
            for (ItemCarrito item : items) {
                System.out.println("   Verificando stock: " + item.producto);
                
                // Verificar stock disponible CON LOCK
                String sqlStock = "SELECT cantidad FROM productos WHERE nombre = ? FOR UPDATE";
                PreparedStatement stmtStock = conn.prepareStatement(sqlStock);
                stmtStock.setString(1, item.producto);
                ResultSet rsStock = stmtStock.executeQuery();
                
                if (!rsStock.next()) {
                    conn.rollback();
                    enviarRespuestaJSON(response, false, "Producto no encontrado: " + item.producto);
                    return;
                }
                
                int stockDisponible = rsStock.getInt("cantidad");
                
                if (stockDisponible < item.cantidad) {
                    conn.rollback();
                    enviarRespuestaJSON(response, false, 
                        String.format("Stock insuficiente para %s. Disponible: %d, Solicitado: %d",
                        item.producto, stockDisponible, item.cantidad));
                    return;
                }
                
                // ✅ USAR CONTROL DE CONCURRENCIA
                boolean stockActualizado = ProductoConcurrenteManager.actualizarStockSeguro(
                    item.producto, -item.cantidad, user.getId()
                );
                
                if (!stockActualizado) {
                    conn.rollback();
                    enviarRespuestaJSON(response, false, "Error al actualizar stock de: " + item.producto);
                    return;
                }
                
                System.out.println("   ✅ Stock actualizado: " + item.producto + " (-" + item.cantidad + ")");
                
                // 🗑️ INVALIDAR CACHÉ
                CacheManager.invalidarProducto(item.producto);
            }
            
            // 3. Crear el pedido
            double totalConImpuestos = total * 1.18; // 18% impuestos
            String direccionCompleta = direccion + " | Tel: " + telefono;
            
            String sqlPedido = "INSERT INTO pedidos (usuario_id, total, tarjeta_id, estado, direccion_envio) " +
                               "VALUES (?, ?, ?, 'PENDIENTE', ?)";
            PreparedStatement stmtPedido = conn.prepareStatement(sqlPedido, Statement.RETURN_GENERATED_KEYS);
            stmtPedido.setInt(1, user.getId());
            stmtPedido.setDouble(2, totalConImpuestos);
            stmtPedido.setInt(3, tarjetaId);
            stmtPedido.setString(4, direccionCompleta);
            stmtPedido.executeUpdate();
            
            // Obtener ID del pedido
            ResultSet rsPedido = stmtPedido.getGeneratedKeys();
            int pedidoId = 0;
            if (rsPedido.next()) {
                pedidoId = rsPedido.getInt(1);
            }
            
            System.out.println("   Pedido creado: ID " + pedidoId);
            
            // 4. Crear detalles del pedido
            String sqlDetalle = "INSERT INTO pedido_detalles (pedido_id, producto_nombre, cantidad, precio_unitario, subtotal) " +
                                "VALUES (?, ?, ?, ?, ?)";
            PreparedStatement stmtDetalle = conn.prepareStatement(sqlDetalle);
            
            for (ItemCarrito item : items) {
                stmtDetalle.setInt(1, pedidoId);
                stmtDetalle.setString(2, item.producto);
                stmtDetalle.setInt(3, item.cantidad);
                stmtDetalle.setDouble(4, item.precio);
                stmtDetalle.setDouble(5, item.cantidad * item.precio);
                stmtDetalle.addBatch();
            }
            stmtDetalle.executeBatch();
            
            System.out.println("   Detalles agregados: " + items.size() + " items");
            
            // 5. Vaciar el carrito
            String sqlVaciar = "DELETE FROM carritos WHERE usuario_id = ?";
            PreparedStatement stmtVaciar = conn.prepareStatement(sqlVaciar);
            stmtVaciar.setInt(1, user.getId());
            stmtVaciar.executeUpdate();
            
            System.out.println("   Carrito vaciado");
            
            // 6. Registrar en auditoría
            registrarAuditoria(conn, user.getId(), "CREAR_PEDIDO", 
                String.format("Pedido #%d - Total: $%.2f - Items: %d", 
                pedidoId, totalConImpuestos, items.size()));
            
            // ========================================
            // COMMIT DE LA TRANSACCIÓN
            // ========================================
            conn.commit();
            System.out.println("✅ TRANSACCIÓN COMPLETADA");
            System.out.println("==========================================\n");
            
            // 🌐 NOTIFICAR VÍA WEBSOCKET
            for (ItemCarrito item : items) {
                InventarioWebSocket.notificarCambioProducto(
                    item.producto, "VENDIDO", user.getUsuario()
                );
            }
            
            // Respuesta exitosa
            JsonObject respuesta = new JsonObject();
            respuesta.addProperty("success", true);
            respuesta.addProperty("message", "Pedido realizado exitosamente");
            respuesta.addProperty("pedidoId", pedidoId);
            respuesta.addProperty("total", totalConImpuestos);
            
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().print(gson.toJson(respuesta));
            
        } catch (NumberFormatException e) {
            System.err.println("❌ Error de formato: " + e.getMessage());
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) {}
            }
            enviarRespuestaJSON(response, false, "Datos inválidos");
            
        } catch (SQLException e) {
            System.err.println("❌ Error SQL: " + e.getMessage());
            e.printStackTrace();
            if (conn != null) {
                try { 
                    conn.rollback();
                    System.out.println("🔙 ROLLBACK ejecutado");
                } catch (SQLException ex) {
                    System.err.println("❌ Error en rollback: " + ex.getMessage());
                }
            }
            enviarRespuestaJSON(response, false, "Error al procesar el pedido");
            
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    System.err.println("❌ Error cerrando conexión: " + e.getMessage());
                }
            }
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