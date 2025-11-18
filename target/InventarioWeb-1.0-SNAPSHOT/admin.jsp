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
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                padding: 20px;
            }

            .dashboard {
                max-width: 1400px;
                margin: 0 auto;
            }

            .header {
                background: white;
                padding: 20px 30px;
                border-radius: 15px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 30px;
            }

            .header h1 {
                color: #667eea;
                font-size: 28px;
            }

            .user-info {
                display: flex;
                align-items: center;
                gap: 15px;
            }

            .user-badge {
                background: #667eea;
                color: white;
                padding: 8px 15px;
                border-radius: 20px;
                font-size: 14px;
                font-weight: bold;
            }

            .logout-btn {
                background: #f56565;
                color: white;
                border: none;
                padding: 10px 20px;
                border-radius: 8px;
                cursor: pointer;
                font-weight: bold;
                transition: all 0.3s;
            }

            .logout-btn:hover {
                background: #c53030;
                transform: translateY(-2px);
            }

            .cards-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 20px;
                margin-bottom: 30px;
            }

            .card {
                background: white;
                padding: 30px;
                border-radius: 15px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                transition: transform 0.3s, box-shadow 0.3s;
                cursor: pointer;
                text-decoration: none;
                color: inherit;
                display: block;
            }

            .card:hover {
                transform: translateY(-5px);
                box-shadow: 0 15px 40px rgba(0,0,0,0.15);
            }

            .card-icon {
                font-size: 48px;
                margin-bottom: 15px;
            }

            .card h3 {
                color: #2d3748;
                margin-bottom: 10px;
                font-size: 20px;
            }

            .card p {
                color: #718096;
                font-size: 14px;
                line-height: 1.5;
            }

            .card-productos { border-left: 5px solid #667eea; }
            .card-usuarios { border-left: 5px solid #48bb78; }
            .card-reportes { border-left: 5px solid #ed8936; }
            .card-configuracion { border-left: 5px solid #9f7aea; }

            .quick-actions {
                background: white;
                padding: 30px;
                border-radius: 15px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            }

            .quick-actions h2 {
                color: #2d3748;
                margin-bottom: 20px;
                font-size: 24px;
            }

            .action-buttons {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 15px;
            }

            .action-btn {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                padding: 15px 25px;
                border-radius: 10px;
                cursor: pointer;
                font-weight: bold;
                transition: all 0.3s;
                text-decoration: none;
                display: inline-block;
                text-align: center;
            }

            .action-btn:hover {
                transform: translateY(-3px);
                box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
            }

            .stats {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
                gap: 15px;
                margin-top: 20px;
            }

            .stat-box {
                background: #f7fafc;
                padding: 20px;
                border-radius: 10px;
                text-align: center;
            }

            .stat-number {
                font-size: 32px;
                font-weight: bold;
                color: #667eea;
            }

            .stat-label {
                color: #718096;
                font-size: 14px;
                margin-top: 5px;
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