package modelo;

import java.sql.*;
import java.util.concurrent.locks.ReentrantLock;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Gestor de operaciones concurrentes sobre productos
 * Previene RACE CONDITIONS cuando múltiples usuarios editan simultáneamente
 */
public class ProductoConcurrenteManager {
    
    // Locks por producto (evita bloquear todo el sistema)
    private static final ConcurrentHashMap<String, ReentrantLock> productoLocks = 
        new ConcurrentHashMap<>();
    
    // Lock global para operaciones críticas
    private static final ReentrantLock globalLock = new ReentrantLock(true); // fair lock
    
    /**
     * Obtiene o crea un lock para un producto específico
     */
    private static ReentrantLock getLockForProducto(String nombreProducto) {
        return productoLocks.computeIfAbsent(nombreProducto, k -> new ReentrantLock(true));
    }
    
    /**
     * Actualiza el stock de un producto de forma thread-safe
     * Previene que dos usuarios vendan el mismo producto y quede stock negativo
     * 
     * @param nombreProducto Nombre del producto
     * @param cantidadCambio Cantidad a sumar/restar (negativo para vender)
     * @param usuarioId ID del usuario que hace el cambio
     * @return true si la operación fue exitosa
     */
    public static boolean actualizarStockSeguro(String nombreProducto, int cantidadCambio, int usuarioId) {
        ReentrantLock lock = getLockForProducto(nombreProducto);
        lock.lock(); // BLOQUEAR acceso al producto
        
        long startTime = System.currentTimeMillis();
        System.out.println("🔒 [LOCK ADQUIRIDO] Producto: " + nombreProducto + 
                          " | Usuario: " + usuarioId + " | Thread: " + Thread.currentThread().getName());
        
        try (Connection conn = ConexionMySQL.conectar()) {
            // Iniciar transacción
            conn.setAutoCommit(false);
            
            try {
                // 1. LEER STOCK ACTUAL CON LOCK (FOR UPDATE previene lecturas sucias)
                String sqlSelect = "SELECT cantidad FROM productos WHERE nombre = ? FOR UPDATE";
                PreparedStatement stmtSelect = conn.prepareStatement(sqlSelect);
                stmtSelect.setString(1, nombreProducto);
                ResultSet rs = stmtSelect.executeQuery();
                
                if (!rs.next()) {
                    System.out.println("❌ Producto no existe: " + nombreProducto);
                    conn.rollback();
                    return false;
                }
                
                int stockActual = rs.getInt("cantidad");
                int nuevoStock = stockActual + cantidadCambio;
                
                // VALIDAR que no quede negativo
                if (nuevoStock < 0) {
                    System.out.println("⚠️ [STOCK INSUFICIENTE] Producto: " + nombreProducto + 
                                      " | Stock actual: " + stockActual + 
                                      " | Solicitado: " + Math.abs(cantidadCambio));
                    conn.rollback();
                    return false;
                }
                
                // 2. ACTUALIZAR STOCK
                String sqlUpdate = "UPDATE productos SET cantidad = ? WHERE nombre = ?";
                PreparedStatement stmtUpdate = conn.prepareStatement(sqlUpdate);
                stmtUpdate.setInt(1, nuevoStock);
                stmtUpdate.setString(2, nombreProducto);
                int filas = stmtUpdate.executeUpdate();
                
                if (filas == 0) {
                    conn.rollback();
                    return false;
                }
                
                // 3. REGISTRAR EN AUDITORÍA
                String sqlAudit = "INSERT INTO auditoria (usuario_id, accion, tabla, registro_id, detalles) " +
                                  "VALUES (?, ?, ?, ?, ?)";
                PreparedStatement stmtAudit = conn.prepareStatement(sqlAudit);
                stmtAudit.setInt(1, usuarioId);
                stmtAudit.setString(2, "ACTUALIZAR_STOCK_CONCURRENTE");
                stmtAudit.setString(3, "productos");
                stmtAudit.setString(4, nombreProducto);
                stmtAudit.setString(5, String.format("Stock anterior: %d | Cambio: %+d | Nuevo stock: %d", 
                                                     stockActual, cantidadCambio, nuevoStock));
                stmtAudit.executeUpdate();
                
                // COMMIT de la transacción
                conn.commit();
                
                long duration = System.currentTimeMillis() - startTime;
                System.out.println("✅ [STOCK ACTUALIZADO] Producto: " + nombreProducto + 
                                  " | " + stockActual + " → " + nuevoStock + 
                                  " | Tiempo: " + duration + "ms");
                
                return true;
                
            } catch (SQLException e) {
                conn.rollback();
                System.err.println("❌ Error en transacción: " + e.getMessage());
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error de conexión: " + e.getMessage());
            e.printStackTrace();
            return false;
        } finally {
            lock.unlock(); // LIBERAR el lock SIEMPRE
            long totalTime = System.currentTimeMillis() - startTime;
            System.out.println("🔓 [LOCK LIBERADO] Producto: " + nombreProducto + 
                              " | Tiempo total: " + totalTime + "ms\n");
        }
    }
    
    /**
     * Transfiere stock entre dos productos de forma atómica
     * Ejemplo: convertir materia prima en producto final
     */
    public static boolean transferirStock(String productoOrigen, String productoDestino, 
                                          int cantidad, int usuarioId) {
        globalLock.lock(); // Lock global para evitar deadlocks
        System.out.println("🔒 [TRANSFERENCIA INICIADA] " + productoOrigen + " → " + productoDestino);
        
        try {
            // Primero restar del origen
            boolean restaExitosa = actualizarStockSeguro(productoOrigen, -cantidad, usuarioId);
            if (!restaExitosa) {
                System.out.println("❌ No se pudo restar del origen");
                return false;
            }
            
            // Luego sumar al destino
            boolean sumaExitosa = actualizarStockSeguro(productoDestino, cantidad, usuarioId);
            if (!sumaExitosa) {
                // REVERTIR la resta anterior
                System.out.println("⚠️ Revirtiendo operación...");
                actualizarStockSeguro(productoOrigen, cantidad, usuarioId);
                return false;
            }
            
            System.out.println("✅ [TRANSFERENCIA EXITOSA] " + cantidad + " unidades");
            return true;
            
        } finally {
            globalLock.unlock();
        }
    }
    
    /**
     * Obtiene el stock actual de forma thread-safe (lectura)
     */
    public static int obtenerStockActual(String nombreProducto) {
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "SELECT cantidad FROM productos WHERE nombre = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, nombreProducto);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt("cantidad");
            }
            return -1;
            
        } catch (SQLException e) {
            System.err.println("❌ Error al obtener stock: " + e.getMessage());
            return -1;
        }
    }
    
    /**
     * Limpia locks no utilizados (mantenimiento)
     */
    public static void limpiarLocksInactivos() {
        System.out.println("🧹 Limpiando locks inactivos...");
        productoLocks.entrySet().removeIf(entry -> !entry.getValue().isLocked());
        System.out.println("   Locks activos: " + productoLocks.size());
    }
    
    /**
     * Obtiene estadísticas de concurrencia
     */
    public static String getEstadisticas() {
        return String.format(
            "📊 Estadísticas de Concurrencia:\n" +
            "   - Productos con lock: %d\n" +
            "   - Lock global ocupado: %s\n" +
            "   - Threads esperando: %d",
            productoLocks.size(),
            globalLock.isLocked() ? "Sí" : "No",
            globalLock.getQueueLength()
        );
    }
}