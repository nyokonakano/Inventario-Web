<%@page import="modelo.Usuario"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    Usuario user = (Usuario) session.getAttribute("usuario");
    if (user == null || !user.esAdministrador()) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Panel de Administración</title>
        <style>
            :root {
                --primary: #2563eb;
                --primary-dark: #1e40af;
                --secondary: #64748b;
                --accent: #f97316;
                --success: #10b981;
                --danger: #ef4444;
                --warning: #f59e0b;
                --bg: #f8fafc;
                --surface: #ffffff;
                --text: #0f172a;
                --text-secondary: #64748b;
                --border: #e2e8f0;
            }

            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                background-color: var(--bg);
                color: var(--text);
                line-height: 1.6;
                padding: 24px;
            }

            .dashboard {
                max-width: 1400px;
                margin: 0 auto;
            }

            .header {
                background: var(--surface);
                padding: 24px 32px;
                border-radius: 16px;
                margin-bottom: 32px;
                display: flex;
                justify-content: space-between;
                align-items: center;
                border: 1px solid var(--border);
            }

            .header h1 {
                color: var(--text);
                font-size: 24px;
                font-weight: 600;
                letter-spacing: -0.5px;
            }

            .user-info {
                display: flex;
                align-items: center;
                gap: 16px;
            }

            .user-badge {
                background: var(--primary);
                color: white;
                padding: 6px 16px;
                border-radius: 20px;
                font-size: 13px;
                font-weight: 500;
            }

            .logout-btn {
                background: var(--surface);
                color: var(--text);
                border: 1px solid var(--border);
                padding: 8px 20px;
                border-radius: 8px;
                cursor: pointer;
                font-weight: 500;
                font-size: 14px;
                transition: all 0.2s;
            }

            .logout-btn:hover {
                background: var(--bg);
                border-color: var(--secondary);
            }

            .cards-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
                gap: 24px;
                margin-bottom: 32px;
            }

            .card {
                background: var(--surface);
                padding: 32px;
                border-radius: 16px;
                border: 1px solid var(--border);
                text-decoration: none;
                color: inherit;
                display: block;
                transition: all 0.2s;
                position: relative;
                overflow: hidden;
            }

            .card::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                width: 4px;
                height: 100%;
                background: var(--primary);
                transform: scaleY(0);
                transition: transform 0.2s;
            }

            .card:hover::before {
                transform: scaleY(1);
            }

            .card:hover {
                border-color: var(--primary);
                transform: translateY(-2px);
            }

            .card-icon {
                font-size: 32px;
                margin-bottom: 16px;
                opacity: 0.9;
            }

            .card h3 {
                color: var(--text);
                margin-bottom: 8px;
                font-size: 18px;
                font-weight: 600;
            }

            .card p {
                color: var(--text-secondary);
                font-size: 14px;
            }

            .quick-actions {
                background: var(--surface);
                padding: 32px;
                border-radius: 16px;
                border: 1px solid var(--border);
            }

            .quick-actions h2 {
                color: var(--text);
                margin-bottom: 24px;
                font-size: 20px;
                font-weight: 600;
            }

            .action-buttons {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 16px;
            }

            .action-btn {
                background: var(--primary);
                color: white;
                border: none;
                padding: 14px 24px;
                border-radius: 10px;
                cursor: pointer;
                font-weight: 500;
                font-size: 14px;
                text-decoration: none;
                display: inline-block;
                text-align: center;
                transition: all 0.2s;
            }

            .action-btn:hover {
                background: var(--primary-dark);
                transform: translateY(-1px);
            }

            .stats {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
                gap: 16px;
                margin-top: 24px;
            }

            .stat-box {
                background: var(--bg);
                padding: 20px;
                border-radius: 12px;
                text-align: center;
                border: 1px solid var(--border);
            }

            .stat-number {
                font-size: 28px;
                font-weight: 700;
                color: var(--primary);
            }

            .stat-label {
                color: var(--text-secondary);
                font-size: 13px;
                font-weight: 500;
            }
        </style>
    </head>
    <body>
        <div class="dashboard">
            <!-- Header -->
            <div class="header">
                <h1>🛡️ Panel de Administración</h1>
                <div class="user-info">
                    <span><strong><%= user.getNombreCompleto() %></strong></span>
                    <span class="user-badge">ADMIN</span>
                    <form action="logout" method="post" style="margin: 0;">
                        <button type="submit" class="logout-btn">Cerrar Sesión</button>
                    </form>
                </div>
            </div>

            <!-- Cards Grid -->
            <div class="cards-grid">
                <a href="productos" class="card card-productos">
                    <div class="card-icon">📦</div>
                    <h3>Gestión de Productos</h3>
                    <p>Ver, crear, editar y eliminar productos del inventario</p>
                </a>

                <a href="usuarios.jsp" class="card card-usuarios">
                    <div class="card-icon">👥</div>
                    <h3>Gestión de Usuarios</h3>
                    <p>Administrar usuarios y asignar roles</p>
                </a>

                <a href="reportes.jsp" class="card card-reportes">
                    <div class="card-icon">📊</div>
                    <h3>Reportes</h3>
                    <p>Estadísticas y análisis del inventario</p>
                </a>

                <a href="configuracion.jsp" class="card card-configuracion">
                    <div class="card-icon">⚙️</div>
                    <h3>Configuración</h3>
                    <p>Ajustes del sistema y respaldos</p>
                </a>
            </div>

            <!-- Quick Actions -->
            <div class="quick-actions">
                <h2>Acciones Rápidas</h2>
                <div class="action-buttons">
                    <a href="index.jsp" class="action-btn">➕ Agregar Producto</a>
                    <a href="productos" class="action-btn">📋 Ver Inventario</a>
                    <a href="usuarios.jsp?action=nuevo" class="action-btn">👤 Nuevo Usuario</a>
                    <a href="auditoria.jsp" class="action-btn">🔍 Ver Auditoría</a>
                </div>

                <!-- Estadísticas -->
                <div class="stats">
                    <div class="stat-box">
                        <div class="stat-number" id="totalProductos">--</div>
                        <div class="stat-label">Productos</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-number" id="totalUsuarios">--</div>
                        <div class="stat-label">Usuarios</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-number" id="valorInventario">$--</div>
                        <div class="stat-label">Valor Total</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-number" id="bajosStock">--</div>
                        <div class="stat-label">Stock Bajo</div>
                    </div>
                </div>
            </div>
        </div>

        <script>
            // Cargar estadísticas (puedes hacer esto con AJAX)
            // Por ahora valores de ejemplo
            document.getElementById('totalProductos').textContent = '150';
            document.getElementById('totalUsuarios').textContent = '12';
            document.getElementById('valorInventario').textContent = '$45,320';
            document.getElementById('bajosStock').textContent = '8';
        </script>
    </body>
</html>