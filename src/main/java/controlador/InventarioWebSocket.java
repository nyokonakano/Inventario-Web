package controlador;

import jakarta.websocket.*;
import jakarta.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;
import com.google.gson.Gson;
import com.google.gson.JsonObject;

/**
 * WebSocket para actualizaciones en tiempo real del inventario
 * Permite sincronización entre múltiples usuarios conectados
 * 
 * CONCEPTO DISTRIBUIDO: Múltiples clientes reciben actualizaciones instantáneas
 * sin necesidad de refrescar la página
 */
@ServerEndpoint("/websocket/inventario")
public class InventarioWebSocket {
    
    // Todas las sesiones activas (thread-safe)
    private static final CopyOnWriteArraySet<Session> sesiones = new CopyOnWriteArraySet<>();
    
    // Mapeo de sesión a usuario (thread-safe)
    private static final ConcurrentHashMap<String, String> sesionUsuario = new ConcurrentHashMap<>();
    
    // Contador de conexiones
    private static int contadorConexiones = 0;
    
    private static final Gson gson = new Gson();
    
    /**
     * Se ejecuta cuando un cliente se conecta
     */
    @OnOpen
    public void onOpen(Session session) {
        sesiones.add(session);
        contadorConexiones++;
        
        String sessionId = session.getId();
        System.out.println("\n🔌 [WebSocket] Nueva conexión");
        System.out.println("   Session ID: " + sessionId);
        System.out.println("   Conexiones activas: " + sesiones.size());
        System.out.println("   Total histórico: " + contadorConexiones);
        
        // Enviar mensaje de bienvenida
        enviarMensaje(session, crearMensaje("conexion", "Conectado al servidor de inventario", null));
        
        // Notificar a todos sobre nueva conexión
        broadcast(crearMensaje("usuario_conectado", 
            "Nuevo usuario conectado", 
            "Total de usuarios online: " + sesiones.size()));
    }
    
    /**
     * Se ejecuta cuando se recibe un mensaje del cliente
     */
    @OnMessage
    public void onMessage(String mensaje, Session session) {
        System.out.println("📨 [WebSocket] Mensaje recibido: " + mensaje);
        
        try {
            JsonObject json = gson.fromJson(mensaje, JsonObject.class);
            String tipo = json.get("tipo").getAsString();
            
            switch (tipo) {
                case "registrar_usuario":
                    // Registrar qué usuario está en esta sesión
                    String usuario = json.get("usuario").getAsString();
                    sesionUsuario.put(session.getId(), usuario);
                    System.out.println("👤 Usuario registrado: " + usuario);
                    
                    enviarMensaje(session, crearMensaje("registro_exitoso", 
                        "Registrado como: " + usuario, null));
                    break;
                    
                case "producto_actualizado":
                    // Un usuario actualizó un producto, notificar a todos
                    String nombreProducto = json.get("producto").getAsString();
                    String accion = json.get("accion").getAsString();
                    String usuarioAccion = sesionUsuario.get(session.getId());
                    
                    System.out.println("🔄 Producto actualizado: " + nombreProducto + " por " + usuarioAccion);
                    
                    // Broadcast a todos excepto al que hizo el cambio
                    broadcastExcepto(session, crearMensaje("actualizar_inventario", 
                        "Producto modificado: " + nombreProducto, 
                        "Acción: " + accion + " por " + usuarioAccion));
                    break;
                    
                case "solicitar_estado":
                    // Cliente solicita estado actual del servidor
                    enviarMensaje(session, crearMensaje("estado_servidor", 
                        "Servidor operativo", 
                        "Usuarios conectados: " + sesiones.size()));
                    break;
                    
                case "ping":
                    // Keep-alive
                    enviarMensaje(session, crearMensaje("pong", "OK", null));
                    break;
                    
                default:
                    System.out.println("⚠️ Tipo de mensaje desconocido: " + tipo);
            }
            
        } catch (Exception e) {
            System.err.println("❌ Error procesando mensaje: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Se ejecuta cuando un cliente se desconecta
     */
    @OnClose
    public void onClose(Session session, CloseReason reason) {
        sesiones.remove(session);
        String usuario = sesionUsuario.remove(session.getId());
        
        System.out.println("\n🔌 [WebSocket] Conexión cerrada");
        System.out.println("   Session ID: " + session.getId());
        System.out.println("   Usuario: " + (usuario != null ? usuario : "Desconocido"));
        System.out.println("   Razón: " + reason.getReasonPhrase());
        System.out.println("   Conexiones restantes: " + sesiones.size());
        
        // Notificar a todos sobre desconexión
        if (usuario != null) {
            broadcast(crearMensaje("usuario_desconectado", 
                "Usuario desconectado: " + usuario, 
                "Usuarios online: " + sesiones.size()));
        }
    }
    
    /**
     * Se ejecuta cuando hay un error
     */
    @OnError
    public void onError(Session session, Throwable error) {
        System.err.println("❌ [WebSocket] Error en sesión: " + session.getId());
        System.err.println("   Error: " + error.getMessage());
        error.printStackTrace();
    }
    
    /**
     * Envía un mensaje a una sesión específica
     */
    private void enviarMensaje(Session session, String mensaje) {
        try {
            if (session.isOpen()) {
                session.getBasicRemote().sendText(mensaje);
            }
        } catch (IOException e) {
            System.err.println("❌ Error enviando mensaje: " + e.getMessage());
        }
    }
    
    /**
     * Envía un mensaje a todos los clientes conectados (BROADCAST)
     */
    public static void broadcast(String mensaje) {
        System.out.println("📢 [BROADCAST] Enviando a " + sesiones.size() + " clientes");
        
        for (Session session : sesiones) {
            try {
                if (session.isOpen()) {
                    session.getBasicRemote().sendText(mensaje);
                }
            } catch (IOException e) {
                System.err.println("❌ Error en broadcast: " + e.getMessage());
            }
        }
    }
    
    /**
     * Envía un mensaje a todos excepto a una sesión
     */
    private void broadcastExcepto(Session excluir, String mensaje) {
        System.out.println("📢 [BROADCAST] Enviando a " + (sesiones.size() - 1) + " clientes");
        
        for (Session session : sesiones) {
            if (!session.equals(excluir)) {
                try {
                    if (session.isOpen()) {
                        session.getBasicRemote().sendText(mensaje);
                    }
                } catch (IOException e) {
                    System.err.println("❌ Error en broadcast: " + e.getMessage());
                }
            }
        }
    }
    
    /**
     * Crea un mensaje JSON estructurado
     */
    private String crearMensaje(String tipo, String mensaje, String datos) {
        JsonObject json = new JsonObject();
        json.addProperty("tipo", tipo);
        json.addProperty("mensaje", mensaje);
        json.addProperty("timestamp", System.currentTimeMillis());
        
        if (datos != null) {
            json.addProperty("datos", datos);
        }
        
        return gson.toJson(json);
    }
    
    /**
     * Notifica a todos sobre un cambio en el inventario
     */
    public static void notificarCambioProducto(String nombreProducto, String accion, String usuario) {
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "producto_actualizado");
        json.addProperty("producto", nombreProducto);
        json.addProperty("accion", accion);
        json.addProperty("usuario", usuario);
        json.addProperty("timestamp", System.currentTimeMillis());
        
        broadcast(gson.toJson(json));
    }
    
    /**
     * Notifica sobre stock bajo
     */
    public static void notificarStockBajo(String nombreProducto, int cantidad) {
        JsonObject json = new JsonObject();
        json.addProperty("tipo", "alerta_stock_bajo");
        json.addProperty("producto", nombreProducto);
        json.addProperty("cantidad", cantidad);
        json.addProperty("mensaje", "⚠️ Stock bajo: " + nombreProducto + " (" + cantidad + " unidades)");
        json.addProperty("timestamp", System.currentTimeMillis());
        
        broadcast(gson.toJson(json));
    }
    
    /**
     * Obtiene estadísticas de WebSocket
     */
    public static String getEstadisticas() {
        return String.format(
            "📊 Estadísticas WebSocket:\n" +
            "   - Conexiones activas: %d\n" +
            "   - Total conexiones: %d\n" +
            "   - Usuarios registrados: %d",
            sesiones.size(),
            contadorConexiones,
            sesionUsuario.size()
        );
    }
    
    /**
     * Obtiene el número de conexiones activas
     */
    public static int getConexionesActivas() {
        return sesiones.size();
    }
}