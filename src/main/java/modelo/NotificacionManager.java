package modelo;

import java.sql.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * Sistema de notificaciones automáticas
 * Monitorea el inventario y genera alertas en tiempo real
 */
public class NotificacionManager {
    
    // Executor para monitoreo continuo
    private static final ScheduledExecutorService monitorExecutor = 
        Executors.newScheduledThreadPool(3);
    
    // Cola de notificaciones pendientes (thread-safe)
    private static final BlockingQueue<Notificacion> colaNotificaciones = 
        new LinkedBlockingQueue<>();
    
    // Suscriptores a notificaciones
    private static final ConcurrentHashMap<Integer, List<TipoNotificacion>> suscriptores = 
        new ConcurrentHashMap<>();
    
    // Thread para procesar notificaciones
    private static Thread procesadorNotificaciones;
    private static volatile boolean ejecutando = false;
    
    /**
     * Tipos de notificaciones
     */
    public enum TipoNotificacion {
        STOCK_BAJO,
        STOCK_CRITICO,
        PRODUCTO_AGOTADO,
        PRECIO_ALTO,
        ACTIVIDAD_SOSPECHOSA,
        SISTEMA
    }
    
    /**
     * Clase para representar una notificación
     */
    public static class Notificacion {
        int id;
        String mensaje;
        TipoNotificacion tipo;
        String detalles;
        Timestamp fecha;
        int prioridad; // 1=Alta, 2=Media, 3=Baja
        
        public Notificacion(String mensaje, TipoNotificacion tipo, String detalles, int prioridad) {
            this.mensaje = mensaje;
            this.tipo = tipo;
            this.detalles = detalles;
            this.prioridad = prioridad;
            this.fecha = new Timestamp(System.currentTimeMillis());
        }
        
        @Override
        public String toString() {
            String icono = prioridad == 1 ? "🔴" : prioridad == 2 ? "🟡" : "🟢";
            return String.format("[%s %s] %s - %s", icono, tipo, mensaje, detalles);
        }
    }
    
    /**
     * Inicializa el sistema de notificaciones
     */
    public static void iniciar() {
        System.out.println("🔔 Iniciando NotificacionManager...");
        
        // Iniciar procesador de notificaciones
        ejecutando = true;
        procesadorNotificaciones = new Thread(() -> {
            Thread.currentThread().setName("ProcesadorNotificaciones");
            procesarNotificaciones();
        });
        procesadorNotificaciones.start();
        
        // Programar monitoreo de stock bajo cada 10 minutos
        monitorExecutor.scheduleAtFixedRate(() -> {
            monitorearStockBajo();
        }, 0, 10, TimeUnit.MINUTES);
        
        // Programar monitoreo de productos agotados cada 5 minutos
        monitorExecutor.scheduleAtFixedRate(() -> {
            monitorearProductosAgotados();
        }, 1, 5, TimeUnit.MINUTES);
        
        // Programar análisis de actividad sospechosa cada hora
        monitorExecutor.scheduleAtFixedRate(() -> {
            analizarActividadSospechosa();
        }, 5, 60, TimeUnit.MINUTES);
        
        System.out.println("✅ Sistema de notificaciones activo");
    }
    
    /**
     * Procesa notificaciones de la cola
     */
    private static void procesarNotificaciones() {
        while (ejecutando) {
            try {
                // Esperar por notificaciones (bloquea hasta que haya una)
                Notificacion notif = colaNotificaciones.poll(5, TimeUnit.SECONDS);
                
                if (notif != null) {
                    System.out.println("\n" + notif);
                    
                    // Guardar en base de datos
                    guardarNotificacion(notif);
                    
                    // Enviar a suscriptores
                    notificarSuscriptores(notif);
                    
                    // Aquí podrías enviar emails, SMS, etc.
                    if (notif.prioridad == 1) {
                        enviarAlertaCritica(notif);
                    }
                }
                
            } catch (InterruptedException e) {
                System.out.println("⚠️ Procesador de notificaciones interrumpido");
                Thread.currentThread().interrupt();
                break;
            }
        }
        
        System.out.println("⏹️ Procesador de notificaciones detenido");
    }
    
    /**
     * Monitorea productos con stock bajo
     */
    private static void monitorearStockBajo() {
        System.out.println("\n🔍 [MONITOR] Verificando stock bajo...");
        
        try (Connection conn = ConexionMySQL.conectar()) {
            // Stock bajo (< 10)
            String sql = "SELECT nombre, cantidad, precio FROM productos WHERE cantidad < 10 AND cantidad > 0";
            PreparedStatement stmt = conn.prepareStatement(sql);
            ResultSet rs = stmt.executeQuery();
            
            int contador = 0;
            while (rs.next()) {
                String nombre = rs.getString("nombre");
                int cantidad = rs.getInt("cantidad");
                double precio = rs.getDouble("precio");
                
                Notificacion notif = new Notificacion(
                    "Stock bajo: " + nombre,
                    TipoNotificacion.STOCK_BAJO,
                    String.format("Solo quedan %d unidades (Precio: $%.2f)", cantidad, precio),
                    cantidad < 5 ? 1 : 2 // Crítico si < 5
                );
                
                colaNotificaciones.offer(notif);
                contador++;
            }
            
            if (contador > 0) {
                System.out.println("⚠️ Se detectaron " + contador + " productos con stock bajo");
            } else {
                System.out.println("✅ Todos los productos tienen stock suficiente");
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error monitoreando stock: " + e.getMessage());
        }
    }
    
    /**
     * Monitorea productos agotados
     */
    private static void monitorearProductosAgotados() {
        System.out.println("\n🔍 [MONITOR] Verificando productos agotados...");
        
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "SELECT nombre, precio FROM productos WHERE cantidad = 0";
            PreparedStatement stmt = conn.prepareStatement(sql);
            ResultSet rs = stmt.executeQuery();
            
            int contador = 0;
            while (rs.next()) {
                String nombre = rs.getString("nombre");
                double precio = rs.getDouble("precio");
                
                Notificacion notif = new Notificacion(
                    "Producto AGOTADO: " + nombre,
                    TipoNotificacion.PRODUCTO_AGOTADO,
                    String.format("Sin stock disponible (Precio: $%.2f) - Reabastecer urgentemente", precio),
                    1 // Prioridad alta
                );
                
                colaNotificaciones.offer(notif);
                contador++;
            }
            
            if (contador > 0) {
                System.out.println("🔴 " + contador + " productos AGOTADOS");
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error monitoreando agotados: " + e.getMessage());
        }
    }
    
    /**
     * Analiza actividad sospechosa en la auditoría
     */
    private static void analizarActividadSospechosa() {
        System.out.println("\n🔍 [MONITOR] Analizando actividad sospechosa...");
        
        try (Connection conn = ConexionMySQL.conectar()) {
            // Detectar múltiples intentos de login fallidos
            String sql = "SELECT u.usuario, COUNT(*) as intentos " +
                         "FROM auditoria a " +
                         "INNER JOIN usuarios u ON a.usuario_id = u.id " +
                         "WHERE a.accion = 'LOGIN_FALLIDO' " +
                         "AND a.fecha > DATE_SUB(NOW(), INTERVAL 1 HOUR) " +
                         "GROUP BY u.usuario " +
                         "HAVING intentos >= 5";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                String usuario = rs.getString("usuario");
                int intentos = rs.getInt("intentos");
                
                Notificacion notif = new Notificacion(
                    "Actividad sospechosa detectada",
                    TipoNotificacion.ACTIVIDAD_SOSPECHOSA,
                    String.format("Usuario '%s' tiene %d intentos fallidos en la última hora", usuario, intentos),
                    1
                );
                
                colaNotificaciones.offer(notif);
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error analizando actividad: " + e.getMessage());
        }
    }
    
    /**
     * Guarda una notificación en la base de datos
     */
    private static void guardarNotificacion(Notificacion notif) {
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "INSERT INTO auditoria (usuario_id, accion, tabla, detalles) " +
                         "VALUES (1, ?, 'sistema', ?)";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, "NOTIFICACION_" + notif.tipo);
            stmt.setString(2, notif.mensaje + " - " + notif.detalles);
            stmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("⚠️ Error guardando notificación: " + e.getMessage());
        }
    }
    
    /**
     * Notifica a los usuarios suscritos
     */
    private static void notificarSuscriptores(Notificacion notif) {
        suscriptores.forEach((usuarioId, tiposInteres) -> {
            if (tiposInteres.contains(notif.tipo)) {
                System.out.println("📧 Notificando a usuario ID: " + usuarioId + " sobre " + notif.tipo);
                // Aquí podrías enviar email, push notification, etc.
            }
        });
    }
    
    /**
     * Envía una alerta crítica (simulado)
     */
    private static void enviarAlertaCritica(Notificacion notif) {
        System.out.println("\n🚨 ===== ALERTA CRÍTICA =====");
        System.out.println("   " + notif.mensaje);
        System.out.println("   " + notif.detalles);
        System.out.println("   Hora: " + notif.fecha);
        System.out.println("=============================\n");
        
        // Aquí podrías enviar email real, SMS, webhook, etc.
    }
    
    /**
     * Suscribe un usuario a ciertos tipos de notificaciones
     */
    public static void suscribir(int usuarioId, TipoNotificacion... tipos) {
        List<TipoNotificacion> listaTipos = new ArrayList<>(Arrays.asList(tipos));
        suscriptores.put(usuarioId, listaTipos);
        System.out.println("✅ Usuario " + usuarioId + " suscrito a: " + Arrays.toString(tipos));
    }
    
    /**
     * Desuscribe un usuario
     */
    public static void desuscribir(int usuarioId) {
        suscriptores.remove(usuarioId);
        System.out.println("🔕 Usuario " + usuarioId + " desuscrito");
    }
    
    /**
     * Envía una notificación manual
     */
    public static void enviarNotificacion(String mensaje, TipoNotificacion tipo, String detalles, int prioridad) {
        Notificacion notif = new Notificacion(mensaje, tipo, detalles, prioridad);
        colaNotificaciones.offer(notif);
    }
    
    /**
     * Obtiene estadísticas del sistema de notificaciones
     */
    public static String getEstadisticas() {
        return String.format(
            "📊 Estadísticas de Notificaciones:\n" +
            "   - Notificaciones pendientes: %d\n" +
            "   - Suscriptores activos: %d\n" +
            "   - Procesador activo: %s",
            colaNotificaciones.size(),
            suscriptores.size(),
            ejecutando ? "Sí" : "No"
        );
    }
    
    /**
     * Detiene el sistema de notificaciones
     */
    public static void shutdown() {
        System.out.println("⏹️ Deteniendo NotificacionManager...");
        
        ejecutando = false;
        monitorExecutor.shutdown();
        
        try {
            if (!monitorExecutor.awaitTermination(10, TimeUnit.SECONDS)) {
                monitorExecutor.shutdownNow();
            }
            
            if (procesadorNotificaciones != null) {
                procesadorNotificaciones.interrupt();
                procesadorNotificaciones.join(5000);
            }
            
        } catch (InterruptedException e) {
            monitorExecutor.shutdownNow();
            Thread.currentThread().interrupt();
        }
        
        System.out.println("✅ NotificacionManager detenido");
    }
}