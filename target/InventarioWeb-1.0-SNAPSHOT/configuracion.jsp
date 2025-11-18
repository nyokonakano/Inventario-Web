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
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        .header {
            background: white;
            padding: 20px 30px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            color: #667eea;
            font-size: 28px;
        }

        .btn {
            padding: 10px 20px;
            border-radius: 8px;
            border: none;
            font-weight: bold;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s;
        }

        .btn-secondary {
            background: #718096;
            color: white;
        }

        .btn-secondary:hover {
            background: #4a5568;
            transform: translateY(-2px);
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 20px;
        }

        .card {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }

        .card h2 {
            color: #1f2937;
            margin-bottom: 20px;
            font-size: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 15px;
            border-bottom: 1px solid #e5e7eb;
        }

        .info-row:last-child {
            border-bottom: none;
        }

        .info-label {
            color: #6b7280;
            font-weight: 500;
        }

        .info-value {
            color: #1f2937;
            font-weight: bold;
        }

        .action-btn {
            width: 100%;
            padding: 15px;
            margin: 10px 0;
            border: none;
            border-radius: 10px;
            font-weight: bold;
            font-size: 15px;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }

        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
        }

        .btn-danger {
            background: #ef4444;
            color: white;
        }

        .btn-danger:hover {
            background: #dc2626;
            transform: translateY(-2px);
        }

        .btn-warning {
            background: #f59e0b;
            color: white;
        }

        .btn-warning:hover {
            background: #d97706;
            transform: translateY(-2px);
        }

        .btn-success {
            background: #10b981;
            color: white;
        }

        .btn-success:hover {
            background: #059669;
            transform: translateY(-2px);
        }

        .status-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: bold;
        }

        .status-online {
            background: #d1fae5;
            color: #065f46;
        }

        .mensaje {
            background: #10b981;
            color: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
            font-weight: bold;
        }

        .error {
            background: #ef4444;
            color: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
            font-weight: bold;
        }

        .warning-box {
            background: #fef3c7;
            border-left: 4px solid #f59e0b;
            padding: 15px;
            border-radius: 8px;
            margin-top: 15px;
            color: #92400e;
        }

        .warning-box strong {
            display: block;
            margin-bottom: 5px;
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