package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

/**
 * Servlet para generar reportes del inventario
 * Usa AsyncTaskManager para procesamiento en segundo plano
 */
@WebServlet("/ReportesServlet")
public class ReportesServlet extends HttpServlet {
    
    /**
     * Registra una acción en la tabla de auditoría
     */
    private void registrarAuditoria(int usuarioId, String accion, String detalles) {
        try (java.sql.Connection conn = ConexionMySQL.conectar()) {
            String sql = "INSERT INTO auditoria (usuario_id, accion, tabla, registro_id, detalles) " +
                         "VALUES (?, ?, ?, ?, ?)";
            java.sql.PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, usuarioId);
            stmt.setString(2, accion);
            stmt.setString(3, "reportes");
            stmt.setString(4, null);
            stmt.setString(5, detalles);
            stmt.executeUpdate();
        } catch (Exception e) {
            System.err.println("⚠️ Error al registrar auditoría: " + e.getMessage());
        }
    }
    
    // Verificar que el usuario sea administrador
    private boolean esAdministrador(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        Usuario user = (Usuario) request.getSession().getAttribute("usuario");
        if (user == null || !user.esAdministrador()) {
            response.sendRedirect("index.jsp?error=acceso_denegado");
            return false;
        }
        return true;
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        if (!esAdministrador(request, response)) return;
        
        Usuario user = (Usuario) request.getSession().getAttribute("usuario");
        String tipo = request.getParameter("tipo");
        String formato = request.getParameter("formato");
        String async = request.getParameter("async");
        
        System.out.println("📊 Generando reporte: " + tipo + " | Formato: " + formato + " | Async: " + async);
        
        // Si es asíncrono, usar AsyncTaskManager
        if ("true".equals(async)) {
            generarReporteAsincrono(request, response, user, tipo);
        } else if ("pdf".equals(formato)) {
            exportarPDF(response, tipo);
        } else if ("excel".equals(formato)) {
            exportarExcel(response, tipo);
        } else {
            // Generación síncrona (más rápida pero bloquea)
            generarReporteSincrono(response, user, tipo);
        }
    }
    
    /**
     * Genera un reporte de forma ASÍNCRONA (sin bloquear)
     * Usa AsyncTaskManager con Future
     */
    private void generarReporteAsincrono(HttpServletRequest request, HttpServletResponse response, 
                                         Usuario user, String tipo) throws IOException {
        
        System.out.println("⚡ Generando reporte ASÍNCRONO...");
        
        response.setContentType("text/plain;charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            // 🔄 USAR ASYNCTASKMANAGER para procesamiento en background
            Future<String> futuro = AsyncTaskManager.generarReporteInventarioAsync(user.getId());
            
            // Esperar el resultado (máximo 30 segundos)
            String reporte = futuro.get(30, TimeUnit.SECONDS);
            
            // Enviar el reporte al cliente
            out.println(reporte);
            
            // Registrar en auditoría
            registrarAuditoria(user.getId(), "GENERAR_REPORTE_ASYNC", 
                "Tipo: " + tipo + " | Método: Asíncrono");
            
            System.out.println("✅ Reporte asíncrono completado");
            
        } catch (java.util.concurrent.TimeoutException e) {
            System.err.println("⏱️ Timeout al generar reporte");
            out.println("ERROR: El reporte está tardando demasiado. Intente con menos datos.");
        } catch (Exception e) {
            System.err.println("❌ Error al generar reporte: " + e.getMessage());
            e.printStackTrace();
            out.println("ERROR: " + e.getMessage());
        }
    }
    
    /**
     * Genera un reporte de forma SÍNCRONA (más simple)
     */
    private void generarReporteSincrono(HttpServletResponse response, Usuario user, String tipo) 
            throws IOException {
        
        response.setContentType("text/plain;charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        try (java.sql.Connection conn = ConexionMySQL.conectar()) {
            
            switch (tipo) {
                case "stock-bajo":
                    generarReporteStockBajo(out, conn);
                    break;
                    
                case "categorias":
                    generarReporteCategorias(out, conn);
                    break;
                    
                case "valiosos":
                    generarReporteMasValiosos(out, conn);
                    break;
                    
                case "auditoria":
                    generarReporteAuditoria(out, conn);
                    break;
                    
                case "proyecciones":
                    generarReporteProyecciones(out, conn);
                    break;
                    
                default:
                    out.println("Tipo de reporte no reconocido: " + tipo);
            }
            
            registrarAuditoria(user.getId(), "GENERAR_REPORTE_SYNC", "Tipo: " + tipo);
            
        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            out.println("ERROR: " + e.getMessage());
        }
    }
    
    /**
     * Reporte de productos con stock bajo
     */
    private void generarReporteStockBajo(PrintWriter out, java.sql.Connection conn) 
            throws Exception {
        
        out.println("=== REPORTE DE STOCK BAJO ===\n");
        out.println("Productos con menos de 10 unidades\n");
        out.println("Generado: " + new java.util.Date() + "\n");
        out.println("=" .repeat(60) + "\n");
        
        String sql = "SELECT nombre, cantidad, precio, categoria FROM productos WHERE cantidad < 10 ORDER BY cantidad";
        java.sql.PreparedStatement stmt = conn.prepareStatement(sql);
        java.sql.ResultSet rs = stmt.executeQuery();
        
        int contador = 0;
        while (rs.next()) {
            contador++;
            String estado = rs.getInt("cantidad") == 0 ? "[AGOTADO]" : 
                           rs.getInt("cantidad") < 5 ? "[CRÍTICO]" : "[BAJO]";
            
            out.printf("%d. %s %s\n", contador, estado, rs.getString("nombre"));
            out.printf("   Cantidad: %d | Precio: $%.2f | Categoría: %s\n\n",
                rs.getInt("cantidad"),
                rs.getDouble("precio"),
                rs.getString("categoria")
            );
        }
        
        if (contador == 0) {
            out.println("✅ No hay productos con stock bajo");
        } else {
            out.println("\n" + "=".repeat(60));
            out.println("Total productos con stock bajo: " + contador);
        }
    }
    
    /**
     * Reporte por categorías
     */
    private void generarReporteCategorias(PrintWriter out, java.sql.Connection conn) 
            throws Exception {
        
        out.println("=== ANÁLISIS POR CATEGORÍA ===\n");
        out.println("Generado: " + new java.util.Date() + "\n");
        out.println("=" .repeat(60) + "\n");
        
        String sql = "SELECT categoria, COUNT(*) as productos, SUM(cantidad) as unidades, " +
                     "SUM(cantidad * precio) as valor_total " +
                     "FROM productos GROUP BY categoria ORDER BY valor_total DESC";
        
        java.sql.PreparedStatement stmt = conn.prepareStatement(sql);
        java.sql.ResultSet rs = stmt.executeQuery();
        
        while (rs.next()) {
            out.printf("📂 %s\n", rs.getString("categoria"));
            out.printf("   Productos: %d\n", rs.getInt("productos"));
            out.printf("   Unidades: %d\n", rs.getInt("unidades"));
            out.printf("   Valor Total: $%.2f\n\n", rs.getDouble("valor_total"));
        }
    }
    
    /**
     * Top 10 productos más valiosos
     */
    private void generarReporteMasValiosos(PrintWriter out, java.sql.Connection conn) 
            throws Exception {
        
        out.println("=== TOP 10 PRODUCTOS MÁS VALIOSOS ===\n");
        out.println("(Ordenados por valor total: precio × cantidad)\n");
        out.println("Generado: " + new java.util.Date() + "\n");
        out.println("=" .repeat(60) + "\n");
        
        String sql = "SELECT nombre, cantidad, precio, (cantidad * precio) as valor_total " +
                     "FROM productos ORDER BY valor_total DESC LIMIT 10";
        
        java.sql.PreparedStatement stmt = conn.prepareStatement(sql);
        java.sql.ResultSet rs = stmt.executeQuery();
        
        int pos = 1;
        while (rs.next()) {
            out.printf("%d. %s\n", pos++, rs.getString("nombre"));
            out.printf("   Cantidad: %d | Precio: $%.2f | Valor Total: $%.2f\n\n",
                rs.getInt("cantidad"),
                rs.getDouble("precio"),
                rs.getDouble("valor_total")
            );
        }
    }
    
    /**
     * Reporte de auditoría
     */
    private void generarReporteAuditoria(PrintWriter out, java.sql.Connection conn) 
            throws Exception {
        
        out.println("=== REPORTE DE AUDITORÍA (Últimos 7 días) ===\n");
        out.println("Generado: " + new java.util.Date() + "\n");
        out.println("=" .repeat(60) + "\n");
        
        String sql = "SELECT a.accion, a.detalles, a.fecha, u.usuario " +
                     "FROM auditoria a " +
                     "INNER JOIN usuarios u ON a.usuario_id = u.id " +
                     "WHERE a.fecha >= DATE_SUB(NOW(), INTERVAL 7 DAY) " +
                     "ORDER BY a.fecha DESC LIMIT 50";
        
        java.sql.PreparedStatement stmt = conn.prepareStatement(sql);
        java.sql.ResultSet rs = stmt.executeQuery();
        
        while (rs.next()) {
            out.printf("[%s] %s - %s\n", 
                rs.getTimestamp("fecha"),
                rs.getString("usuario"),
                rs.getString("accion")
            );
            out.printf("   %s\n\n", rs.getString("detalles"));
        }
    }
    
    /**
     * Reporte de proyecciones (simulado - requiere más lógica)
     */
    private void generarReporteProyecciones(PrintWriter out, java.sql.Connection conn) 
            throws Exception {
        
        out.println("=== PROYECCIONES DE STOCK ===\n");
        out.println("(Simulación - Requiere datos históricos)\n");
        out.println("Generado: " + new java.util.Date() + "\n");
        out.println("=" .repeat(60) + "\n");
        
        // Simular procesamiento pesado
        Thread.sleep(2000);
        
        out.println("⚠️ Esta funcionalidad requiere más datos históricos.\n");
        out.println("Próximamente se implementará el análisis predictivo basado en:");
        out.println("- Consumo histórico mensual");
        out.println("- Tendencias estacionales");
        out.println("- Predicción de reabastecimiento\n");
    }
    
    /**
     * Exporta el reporte a PDF (simulado)
     */
    private void exportarPDF(HttpServletResponse response, String tipo) throws IOException {
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=reporte-" + tipo + ".pdf");
        
        PrintWriter out = response.getWriter();
        out.println("Exportación a PDF en desarrollo.");
        out.println("Próximamente disponible con Apache PDFBox o iText.");
    }
    
    /**
     * Exporta el reporte a Excel (simulado)
     */
    private void exportarExcel(HttpServletResponse response, String tipo) throws IOException {
        response.setContentType("application/vnd.ms-excel");
        response.setHeader("Content-Disposition", "attachment; filename=reporte-" + tipo + ".xls");
        
        PrintWriter out = response.getWriter();
        out.println("Exportación a Excel en desarrollo.");
        out.println("Próximamente disponible con Apache POI.");
    }
}