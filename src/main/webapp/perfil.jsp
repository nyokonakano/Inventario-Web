<%@page import="modelo.Usuario"%>
<%@page import="java.sql.*"%>
<%@page import="modelo.ConexionMySQL"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    Usuario user = (Usuario) session.getAttribute("usuario");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    // Obtener información completa del usuario
    String email = "";
    Timestamp fechaCreacion = null;
    Timestamp ultimoAcceso = null;
    boolean activo = true;
    
    try (Connection conn = ConexionMySQL.conectar()) {
        String sql = "SELECT email, fecha_creacion, ultimo_acceso, activo FROM usuarios WHERE id = ?";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setInt(1, user.getId());
        ResultSet rs = stmt.executeQuery();
        
        if (rs.next()) {
            email = rs.getString("email");
            fechaCreacion = rs.getTimestamp("fecha_creacion");
            ultimoAcceso = rs.getTimestamp("ultimo_acceso");
            activo = rs.getBoolean("activo");
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Mi Perfil</title>
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
            min-height: 100vh;
            padding: 24px;
        }

        .container {
            max-width: 800px;
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

        .profile-card {
            background: var(--surface);
            padding: 48px;
            border-radius: 16px;
            border: 1px solid var(--border);
            margin-bottom: 24px;
        }

        .profile-avatar {
            width: 120px;
            height: 120px;
            background: linear-gradient(135deg, var(--primary) 0%, #8b5cf6 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 48px;
            color: white;
            margin: 0 auto 24px;
            font-weight: 600;
        }

        .profile-info {
            text-align: center;
            margin-bottom: 32px;
        }

        .profile-name {
            font-size: 28px;
            color: var(--text);
            margin-bottom: 8px;
            font-weight: 600;
        }

        .profile-role {
            display: inline-block;
            padding: 6px 16px;
            background: var(--warning);
            color: white;
            border-radius: 16px;
            font-size: 13px;
            font-weight: 500;
        }

        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-top: 32px;
        }

        .info-item {
            background: var(--bg);
            padding: 20px;
            border-radius: 12px;
            border: 1px solid var(--border);
        }

        .info-label {
            color: var(--text-secondary);
            font-size: 13px;
            margin-bottom: 6px;
            font-weight: 500;
        }

        .info-value {
            color: var(--text);
            font-size: 15px;
            font-weight: 600;
        }

        .stats-card {
            background: var(--surface);
            padding: 32px;
            border-radius: 16px;
            border: 1px solid var(--border);
        }

        .stats-card h2 {
            color: var(--text);
            margin-bottom: 24px;
            font-size: 20px;
            font-weight: 600;
        }

        .stat-row {
            display: flex;
            justify-content: space-between;
            padding: 16px 0;
            border-bottom: 1px solid var(--border);
        }

        .stat-row:last-child {
            border-bottom: none;
        }

        .stat-label {
            color: var(--text-secondary);
            font-size: 14px;
            font-weight: 500;
        }

        .stat-value {
            color: var(--text);
            font-weight: 600;
            font-size: 14px;
            text-align: right;
            max-width: 60%;
        }

        @media (max-width: 640px) {
            .info-grid {
                grid-template-columns: 1fr;
            }

            .stat-row {
                flex-direction: column;
                gap: 8px;
            }

            .stat-value {
                max-width: 100%;
                text-align: left;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>👤 Mi Perfil</h1>
            <a href="<%= user.esAdministrador() ? "admin.jsp" : "index.jsp" %>" class="btn btn-secondary">← Volver</a>
        </div>

        <!-- Tarjeta de Perfil -->
        <div class="profile-card">
            <div class="profile-avatar">
                <%= user.getNombreCompleto().substring(0, 1).toUpperCase() %>
            </div>

            <div class="profile-info">
                <div class="profile-name"><%= user.getNombreCompleto() %></div>
                <span class="profile-role"><%= user.getRolNombre() %></span>
            </div>

            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Usuario</div>
                    <div class="info-value"><%= user.getUsuario() %></div>
                </div>

                <div class="info-item">
                    <div class="info-label">Email</div>
                    <div class="info-value"><%= email != null ? email : "No registrado" %></div>
                </div>

                <div class="info-item">
                    <div class="info-label">Estado</div>
                    <div class="info-value" style="color: <%= activo ? "#10b981" : "#ef4444" %>">
                        <%= activo ? "✅ Activo" : "❌ Inactivo" %>
                    </div>
                </div>

                <div class="info-item">
                    <div class="info-label">ID de Usuario</div>
                    <div class="info-value">#<%= user.getId() %></div>
                </div>

                <div class="info-item">
                    <div class="info-label">Fecha de Registro</div>
                    <div class="info-value">
                        <%= fechaCreacion != null ? 
                            new java.text.SimpleDateFormat("dd/MM/yyyy").format(fechaCreacion) : 
                            "Desconocida" %>
                    </div>
                </div>

                <div class="info-item">
                    <div class="info-label">Último Acceso</div>
                    <div class="info-value">
                        <%= ultimoAcceso != null ? 
                            new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(ultimoAcceso) : 
                            "Nunca" %>
                    </div>
                </div>
            </div>
        </div>

        <!-- Estadísticas de Actividad -->
        <div class="stats-card">
            <h2>📊 Mi Actividad</h2>
            
            <%
                int accionesRealizadas = 0;
                String ultimaAccion = "Ninguna";
                
                try (Connection conn = ConexionMySQL.conectar()) {
                    // Contar acciones del usuario
                    String sql1 = "SELECT COUNT(*) FROM auditoria WHERE usuario_id = ?";
                    PreparedStatement stmt1 = conn.prepareStatement(sql1);
                    stmt1.setInt(1, user.getId());
                    ResultSet rs1 = stmt1.executeQuery();
                    if (rs1.next()) {
                        accionesRealizadas = rs1.getInt(1);
                    }
                    
                    // Última acción
                    String sql2 = "SELECT accion, fecha FROM auditoria WHERE usuario_id = ? ORDER BY fecha DESC LIMIT 1";
                    PreparedStatement stmt2 = conn.prepareStatement(sql2);
                    stmt2.setInt(1, user.getId());
                    ResultSet rs2 = stmt2.executeQuery();
                    if (rs2.next()) {
                        ultimaAccion = rs2.getString("accion") + " - " + 
                                      new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(rs2.getTimestamp("fecha"));
                    }
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            %>
            
            <div class="stat-row">
                <span class="stat-label">Total de acciones realizadas</span>
                <span class="stat-value"><%= accionesRealizadas %></span>
            </div>

            <div class="stat-row">
                <span class="stat-label">Última acción</span>
                <span class="stat-value"><%= ultimaAccion %></span>
            </div>

            <div class="stat-row">
                <span class="stat-label">Permisos</span>
                <span class="stat-value">
                    <%= user.puedeVerInventario() ? "✅ Ver inventario " : "" %>
                    <%= user.puedeAgregar() ? "✅ Agregar productos " : "" %>
                    <%= user.puedeEditar() ? "✅ Editar productos " : "" %>
                    <%= user.puedeEliminar() ? "✅ Eliminar productos " : "" %>
                    <%= user.puedeGestionarUsuarios() ? "✅ Gestionar usuarios" : "" %>
                </span>
            </div>
        </div>
    </div>
</body>
</html>