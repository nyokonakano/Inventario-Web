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
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }
        
        .container { max-width: 1400px; margin: 0 auto; }
        
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
        
        .header h1 { color: #667eea; }
        
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
        
        .btn-primary { background: #667eea; color: white; }
        .btn-primary:hover { background: #5568d3; transform: translateY(-2px); }
        
        .btn-success { background: #48bb78; color: white; }
        .btn-success:hover { background: #38a169; }
        
        .btn-danger { background: #f56565; color: white; padding: 8px 12px; font-size: 13px; }
        .btn-danger:hover { background: #e53e3e; }
        
        .btn-secondary { background: #718096; color: white; }
        .btn-secondary:hover { background: #4a5568; }
        
        .form-card {
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .form-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-bottom: 15px;
        }
        
        input, select {
            width: 100%;
            padding: 10px;
            border: 2px solid #e5e7eb;
            border-radius: 8px;
            font-size: 14px;
        }
        
        table {
            width: 100%;
            background: white;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            border-collapse: collapse;
        }
        
        th {
            background: #f3f4f6;
            padding: 15px;
            text-align: left;
            font-weight: bold;
        }
        
        td {
            padding: 15px;
            border-bottom: 1px solid #e5e7eb;
        }
        
        tr:hover { background: #f9fafb; }
        
        .badge {
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: bold;
            color: white;
        }
        
        .badge-admin { background: #10b981; }
        .badge-user { background: #f59e0b; }
        .badge-active { background: #10b981; }
        .badge-inactive { background: #ef4444; }
        
        .mensaje {
            background: #10b981;
            color: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
        }
        
        .error {
            background: #ef4444;
            color: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
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