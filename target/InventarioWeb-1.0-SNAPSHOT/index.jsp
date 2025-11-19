<%@page import="modelo.Usuario"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    Usuario user = (Usuario) session.getAttribute("usuario");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Inventario - <%= user.getRolNombre() %></title>
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
            }

            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background-color: var(--bg);
                color: var(--text);
                padding: 24px;
                min-height: 100vh;
            }

            .container {
                max-width: 800px;
                margin: 0 auto;
            }

            .header {
                background: var(--surface);
                padding: 24px 32px;
                border-radius: 16px;
                margin-bottom: 32px;
                border: 1px solid var(--border);
                display: flex;
                justify-content: space-between;
                align-items: center;
            }

            .header h1 {
                font-size: 24px;
                font-weight: 600;
                color: var(--text);
            }

            .user-section {
                display: flex;
                align-items: center;
                gap: 12px;
            }

            .role-badge {
                background: var(--warning);
                color: white;
                padding: 4px 12px;
                border-radius: 12px;
                font-size: 12px;
                font-weight: 500;
            }

            .admin-link {
                background: var(--success);
                color: white;
                padding: 8px 16px;
                border-radius: 8px;
                text-decoration: none;
                font-weight: 500;
                font-size: 14px;
                transition: all 0.2s;
            }

            .admin-link:hover {
                background: #059669;
            }

            .inline-form {
                display: inline;
            }

            button.logout {
                background: var(--surface);
                color: var(--text);
                border: 1px solid var(--border);
                padding: 8px 16px;
                border-radius: 8px;
                cursor: pointer;
                font-weight: 500;
                font-size: 14px;
                transition: all 0.2s;
            }

            button.logout:hover {
                background: var(--bg);
            }

            .form-card {
                background: var(--surface);
                padding: 32px;
                border-radius: 16px;
                border: 1px solid var(--border);
                margin-bottom: 24px;
            }

            .form-card h2 {
                color: var(--text);
                margin-bottom: 24px;
                font-size: 20px;
                font-weight: 600;
            }

            input[type="text"],
            input[type="number"] {
                width: 100%;
                padding: 12px 16px;
                margin-bottom: 16px;
                border: 1px solid var(--border);
                border-radius: 10px;
                font-size: 15px;
                transition: all 0.2s;
                background: var(--surface);
            }

            input[type="text"]:focus,
            input[type="number"]:focus {
                outline: none;
                border-color: var(--primary);
                background: var(--bg);
            }

            button[type="submit"] {
                width: 100%;
                background: var(--primary);
                color: white;
                border: none;
                padding: 14px;
                border-radius: 10px;
                font-size: 15px;
                font-weight: 500;
                cursor: pointer;
                transition: all 0.2s;
            }

            button[type="submit"]:hover {
                background: var(--primary-dark);
            }

            .actions {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 16px;
            }

            .action-btn {
                background: var(--surface);
                border: 1px solid var(--border);
                color: var(--text);
                padding: 14px;
                border-radius: 10px;
                font-weight: 500;
                cursor: pointer;
                text-decoration: none;
                display: block;
                text-align: center;
                transition: all 0.2s;
            }

            .action-btn:hover {
                background: var(--primary);
                color: white;
                border-color: var(--primary);
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

            .info-box {
                background: #fef3c7;
                border-left: 4px solid var(--warning);
                padding: 16px;
                border-radius: 10px;
                margin-bottom: 24px;
            }

            .info-box p {
                margin: 0;
                color: #92400e;
                font-size: 14px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <!-- Header -->
            <div class="header">
                <h1>📦 Gestión de Inventario</h1>
                <div class="user-section">
                    <div>
                        <strong><%= user.getNombreCompleto() %></strong>
                        <span class="role-badge"><%= user.getRolNombre() %></span>
                    </div>
                    
                    <% if (user.esAdministrador()) { %>
                        <a href="admin.jsp" class="admin-link">🛡️ Panel Admin</a>
                    <% } %>
                    
                    <form action="logout" method="post" class="inline-form">
                        <button type="submit" class="logout">Salir</button>
                    </form>
                </div>
            </div>

            <!-- Mensajes -->
            <%
                String error = request.getParameter("error");
                String mensaje = request.getParameter("mensaje");
                
                if ("datos_incompletos".equals(error)) {
            %>
                <div class="error">⚠️ Por favor complete todos los campos</div>
            <%
                } else if ("producto_existe".equals(error)) {
            %>
                <div class="error">⚠️ El producto ya existe en el inventario</div>
            <%
                } else if ("agregado".equals(mensaje)) {
            %>
                <div class="mensaje">✅ Producto agregado correctamente</div>
            <%
                }
            %>

            <!-- Información del rol -->
            <% if (user.esUsuario()) { %>
            <div class="info-box">
                <p>ℹ️ <strong>Permisos de usuario:</strong> Puedes agregar productos y ver el inventario. Para editar o eliminar, contacta a un administrador.</p>
            </div>
            <% } %>

            <!-- Formulario para agregar producto -->
            <div class="form-card">
                <h2>➕ Agregar Nuevo Producto</h2>
                <form method="post" action="productos">
                    <input type="text" name="nombre" placeholder="Nombre del producto" required>
                    <input type="number" name="cantidad" placeholder="Cantidad" required min="0">
                    <input type="number" step="0.01" name="precio" placeholder="Precio" required min="0">
                    <input type="text" name="categoria" placeholder="Categoría" required>
                    <button type="submit">Agregar Producto</button>
                </form>
            </div>

            <!-- Acciones -->
            <div class="actions">
                <form action="productos" method="get" style="margin: 0;">
                    <button type="submit" class="action-btn">📋 Ver Inventario</button>
                </form>
                
                <% if (user.esAdministrador()) { %>
                    <a href="usuarios.jsp" class="action-btn">👥 Gestionar Usuarios</a>
                <% } else { %>
                    <a href="perfil.jsp" class="action-btn">👤 Mi Perfil</a>
                <% } %>
            </div>
        </div>
    </body>
</html>