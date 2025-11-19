<%@page import="java.util.List"%>
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
    <title>Gestión de Usuarios</title>
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

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
        }

        .btn-success {
            background: var(--success);
            color: white;
        }

        .btn-success:hover {
            background: #059669;
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

        .btn-secondary {
            background: var(--surface);
            color: var(--text);
            border: 1px solid var(--border);
        }

        .btn-secondary:hover {
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
            margin-bottom: 24px;
            font-size: 20px;
            font-weight: 600;
            color: var(--text);
        }

        .form-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 16px;
            margin-bottom: 20px;
        }

        input,
        select {
            width: 100%;
            padding: 12px 16px;
            border: 1px solid var(--border);
            border-radius: 10px;
            font-size: 14px;
            background: var(--surface);
            transition: all 0.2s;
        }

        input:focus,
        select:focus {
            outline: none;
            border-color: var(--primary);
        }

        table {
            width: 100%;
            background: var(--surface);
            border-radius: 16px;
            overflow: hidden;
            border: 1px solid var(--border);
            border-collapse: separate;
            border-spacing: 0;
        }

        thead {
            background: var(--bg);
        }

        th {
            padding: 16px 20px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: var(--text);
        }

        td {
            padding: 16px 20px;
            border-top: 1px solid var(--border);
            font-size: 14px;
        }

        tr:hover td {
            background: var(--bg);
        }

        .badge {
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
        }

        .badge-admin {
            background: #d1fae5;
            color: #065f46;
        }

        .badge-user {
            background: #fef3c7;
            color: #92400e;
        }

        .badge-active {
            background: #d1fae5;
            color: #065f46;
        }

        .badge-inactive {
            background: #fee2e2;
            color: #991b1b;
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
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>👥 Gestión de Usuarios</h1>
            <a href="admin.jsp" class="btn btn-secondary">← Volver al Panel</a>
        </div>
        
        <!-- Mensajes -->
        <%
            String error = request.getParameter("error");
            String mensaje = request.getParameter("mensaje");
            
            if ("usuario_creado".equals(mensaje)) {
        %>
            <div class="mensaje">✅ Usuario creado exitosamente</div>
        <%
            } else if ("usuario_eliminado".equals(mensaje)) {
        %>
            <div class="mensaje">✅ Usuario eliminado</div>
        <%
            } else if ("estado_actualizado".equals(mensaje)) {
        %>
            <div class="mensaje">✅ Estado actualizado</div>
        <%
            } else if ("usuario_existe".equals(error)) {
        %>
            <div class="error">❌ El nombre de usuario ya existe</div>
        <%
            } else if ("datos_incompletos".equals(error)) {
        %>
            <div class="error">❌ Complete todos los campos</div>
        <%
            }
        %>
        
        <!-- Formulario para crear usuario -->
        <div class="form-card">
            <h2 style="margin-bottom: 20px;">➕ Crear Nuevo Usuario</h2>
            <form method="post" action="usuarios">
                <input type="hidden" name="accion" value="crear">
                <div class="form-grid">
                    <input type="text" name="usuario" placeholder="Nombre de usuario" required>
                    <input type="password" name="clave" placeholder="Contraseña" required>
                    <input type="text" name="nombre_completo" placeholder="Nombre completo" required>
                    <input type="email" name="email" placeholder="Email">
                    <select name="rol_id" required>
                        <option value="">Seleccionar rol</option>
                        <option value="1">Administrador</option>
                        <option value="2">Usuario</option>
                    </select>
                </div>
                <button type="submit" class="btn btn-success">Crear Usuario</button>
            </form>
        </div>
        
        <!-- Lista de usuarios -->
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Usuario</th>
                    <th>Nombre Completo</th>
                    <th>Email</th>
                    <th>Rol</th>
                    <th>Estado</th>
                    <th>Fecha Creación</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                <%
                    List<Usuario> lista = (List<Usuario>) request.getAttribute("listaUsuarios");
                    if (lista != null && !lista.isEmpty()) {
                        for (Usuario u : lista) {
                %>
                <tr>
                    <td><%= u.getId() %></td>
                    <td><strong><%= u.getUsuario() %></strong></td>
                    <td><%= u.getNombreCompleto() %></td>
                    <td><%= u.getEmail() != null ? u.getEmail() : "-" %></td>
                    <td>
                        <span class="badge <%= u.esAdministrador() ? "badge-admin" : "badge-user" %>">
                            <%= u.getRolNombre() %>
                        </span>
                    </td>
                    <td>
                        <span class="badge <%= u.isActivo() ? "badge-active" : "badge-inactive" %>">
                            <%= u.isActivo() ? "Activo" : "Inactivo" %>
                        </span>
                    </td>
                    <td><%= u.getFechaCreacion() %></td>
                    <td>
                        <!-- Cambiar estado -->
                        <form method="post" action="usuarios" style="display:inline;">
                            <input type="hidden" name="accion" value="cambiar_estado">
                            <input type="hidden" name="id" value="<%= u.getId() %>">
                            <input type="hidden" name="activo" value="<%= !u.isActivo() %>">
                            <button type="submit" class="btn <%= u.isActivo() ? "btn-secondary" : "btn-success" %>" 
                                    style="padding: 8px 12px; font-size: 13px;">
                                <%= u.isActivo() ? "🚫 Desactivar" : "✅ Activar" %>
                            </button>
                        </form>
                        
                        <!-- Eliminar (no permitir eliminar al usuario actual) -->
                        <% if (u.getId() != user.getId()) { %>
                        <form method="post" action="usuarios" style="display:inline;" 
                              onsubmit="return confirm('¿Eliminar usuario <%= u.getUsuario() %>?');">
                            <input type="hidden" name="accion" value="eliminar">
                            <input type="hidden" name="id" value="<%= u.getId() %>">
                            <button type="submit" class="btn btn-danger">🗑️ Eliminar</button>
                        </form>
                        <% } %>
                    </td>
                </tr>
                <%
                        }
                    } else {
                %>
                <tr>
                    <td colspan="8" style="text-align:center; color: #6b7280;">
                        No hay usuarios registrados
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