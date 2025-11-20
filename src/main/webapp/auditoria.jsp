<%@page import="modelo.Usuario"%>
<%@page import="modelo.ConexionMySQL"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    Usuario user = (Usuario) session.getAttribute("usuario");
    if (user == null || !user.esAdministrador()) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    // Clase auxiliar para auditoría
    class Auditoria {
        int id;
        String usuario;
        String accion;
        String tabla;
        String registroId;
        String detalles;
        Timestamp fecha;
    }
    
    List<Auditoria> logs = new ArrayList<>();
    String filtro = request.getParameter("filtro");
    
    try (Connection conn = ConexionMySQL.conectar()) {
        String sql = "SELECT a.id, u.usuario, a.accion, a.tabla, a.registro_id, a.detalles, a.fecha " +
                     "FROM auditoria a " +
                     "INNER JOIN usuarios u ON a.usuario_id = u.id ";
        
        if (filtro != null && !filtro.trim().isEmpty()) {
            sql += "WHERE a.accion LIKE ? OR a.tabla LIKE ? OR u.usuario LIKE ? ";
        }
        
        sql += "ORDER BY a.fecha DESC LIMIT 100";
        
        PreparedStatement stmt = conn.prepareStatement(sql);
        
        if (filtro != null && !filtro.trim().isEmpty()) {
            String termino = "%" + filtro + "%";
            stmt.setString(1, termino);
            stmt.setString(2, termino);
            stmt.setString(3, termino);
        }
        
        ResultSet rs = stmt.executeQuery();
        
        while (rs.next()) {
            Auditoria log = new Auditoria();
            log.id = rs.getInt("id");
            log.usuario = rs.getString("usuario");
            log.accion = rs.getString("accion");
            log.tabla = rs.getString("tabla");
            log.registroId = rs.getString("registro_id");
            log.detalles = rs.getString("detalles");
            log.fecha = rs.getTimestamp("fecha");
            logs.add(log);
        }
        
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Auditoría del Sistema</title>
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
            --info: #3b82f6;
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

        .btn-secondary {
            background: var(--surface);
            color: var(--text);
            border: 1px solid var(--border);
        }

        .btn-secondary:hover {
            background: var(--bg);
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
        }

        .filters {
            background: var(--surface);
            padding: 24px;
            border-radius: 16px;
            border: 1px solid var(--border);
            margin-bottom: 24px;
            display: flex;
            gap: 12px;
            align-items: center;
        }

        .filters input {
            flex: 1;
            padding: 12px 16px;
            border: 1px solid var(--border);
            border-radius: 10px;
            font-size: 14px;
        }

        .filters input:focus {
            outline: none;
            border-color: var(--primary);
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 24px;
        }

        .stat-card {
            background: var(--surface);
            padding: 24px;
            border-radius: 16px;
            border: 1px solid var(--border);
            text-align: center;
        }

        .stat-number {
            font-size: 32px;
            font-weight: 700;
            color: var(--primary);
            margin-bottom: 4px;
        }

        .stat-label {
            color: var(--text-secondary);
            font-size: 13px;
            font-weight: 500;
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

        .badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
        }

        .badge-crear {
            background: #d1fae5;
            color: #065f46;
        }

        .badge-editar {
            background: #fef3c7;
            color: #92400e;
        }

        .badge-eliminar {
            background: #fee2e2;
            color: #991b1b;
        }

        .badge-login {
            background: #dbeafe;
            color: #1e40af;
        }

        .badge-logout {
            background: #e0e7ff;
            color: #3730a3;
        }

        .no-data {
            text-align: center;
            padding: 48px;
            color: var(--text-secondary);
        }

        .detalles {
            font-size: 13px;
            color: var(--text-secondary);
            max-width: 300px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .fecha {
            color: var(--text-secondary);
            font-size: 13px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 Auditoría del Sistema</h1>
            <div>
                <a href="configuracion.jsp" class="btn btn-secondary" style="margin-right:10px;">⚙️ Configuración</a>
                <a href="admin.jsp" class="btn btn-secondary">← Volver al Panel</a>
            </div>
        </div>

        <!-- Estadísticas -->
        <div class="stats">
            <div class="stat-card">
                <div class="stat-number"><%= logs.size() %></div>
                <div class="stat-label">Registros Recientes</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">
                    <%
                        long hoy = logs.stream()
                            .filter(l -> l.fecha.toLocalDateTime().toLocalDate()
                                .equals(java.time.LocalDate.now()))
                            .count();
                    %>
                    <%= hoy %>
                </div>
                <div class="stat-label">Acciones Hoy</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">
                    <%
                        Set<String> usuarios = new HashSet<>();
                        for (Auditoria l : logs) {
                            usuarios.add(l.usuario);
                        }
                    %>
                    <%= usuarios.size() %>
                </div>
                <div class="stat-label">Usuarios Activos</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">100</div>
                <div class="stat-label">Límite Mostrado</div>
            </div>
        </div>

        <!-- Filtros -->
        <div class="filters">
            <form method="get" action="auditoria.jsp" style="display:flex; gap:15px; width:100%;">
                <input type="text" name="filtro" placeholder="Buscar por usuario, acción o tabla..." 
                       value="<%= filtro != null ? filtro : "" %>">
                <button type="submit">🔍 Filtrar</button>
                <% if (filtro != null && !filtro.isEmpty()) { %>
                    <a href="auditoria.jsp" class="btn btn-secondary" style="padding:12px 20px;">✖ Limpiar</a>
                <% } %>
            </form>
        </div>

        <!-- Tabla de Auditoría -->
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Usuario</th>
                    <th>Acción</th>
                    <th>Tabla</th>
                    <th>Registro ID</th>
                    <th>Detalles</th>
                    <th>Fecha y Hora</th>
                </tr>
            </thead>
            <tbody>
                <%
                    if (!logs.isEmpty()) {
                        for (Auditoria log : logs) {
                            String badgeClass = "badge-crear";
                            if (log.accion.toLowerCase().contains("editar") || log.accion.toLowerCase().contains("actualizar")) {
                                badgeClass = "badge-editar";
                            } else if (log.accion.toLowerCase().contains("eliminar")) {
                                badgeClass = "badge-eliminar";
                            } else if (log.accion.toLowerCase().contains("login")) {
                                badgeClass = "badge-login";
                            } else if (log.accion.toLowerCase().contains("logout")) {
                                badgeClass = "badge-logout";
                            }
                %>
                <tr>
                    <td><strong>#<%= log.id %></strong></td>
                    <td><%= log.usuario %></td>
                    <td><span class="badge <%= badgeClass %>"><%= log.accion %></span></td>
                    <td><%= log.tabla != null ? log.tabla : "-" %></td>
                    <td><%= log.registroId != null ? log.registroId : "-" %></td>
                    <td>
                        <div class="detalles" title="<%= log.detalles != null ? log.detalles : "" %>">
                            <%= log.detalles != null ? log.detalles : "-" %>
                        </div>
                    </td>
                    <td class="fecha">
                        <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(log.fecha) %>
                    </td>
                </tr>
                <%
                        }
                    } else {
                %>
                <tr>
                    <td colspan="7" class="no-data">
                        <% if (filtro != null && !filtro.isEmpty()) { %>
                            No se encontraron resultados para "<%= filtro %>"
                        <% } else { %>
                            No hay registros de auditoría disponibles
                        <% } %>
                    </td>
                </tr>
                <%
                    }
                %>
            </tbody>
        </table>

        <div style="background:white; padding:15px; border-radius:10px; margin-top:20px; text-align:center; box-shadow: 0 10px 30px rgba(0,0,0,0.1);">
            <p style="color:#6b7280; font-size:14px;">
                ℹ️ Mostrando los últimos 100 registros. Para ver más, use los filtros o contacte al administrador.
            </p>
        </div>
    </div>
</body>
</html>