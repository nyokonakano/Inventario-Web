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
            max-width: 1600px;
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

        .filters {
            background: white;
            padding: 20px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            display: flex;
            gap: 15px;
            align-items: center;
        }

        .filters input {
            flex: 1;
            padding: 12px;
            border: 2px solid #e5e7eb;
            border-radius: 8px;
            font-size: 14px;
        }

        .filters button {
            background: #667eea;
            color: white;
            padding: 12px 25px;
            border: none;
            border-radius: 8px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
        }

        .filters button:hover {
            background: #5568d3;
            transform: translateY(-2px);
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            text-align: center;
        }

        .stat-number {
            font-size: 32px;
            font-weight: bold;
            color: #667eea;
        }

        .stat-label {
            color: #6b7280;
            font-size: 14px;
            margin-top: 5px;
        }

        table {
            width: 100%;
            background: white;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            border-collapse: collapse;
        }

        thead {
            background: #f3f4f6;
        }

        th {
            padding: 15px;
            text-align: left;
            font-weight: bold;
            color: #374151;
            font-size: 14px;
            text-transform: uppercase;
        }

        td {
            padding: 15px;
            border-bottom: 1px solid #e5e7eb;
            font-size: 14px;
        }

        tr:hover {
            background: #f9fafb;
        }

        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: bold;
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
            padding: 40px;
            color: #6b7280;
        }

        .detalles {
            font-size: 12px;
            color: #6b7280;
            max-width: 300px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .fecha {
            color: #6b7280;
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