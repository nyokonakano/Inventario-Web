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
            body {
                font-family: 'Segoe UI', sans-serif;
                background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
                padding: 20px;
                min-height: 100vh;
            }

            .container {
                max-width: 1400px;
                margin: 0 auto;
            }

            .header {
                background: white;
                padding: 20px 30px;
                border-radius: 15px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                margin-bottom: 20px;
            }

            .header h1 {
                color: #1f2937;
                margin-bottom: 10px;
            }

            .user-info {
                display: flex;
                justify-content: space-between;
                align-items: center;
                font-size: 14px;
                color: #6b7280;
            }

            .role-badge {
                background: <%= user.esAdministrador() ? "#10b981" : "#f59e0b" %>;
                color: white;
                padding: 4px 10px;
                border-radius: 12px;
                font-size: 12px;
                font-weight: bold;
            }

            .top-bar {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 20px;
                gap: 15px;
            }

            .search-form {
                display: flex;
                gap: 10px;
                flex: 1;
            }

            input[type="text"] {
                flex: 1;
                padding: 12px;
                font-size: 14px;
                border-radius: 8px;
                border: 2px solid #e5e7eb;
            }

            button {
                padding: 12px 20px;
                font-size: 14px;
                border-radius: 8px;
                border: none;
                font-weight: bold;
                cursor: pointer;
                transition: all 0.3s;
            }

            .btn-primary {
                background: #6366f1;
                color: white;
            }

            .btn-primary:hover {
                background: #4f46e5;
                transform: translateY(-2px);
            }

            .btn-secondary {
                background: white;
                color: #6366f1;
                border: 2px solid #6366f1;
            }

            .btn-secondary:hover {
                background: #6366f1;
                color: white;
            }

            .btn-danger {
                background: #ef4444;
                color: white;
                padding: 8px 12px;
                font-size: 13px;
            }

            .btn-danger:hover {
                background: #dc2626;
            }

            .btn-edit {
                background: #f59e0b;
                color: white;
                padding: 8px 12px;
                font-size: 13px;
                margin-right: 5px;
            }

            .btn-edit:hover {
                background: #d97706;
            }

            .btn-disabled {
                background: #d1d5db;
                color: #6b7280;
                cursor: not-allowed;
            }

            table {
                width: 100%;
                border-collapse: collapse;
                background: white;
                border-radius: 15px;
                overflow: hidden;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            }

            th {
                background: #f3f4f6;
                padding: 15px;
                text-align: left;
                font-weight: bold;
                color: #374151;
            }

            td {
                padding: 15px;
                border-bottom: 1px solid #e5e7eb;
            }

            tr:last-child td {
                border-bottom: none;
            }

            tr:hover {
                background: #f9fafb;
            }

            .no-result {
                text-align: center;
                padding: 40px;
                color: #6b7280;
            }

            .permissions-warning {
                background: #fef3c7;
                border-left: 4px solid #f59e0b;
                padding: 15px;
                border-radius: 8px;
                margin-bottom: 20px;
                color: #92400e;
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