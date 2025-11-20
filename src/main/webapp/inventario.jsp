<%@page import="java.util.List"%>
<%@page import="modelo.Producto"%>
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
        <title>Inventario</title>
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
                max-width: 1600px;
                margin: 0 auto;
            }

            .header {
                background: var(--surface);
                padding: 24px 32px;
                border-radius: 16px;
                border: 1px solid var(--border);
                margin-bottom: 24px;
            }

            .header h1 {
                color: var(--text);
                margin-bottom: 12px;
                font-size: 24px;
                font-weight: 600;
            }

            .user-info {
                display: flex;
                justify-content: space-between;
                align-items: center;
                font-size: 14px;
                color: var(--text-secondary);
            }

            .role-badge {
                background: var(--warning);
                color: white;
                padding: 4px 12px;
                border-radius: 12px;
                font-size: 12px;
                font-weight: 500;
            }

            .top-bar {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 24px;
                gap: 16px;
            }

            .search-form {
                display: flex;
                gap: 12px;
                flex: 1;
                max-width: 600px;
            }

            input[type="text"] {
                flex: 1;
                padding: 12px 16px;
                font-size: 14px;
                border-radius: 10px;
                border: 1px solid var(--border);
                background: var(--surface);
                transition: all 0.2s;
            }

            input[type="text"]:focus {
                outline: none;
                border-color: var(--primary);
            }

            button {
                padding: 12px 20px;
                font-size: 14px;
                border-radius: 10px;
                border: none;
                font-weight: 500;
                cursor: pointer;
                transition: all 0.2s;
            }

            .btn-primary {
                background: var(--primary);
                color: white;
            }

            .btn-primary:hover {
                background: var(--primary-dark);
            }

            .btn-secondary {
                background: var(--surface);
                color: var(--text);
                border: 1px solid var(--border);
            }

            .btn-secondary:hover {
                background: var(--bg);
            }

            .btn-danger {
                background: var(--danger);
                color: white;
                padding: 8px 14px;
                font-size: 13px;
            }

            .btn-danger:hover {
                background: #dc2626;
            }

            .btn-edit {
                background: var(--warning);
                color: white;
                padding: 8px 14px;
                font-size: 13px;
                margin-right: 8px;
            }

            .btn-edit:hover {
                background: #d97706;
            }

            table {
                width: 100%;
                border-collapse: separate;
                border-spacing: 0;
                background: var(--surface);
                border-radius: 16px;
                overflow: hidden;
                border: 1px solid var(--border);
            }

            thead {
                background: var(--bg);
            }

            th {
                padding: 16px 20px;
                text-align: left;
                font-weight: 600;
                color: var(--text);
                font-size: 13px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            td {
                padding: 16px 20px;
                border-top: 1px solid var(--border);
                font-size: 14px;
            }

            tr:hover td {
                background: var(--bg);
            }

            .no-result {
                text-align: center;
                padding: 48px;
                color: var(--text-secondary);
            }

            .permissions-warning {
                background: #fef3c7;
                border-left: 4px solid var(--warning);
                padding: 16px 20px;
                border-radius: 10px;
                margin-bottom: 24px;
                color: #92400e;
                font-size: 14px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📋 Inventario de Productos</h1>
                <div class="user-info">
                    <span><strong><%= user.getNombreCompleto() %></strong> - <span class="role-badge"><%= user.getRolNombre() %></span></span>
                </div>
            </div>

            <% if (!user.esAdministrador()) { %>
            <div class="permissions-warning">
                ⚠️ <strong>Vista limitada:</strong> Solo puedes ver el inventario. Para editar o eliminar productos, contacta a un administrador.
            </div>
            <% } %>

            <div class="top-bar">
                <form action="<%= user.esAdministrador() ? "admin.jsp" : "index.jsp" %>" method="get">
                    <button type="submit" class="btn-secondary">← Volver</button>
                </form>

                <form action="productos" method="get" class="search-form">
                    <input type="text" name="busqueda" placeholder="Buscar por nombre o categoría" 
                           value="<%= request.getParameter("busqueda") != null ? request.getParameter("busqueda") : "" %>">
                    <button type="submit" class="btn-primary">🔍 Buscar</button>
                </form>
            </div>

            <table>
                <thead>
                    <tr>
                        <th>Nombre</th>
                        <th>Cantidad</th>
                        <th>Precio</th>
                        <th>Categoría</th>
                        <th>Total</th>
                        <% if (user.esAdministrador()) { %>
                        <th>Acciones</th>
                        <% } %>
                    </tr>
                </thead>
                <tbody>
                    <%
                        List<Producto> lista = (List<Producto>) request.getAttribute("listaProductos");
                        if (lista != null && !lista.isEmpty()) {
                            for (Producto p : lista) {
                    %>
                    <tr>
                        <td><strong><%= p.getNombre()%></strong></td>
                        <td><%= p.getCantidad()%></td>
                        <td>$<%= String.format("%.2f", p.getPrecio())%></td>
                        <td><%= p.getCategoria()%></td>
                        <td><strong>$<%= String.format("%.2f", p.getCantidad() * p.getPrecio())%></strong></td>
                        
                        <% if (user.esAdministrador()) { %>
                        <td>
                            <!-- Editar -->
                            <form method="get" action="editar" style="display:inline;">
                                <input type="hidden" name="nombre" value="<%= p.getNombre()%>">
                                <button type="submit" class="btn-edit">✏️ Editar</button>
                            </form>

                            <!-- Eliminar -->
                            <form method="post" action="productos" style="display:inline;" 
                                  onsubmit="return confirm('¿Está seguro de eliminar <%= p.getNombre()%>?');">
                                <input type="hidden" name="accion" value="eliminar">
                                <input type="hidden" name="nombre" value="<%= p.getNombre()%>">
                                <button type="submit" class="btn-danger">🗑️ Eliminar</button>
                            </form>
                        </td>
                        <% } %>
                    </tr>
                    <%
                            }
                        } else {
                    %>
                    <tr>
                        <td colspan="<%= user.esAdministrador() ? "6" : "5" %>" class="no-result">
                            No hay productos en el inventario.
                        </td>
                    </tr>
                    <%
                        }
                    %>
                </tbody>
            </table>
        </div>
    </body>
</html>