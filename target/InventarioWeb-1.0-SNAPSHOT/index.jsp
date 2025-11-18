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
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: 'Segoe UI', sans-serif;
                background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
                min-height: 100vh;
                padding: 20px;
            }

            .container {
                max-width: 800px;
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
                color: #6366f1;
                font-size: 24px;
            }

            .user-section {
                display: flex;
                align-items: center;
                gap: 15px;
            }

            .role-badge {
                background: <%= user.esAdministrador() ? "#10b981" : "#f59e0b" %>;
                color: white;
                padding: 6px 12px;
                border-radius: 15px;
                font-size: 12px;
                font-weight: bold;
            }

            .admin-link {
                background: #10b981;
                color: white;
                padding: 8px 15px;
                border-radius: 8px;
                text-decoration: none;
                font-weight: bold;
                transition: all 0.3s;
            }

            .admin-link:hover {
                background: #059669;
                transform: translateY(-2px);
            }

            form.inline-form {
                display: inline;
            }

            button.logout {
                background: #ef4444;
                color: white;
                border: none;
                padding: 8px 15px;
                border-radius: 8px;
                cursor: pointer;
                font-weight: bold;
                transition: all 0.3s;
            }

            button.logout:hover {
                background: #dc2626;
            }

            .form-card {
                background: white;
                padding: 30px;
                border-radius: 15px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                margin-bottom: 20px;
            }

            .form-card h2 {
                color: #1f2937;
                margin-bottom: 20px;
                font-size: 20px;
            }

            input[type="text"],
            input[type="number"] {
                width: 100%;
                padding: 12px;
                margin-bottom: 15px;
                border: 2px solid #e5e7eb;
                border-radius: 8px;
                font-size: 16px;
                transition: border 0.3s;
            }

            input[type="text"]:focus,
            input[type="number"]:focus {
                outline: none;
                border-color: #6366f1;
            }

            button[type="submit"] {
                width: 100%;
                background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
                color: white;
                border: none;
                padding: 14px;
                border-radius: 8px;
                font-size: 16px;
                font-weight: bold;
                cursor: pointer;
                transition: all 0.3s;
            }

            button[type="submit"]:hover {
                transform: translateY(-2px);
                box-shadow: 0 10px 25px rgba(99, 102, 241, 0.4);
            }

            .actions {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 15px;
            }

            .action-btn {
                background: white;
                border: 2px solid #6366f1;
                color: #6366f1;
                padding: 12px;
                border-radius: 8px;
                font-weight: bold;
                cursor: pointer;
                transition: all 0.3s;
                text-decoration: none;
                display: block;
                text-align: center;
            }

            .action-btn:hover {
                background: #6366f1;
                color: white;
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

            .info-box {
                background: #fef3c7;
                border-left: 4px solid #f59e0b;
                padding: 15px;
                border-radius: 8px;
                margin-bottom: 20px;
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