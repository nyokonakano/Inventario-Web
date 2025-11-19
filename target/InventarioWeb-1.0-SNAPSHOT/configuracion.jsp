<%@page import="modelo.Usuario"%>
<%@page import="modelo.ConexionMySQL"%>
<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    Usuario user = (Usuario) session.getAttribute("usuario");
    if (user == null || !user.esAdministrador()) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    // Obtener información del sistema
    String dbVersion = "";
    int totalProductos = 0;
    int totalUsuarios = 0;
    int totalAuditorias = 0;
    
    try (Connection conn = ConexionMySQL.conectar()) {
        // Versión de MySQL
        DatabaseMetaData metaData = conn.getMetaData();
        dbVersion = metaData.getDatabaseProductName() + " " + metaData.getDatabaseProductVersion();
        
        // Contar productos
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM productos");
        if (rs.next()) totalProductos = rs.getInt(1);
        
        // Contar usuarios
        rs = stmt.executeQuery("SELECT COUNT(*) FROM usuarios");
        if (rs.next()) totalUsuarios = rs.getInt(1);
        
        // Contar auditorías
        rs = stmt.executeQuery("SELECT COUNT(*) FROM auditoria");
        if (rs.next()) totalAuditorias = rs.getInt(1);
        
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Configuración del Sistema</title>
    <style>
        :root {
            --primary: #2563eb;
            --primary-dark: #1e40af;
            --bg: #f8fafc;
            --surface: #ffffff;
            --text: #0f172a;
            --text-secondary: #64748b;
            --border: #e2e8f0;
            --success: #10b981;
            --warning: #f59e0b;
            --danger: #ef4444;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: var(--bg);
            padding: 24px;
            min-height: 100vh;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        .header {
            background: var(--surface);
            padding: 24px 32px;
            border-radius: 16px;
            border: 1px solid var(--border);
            margin-bottom: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            color: var(--text);
            font-size: 24px;
            font-weight: 600;
        }

        .btn {
            padding: 10px 20px;
            border-radius: 10px;
            border: none;
            font-weight: 500;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: all 0.2s;
            font-size: 14px;
        }

        .btn-secondary {
            background: var(--surface);
            color: var(--text);
            border: 1px solid var(--border);
        }

        .btn-secondary:hover {
            background: var(--bg);
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 24px;
        }

        .card {
            background: var(--surface);
            padding: 32px;
            border-radius: 16px;
            border: 1px solid var(--border);
        }

        .card h2 {
            color: var(--text);
            margin-bottom: 24px;
            font-size: 18px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 16px 0;
            border-bottom: 1px solid var(--border);
        }

        .info-row:last-child {
            border-bottom: none;
        }

        .info-label {
            color: var(--text-secondary);
            font-weight: 500;
            font-size: 14px;
        }

        .info-value {
            color: var(--text);
            font-weight: 600;
            font-size: 14px;
        }

        .action-btn {
            width: 100%;
            padding: 14px;
            margin: 12px 0;
            border: none;
            border-radius: 10px;
            font-weight: 500;
            font-size: 14px;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
        }

        .btn-danger {
            background: var(--danger);
            color: white;
        }

        .btn-danger:hover {
            background: #dc2626;
        }

        .btn-warning {
            background: var(--warning);
            color: white;
        }

        .btn-warning:hover {
            background: #d97706;
        }

        .btn-success {
            background: var(--success);
            color: white;
        }

        .btn-success:hover {
            background: #059669;
        }

        .status-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
        }

        .status-online {
            background: #d1fae5;
            color: #065f46;
        }

        .mensaje {
            background: #d1fae5;
            color: #065f46;
            padding: 16px;
            border-radius: 10px;
            margin-bottom: 24px;
            text-align: center;
            font-weight: 500;
            border: 1px solid #6ee7b7;
        }

        .error {
            background: #fee2e2;
            color: #991b1b;
            padding: 16px;
            border-radius: 10px;
            margin-bottom: 24px;
            text-align: center;
            font-weight: 500;
            border: 1px solid #fca5a5;
        }

        .warning-box {
            background: #fef3c7;
            border-left: 4px solid var(--warning);
            padding: 16px;
            border-radius: 10px;
            margin-top: 16px;
            color: #92400e;
            font-size: 14px;
        }

        .warning-box strong {
            display: block;
            margin-bottom: 6px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⚙️ Configuración del Sistema</h1>
            <a href="admin.jsp" class="btn btn-secondary">← Volver al Panel</a>
        </div>

        <%
            String mensaje = request.getParameter("mensaje");
            String error = request.getParameter("error");
            
            if ("respaldo_creado".equals(mensaje)) {
        %>
            <div class="mensaje">✅ Respaldo creado exitosamente</div>
        <%
            } else if ("datos_limpiados".equals(mensaje)) {
        %>
            <div class="mensaje">✅ Datos de prueba eliminados</div>
        <%
            } else if ("error_respaldo".equals(error)) {
        %>
            <div class="error">❌ Error al crear el respaldo</div>
        <%
            }
        %>

        <div class="grid">
            <!-- Información del Sistema -->
            <div class="card">
                <h2>📊 Información del Sistema</h2>
                <div class="info-row">
                    <span class="info-label">Estado del Sistema:</span>
                    <span class="status-badge status-online">● En línea</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Base de Datos:</span>
                    <span class="info-value">MySQL</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Total de Productos:</span>
                    <span class="info-value"><%= totalProductos %></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Total de Usuarios:</span>
                    <span class="info-value"><%= totalUsuarios %></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Registros de Auditoría:</span>
                    <span class="info-value"><%= totalAuditorias %></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Servidor:</span>
                    <span class="info-value">Apache Tomcat</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Java Version:</span>
                    <span class="info-value"><%= System.getProperty("java.version") %></span>
                </div>
            </div>

            <!-- Gestión de Base de Datos -->
            <div class="card">
                <h2>💾 Gestión de Base de Datos</h2>
                
                <form method="post" action="ConfiguracionServlet">
                    <input type="hidden" name="accion" value="exportar">
                    <button type="submit" class="action-btn btn-primary">
                        📤 Exportar Base de Datos
                    </button>
                </form>

                <form method="post" action="ConfiguracionServlet" 
                      onsubmit="return confirm('¿Estás seguro? Esto puede tardar varios minutos.');">
                    <input type="hidden" name="accion" value="optimizar">
                    <button type="submit" class="action-btn btn-success">
                        🔧 Optimizar Tablas
                    </button>
                </form>

                <form method="post" action="ConfiguracionServlet" 
                      onsubmit="return confirm('¿Limpiar logs antiguos (más de 30 días)?');">
                    <input type="hidden" name="accion" value="limpiar_logs">
                    <button type="submit" class="action-btn btn-warning">
                        🧹 Limpiar Auditoría Antigua
                    </button>
                </form>

                <div class="warning-box">
                    <strong>⚠️ Advertencia:</strong>
                    Estas operaciones pueden afectar el rendimiento temporalmente.
                </div>
            </div>

            <!-- Mantenimiento del Sistema -->
            <div class="card">
                <h2>🛠️ Mantenimiento</h2>
                
                <a href="auditoria.jsp" class="action-btn btn-primary" style="text-decoration:none;">
                    🔍 Ver Logs de Auditoría
                </a>

                <form method="post" action="ConfiguracionServlet" 
                      onsubmit="return confirm('¿Reiniciar caché del sistema?');">
                    <input type="hidden" name="accion" value="limpiar_cache">
                    <button type="submit" class="action-btn btn-warning">
                        🔄 Limpiar Caché
                    </button>
                </form>

                <form method="post" action="ConfiguracionServlet" 
                      onsubmit="return confirm('⚠️ PELIGRO: ¿Eliminar TODOS los productos de prueba?');">
                    <input type="hidden" name="accion" value="eliminar_pruebas">
                    <button type="submit" class="action-btn btn-danger">
                        🗑️ Eliminar Datos de Prueba
                    </button>
                </form>

                <div class="warning-box">
                    <strong>⚠️ Cuidado:</strong>
                    La eliminación de datos es permanente.
                </div>
            </div>

            <!-- Seguridad -->
            <div class="card">
                <h2>🔒 Seguridad</h2>
                
                <div class="info-row">
                    <span class="info-label">Sesiones Activas:</span>
                    <span class="info-value">1</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Último Acceso Admin:</span>
                    <span class="info-value"><%= new java.util.Date() %></span>
                </div>

                <form method="post" action="ConfiguracionServlet" 
                      onsubmit="return confirm('¿Cerrar todas las sesiones excepto la tuya?');">
                    <input type="hidden" name="accion" value="cerrar_sesiones">
                    <button type="submit" class="action-btn btn-warning">
                        🚪 Cerrar Todas las Sesiones
                    </button>
                </form>

                <form method="post" action="ConfiguracionServlet">
                    <input type="hidden" name="accion" value="cambiar_clave">
                    <button type="submit" class="action-btn btn-primary">
                        🔑 Cambiar mi Contraseña
                    </button>
                </form>
            </div>

            <!-- Respaldos Automáticos -->
            <div class="card">
                <h2>⏰ Configuración de Respaldos</h2>
                
                <div class="info-row">
                    <span class="info-label">Respaldo Automático:</span>
                    <span class="info-value">Desactivado</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Último Respaldo:</span>
                    <span class="info-value">Nunca</span>
                </div>

                <form method="post" action="ConfiguracionServlet">
                    <input type="hidden" name="accion" value="activar_respaldo">
                    <button type="submit" class="action-btn btn-success">
                        ✅ Activar Respaldo Diario
                    </button>
                </form>

                <div class="warning-box">
                    <strong>ℹ️ Información:</strong>
                    Los respaldos automáticos se ejecutarán a las 2:00 AM.
                </div>
            </div>

            <!-- Información Adicional -->
            <div class="card">
                <h2>ℹ️ Acerca del Sistema</h2>
                
                <div class="info-row">
                    <span class="info-label">Versión:</span>
                    <span class="info-value">1.0.0</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Desarrollado por:</span>
                    <span class="info-value">Tu Empresa</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Fecha de Deploy:</span>
                    <span class="info-value"><%= new java.text.SimpleDateFormat("dd/MM/yyyy").format(new java.util.Date()) %></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Licencia:</span>
                    <span class="info-value">MIT</span>
                </div>

                <a href="https://github.com" target="_blank" class="action-btn btn-primary" 
                   style="text-decoration:none; margin-top:15px;">
                    📚 Documentación
                </a>
            </div>
        </div>
    </div>
</body>
</html>