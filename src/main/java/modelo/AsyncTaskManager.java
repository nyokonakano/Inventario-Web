package modelo;

import java.sql.*;
import java.util.concurrent.*;
import java.util.List;
import java.util.ArrayList;

/**
 * Gestor de tareas asíncronas usando Thread Pools
 * Permite ejecutar operaciones pesadas sin bloquear la aplicación
 */
public class AsyncTaskManager {
    
    // Thread Pool para tareas generales (ajustar según CPU)
    private static final ExecutorService executorService = 
        Executors.newFixedThreadPool(5);
    
    // Thread Pool para tareas programadas
    private static final ScheduledExecutorService scheduledExecutor = 
        Executors.newScheduledThreadPool(2);
    
    /**
     * Genera un reporte de inventario de forma asíncrona
     * El usuario recibe respuesta inmediata y el reporte se procesa en background
     */
    public static Future<String> generarReporteInventarioAsync(int usuarioId) {
        System.out.println("📊 [ASYNC] Iniciando generación de reporte en background...");
        
        return executorService.submit(() -> {
            Thread.currentThread().setName("ReporteInventario-" + usuarioId);
            System.out.println("⚙️ Thread " + Thread.currentThread().getName() + " procesando...");
            
            long startTime = System.currentTimeMillis();
            StringBuilder reporte = new StringBuilder();
            
            try (Connection conn = ConexionMySQL.conectar()) {
                // Simular procesamiento pesado
                reporte.append("=== REPORTE DE INVENTARIO ===\n\n");
                
                // Total de productos
                String sql1 = "SELECT COUNT(*) as total FROM productos";
                PreparedStatement stmt1 = conn.prepareStatement(sql1);
                ResultSet rs1 = stmt1.executeQuery();
                if (rs1.next()) {
                    reporte.append("Total de productos: ").append(rs1.getInt("total")).append("\n");
                }
                
                Thread.sleep(1000); // Simular cálculos complejos
                
                // Valor total del inventario
                String sql2 = "SELECT SUM(cantidad * precio) as valor_total FROM productos";
                PreparedStatement stmt2 = conn.prepareStatement(sql2);
                ResultSet rs2 = stmt2.executeQuery();
                if (rs2.next()) {
                    reporte.append("Valor total: $").append(String.format("%.2f", rs2.getDouble("valor_total"))).append("\n");
                }
                
                Thread.sleep(1000);
                
                // Productos por categoría
                String sql3 = "SELECT categoria, COUNT(*) as cant, SUM(cantidad) as stock " +
                              "FROM productos GROUP BY categoria ORDER BY cant DESC";
                PreparedStatement stmt3 = conn.prepareStatement(sql3);
                ResultSet rs3 = stmt3.executeQuery();
                
                reporte.append("\n--- Productos por Categoría ---\n");
                while (rs3.next()) {
                    reporte.append(String.format("  %s: %d productos (%d unidades)\n",
                        rs3.getString("categoria"),
                        rs3.getInt("cant"),
                        rs3.getInt("stock")));
                }
                
                Thread.sleep(1000);
                
                // Productos con stock bajo
                String sql4 = "SELECT nombre, cantidad FROM productos WHERE cantidad < 10 ORDER BY cantidad";
                PreparedStatement stmt4 = conn.prepareStatement(sql4);
                ResultSet rs4 = stmt4.executeQuery();
                
                reporte.append("\n--- Stock Bajo (< 10 unidades) ---\n");
                while (rs4.next()) {
                    reporte.append(String.format("  ⚠️ %s: %d unidades\n",
                        rs4.getString("nombre"),
                        rs4.getInt("cantidad")));
                }
                
                // Registrar en auditoría
                String sqlAudit = "INSERT INTO auditoria (usuario_id, accion, tabla, registro_id, detalles) " +
                                  "VALUES (?, ?, ?, ?, ?)";
                PreparedStatement stmtAudit = conn.prepareStatement(sqlAudit);
                stmtAudit.setInt(1, usuarioId);
                stmtAudit.setString(2, "GENERAR_REPORTE_ASYNC");
                stmtAudit.setString(3, "productos");
                stmtAudit.setString(4, null);
                stmtAudit.setString(5, "Reporte generado en " + (System.currentTimeMillis() - startTime) + "ms");
                stmtAudit.executeUpdate();
                
                long duration = System.currentTimeMillis() - startTime;
                reporte.append("\n✅ Reporte generado en ").append(duration).append("ms");
                
                System.out.println("✅ [ASYNC] Reporte completado en " + duration + "ms");
                return reporte.toString();
                
            } catch (Exception e) {
                System.err.println("❌ Error generando reporte: " + e.getMessage());
                return "Error al generar reporte: " + e.getMessage();
            }
        });
    }
    
    /**
     * Exporta la base de datos de forma asíncrona
     */
    public static Future<Boolean> exportarBaseDatosAsync(int usuarioId) {
        System.out.println("💾 [ASYNC] Iniciando exportación de BD...");
        
        return executorService.submit(() -> {
            Thread.currentThread().setName("ExportBD-" + usuarioId);
            System.out.println("⚙️ Exportando base de datos...");
            
            try {
                Thread.sleep(3000); // Simular exportación pesada
                
                // Aquí iría la lógica real de exportación
                System.out.println("✅ Exportación completada");
                return true;
                
            } catch (Exception e) {
                System.err.println("❌ Error en exportación: " + e.getMessage());
                return false;
            }
        });
    }
    
    /**
     * Procesa múltiples actualizaciones de stock en paralelo
     */
    public static List<Future<Boolean>> actualizarStockMasivoAsync(
            List<String> productos, List<Integer> cantidades, int usuarioId) {
        
        System.out.println("🔄 [ASYNC] Actualizando " + productos.size() + " productos en paralelo...");
        List<Future<Boolean>> resultados = new ArrayList<>();
        
        for (int i = 0; i < productos.size(); i++) {
            final String producto = productos.get(i);
            final int cantidad = cantidades.get(i);
            
            Future<Boolean> futuro = executorService.submit(() -> {
                return ProductoConcurrenteManager.actualizarStockSeguro(producto, cantidad, usuarioId);
            });
            
            resultados.add(futuro);
        }
        
        return resultados;
    }
    
    /**
     * Programa una tarea para ejecutarse periódicamente
     * Ejemplo: verificar stock bajo cada hora
     */
    public static void programarVerificacionStockBajo(int intervaloMinutos) {
        System.out.println("⏰ Programando verificación de stock cada " + intervaloMinutos + " minutos");
        
        Runnable tarea = () -> {
            System.out.println("\n🔍 [SCHEDULED] Verificando stock bajo...");
            
            try (Connection conn = ConexionMySQL.conectar()) {
                String sql = "SELECT nombre, cantidad FROM productos WHERE cantidad < 10";
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery();
                
                List<String> productosConStockBajo = new ArrayList<>();
                while (rs.next()) {
                    productosConStockBajo.add(rs.getString("nombre") + " (" + rs.getInt("cantidad") + ")");
                }
                
                if (!productosConStockBajo.isEmpty()) {
                    System.out.println("⚠️ [ALERTA] " + productosConStockBajo.size() + " productos con stock bajo:");
                    productosConStockBajo.forEach(p -> System.out.println("   - " + p));
                    
                    // Aquí podrías enviar un email o notificación
                } else {
                    System.out.println("✅ Todos los productos tienen stock suficiente");
                }
                
            } catch (SQLException e) {
                System.err.println("❌ Error verificando stock: " + e.getMessage());
            }
        };
        
        // Ejecutar inmediatamente y luego cada X minutos
        scheduledExecutor.scheduleAtFixedRate(tarea, 0, intervaloMinutos, TimeUnit.MINUTES);
    }
    
    /**
     * Limpia registros de auditoría antiguos de forma asíncrona
     */
    public static Future<Integer> limpiarAuditoriaAntiguaAsync(int diasAntiguedad) {
        System.out.println("🧹 [ASYNC] Limpiando auditoría mayor a " + diasAntiguedad + " días...");
        
        return executorService.submit(() -> {
            Thread.currentThread().setName("LimpiarAuditoria");
            
            try (Connection conn = ConexionMySQL.conectar()) {
                String sql = "DELETE FROM auditoria WHERE fecha < DATE_SUB(NOW(), INTERVAL ? DAY)";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setInt(1, diasAntiguedad);
                
                int eliminados = stmt.executeUpdate();
                System.out.println("✅ Se eliminaron " + eliminados + " registros antiguos");
                
                return eliminados;
                
            } catch (SQLException e) {
                System.err.println("❌ Error limpiando auditoría: " + e.getMessage());
                return 0;
            }
        });
    }
    
    /**
     * Obtiene estadísticas del thread pool
     */
    public static String getEstadisticas() {
        if (executorService instanceof ThreadPoolExecutor) {
            ThreadPoolExecutor tpe = (ThreadPoolExecutor) executorService;
            return String.format(
                "📊 Estadísticas Thread Pool:\n" +
                "   - Tareas activas: %d\n" +
                "   - Tareas completadas: %d\n" +
                "   - Tareas en cola: %d\n" +
                "   - Pool size: %d/%d",
                tpe.getActiveCount(),
                tpe.getCompletedTaskCount(),
                tpe.getQueue().size(),
                tpe.getPoolSize(),
                tpe.getMaximumPoolSize()
            );
        }
        return "Estadísticas no disponibles";
    }
    
    /**
     * Cierra el executor service (llamar al detener la aplicación)
     */
    public static void shutdown() {
        System.out.println("⏹️ Deteniendo AsyncTaskManager...");
        executorService.shutdown();
        scheduledExecutor.shutdown();
        
        try {
            if (!executorService.awaitTermination(10, TimeUnit.SECONDS)) {
                executorService.shutdownNow();
            }
            if (!scheduledExecutor.awaitTermination(10, TimeUnit.SECONDS)) {
                scheduledExecutor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executorService.shutdownNow();
            scheduledExecutor.shutdownNow();
        }
        
        System.out.println("✅ AsyncTaskManager detenido");
    }
}