package controlador;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import modelo.*;
import java.io.IOException;

/**
 * Servlet que se ejecuta al iniciar la aplicación
 * Inicia todos los sistemas de concurrencia y distribución
 */
@WebServlet(
    name = "InicializadorServlet",
    urlPatterns = {"/inicializar"},
    loadOnStartup = 1  // Se ejecuta automáticamente al iniciar
)
public class InicializadorServlet extends HttpServlet {
    
    @Override
    public void init() throws ServletException {
        System.out.println("\n");
        System.out.println("════════════════════════════════════════════════════════");
        System.out.println("    🚀 INICIANDO SISTEMA DE INVENTARIO CONCURRENTE");
        System.out.println("════════════════════════════════════════════════════════\n");
        
        try {
            // 1️⃣ Iniciar Sistema de Notificaciones
            System.out.println("1️⃣ Iniciando Sistema de Notificaciones...");
            NotificacionManager.iniciar();
            
            // Suscribir al admin a todas las notificaciones
            NotificacionManager.suscribir(1, 
                NotificacionManager.TipoNotificacion.STOCK_BAJO,
                NotificacionManager.TipoNotificacion.STOCK_CRITICO,
                NotificacionManager.TipoNotificacion.PRODUCTO_AGOTADO,
                NotificacionManager.TipoNotificacion.ACTIVIDAD_SOSPECHOSA
            );
            
            // 2️⃣ Precargar productos populares en caché
            System.out.println("\n2️⃣ Precargando Caché de Productos...");
            CacheManager.precargarProductosPopulares(20);
            
            // 3️⃣ Programar tareas asíncronas
            System.out.println("\n3️⃣ Programando Tareas Asíncronas...");
            AsyncTaskManager.programarVerificacionStockBajo(30); // Cada 30 minutos
            
            // 4️⃣ Verificación inicial de locks
            System.out.println("\n4️⃣ Inicializando Control de Concurrencia...");
            ProductoConcurrenteManager.limpiarLocksInactivos();
            
            // 5️⃣ Resumen de inicialización
            System.out.println("\n════════════════════════════════════════════════════════");
            System.out.println("    ✅ SISTEMA INICIADO CORRECTAMENTE");
            System.out.println("════════════════════════════════════════════════════════");
            System.out.println(NotificacionManager.getEstadisticas());
            System.out.println(CacheManager.getEstadisticas());
            System.out.println(ProductoConcurrenteManager.getEstadisticas());
            System.out.println("════════════════════════════════════════════════════════\n");
            
            // 6️⃣ Enviar notificación de inicio
            NotificacionManager.enviarNotificacion(
                "Sistema iniciado",
                NotificacionManager.TipoNotificacion.SISTEMA,
                "Todos los módulos de concurrencia y distribución están operativos",
                3
            );
            
        } catch (Exception e) {
            System.err.println("❌ ERROR CRÍTICO AL INICIAR EL SISTEMA");
            e.printStackTrace();
            throw new ServletException("Error al inicializar sistemas concurrentes", e);
        }
    }
    
    @Override
    public void destroy() {
        System.out.println("\n");
        System.out.println("════════════════════════════════════════════════════════");
        System.out.println("    ⏹️ DETENIENDO SISTEMA DE INVENTARIO");
        System.out.println("════════════════════════════════════════════════════════\n");
        
        try {
            // Detener todos los sistemas en orden inverso
            System.out.println("1️⃣ Deteniendo NotificacionManager...");
            NotificacionManager.shutdown();
            
            System.out.println("2️⃣ Deteniendo AsyncTaskManager...");
            AsyncTaskManager.shutdown();
            
            System.out.println("3️⃣ Limpiando CacheManager...");
            CacheManager.shutdown();
            
            System.out.println("4️⃣ Limpiando locks...");
            ProductoConcurrenteManager.limpiarLocksInactivos();
            
            System.out.println("\n════════════════════════════════════════════════════════");
            System.out.println("    ✅ SISTEMA DETENIDO CORRECTAMENTE");
            System.out.println("════════════════════════════════════════════════════════\n");
            
        } catch (Exception e) {
            System.err.println("❌ Error al detener sistemas");
            e.printStackTrace();
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Endpoint para verificar el estado del sistema
        Usuario user = (Usuario) request.getSession().getAttribute("usuario");
        
        if (user == null || !user.esAdministrador()) {
            response.sendRedirect("index.jsp?error=acceso_denegado");
            return;
        }
        
        response.setContentType("text/html;charset=UTF-8");
        
        StringBuilder html = new StringBuilder();
        html.append("<!DOCTYPE html><html><head>");
        html.append("<meta charset='UTF-8'>");
        html.append("<title>Estado del Sistema</title>");
        html.append("<style>");
        html.append("body { font-family: 'Courier New', monospace; background: #1e1e1e; color: #00ff00; padding: 20px; }");
        html.append("pre { background: #000; padding: 20px; border-radius: 10px; border: 2px solid #00ff00; }");
        html.append("h1 { color: #00ff00; text-align: center; }");
        html.append(".btn { background: #00ff00; color: #000; padding: 10px 20px; text-decoration: none; ");
        html.append("border-radius: 5px; display: inline-block; margin: 10px; font-weight: bold; }");
        html.append("</style></head><body>");
        
        html.append("<h1>🖥️ ESTADO DEL SISTEMA - INVENTARIO CONCURRENTE</h1>");
        html.append("<a class='btn' href='admin.jsp'>← Volver al Panel</a>");
        html.append("<a class='btn' href='inicializar?action=stats'>🔄 Actualizar</a>");
        
        html.append("<pre>");
        html.append("════════════════════════════════════════════════════════\n");
        html.append("              📊 ESTADÍSTICAS EN TIEMPO REAL\n");
        html.append("════════════════════════════════════════════════════════\n\n");
        
        html.append("🔔 SISTEMA DE NOTIFICACIONES\n");
        html.append(NotificacionManager.getEstadisticas());
        html.append("\n\n");
        
        html.append("💾 SISTEMA DE CACHÉ\n");
        html.append(CacheManager.getEstadisticas());
        html.append("\n\n");
        
        html.append("🔒 CONTROL DE CONCURRENCIA\n");
        html.append(ProductoConcurrenteManager.getEstadisticas());
        html.append("\n\n");
        
        html.append("⚡ THREAD POOLS ASÍNCRONOS\n");
        html.append(AsyncTaskManager.getEstadisticas());
        html.append("\n\n");
        
        html.append("🌐 WEBSOCKET\n");
        html.append(InventarioWebSocket.getEstadisticas());
        html.append("\n\n");
        
        html.append("════════════════════════════════════════════════════════\n");
        html.append("Última actualización: " + new java.util.Date() + "\n");
        html.append("════════════════════════════════════════════════════════");
        html.append("</pre>");
        
        html.append("</body></html>");
        
        response.getWriter().println(html.toString());
    }
}