<%@page import="modelo.Usuario"%>
<%@page import="java.sql.*"%>
<%@page import="modelo.ConexionMySQL"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    Usuario user = (Usuario) session.getAttribute("usuario");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    class DetallePedido {
        String producto;
        int cantidad;
        double precioUnitario;
        double subtotal;
    }
    
    // Clase auxiliar para pedidos
    class Pedido {
        int id;
        double total;
        String estado;
        Timestamp fecha;
        String direccion;
        List<DetallePedido> detalles = new ArrayList<>();
    }
    
    // Obtener pedidos del usuario
    List<Pedido> pedidos = new ArrayList<>();
    
    try (Connection conn = ConexionMySQL.conectar()) {
        String sql = "SELECT id, total, estado, fecha_pedido, direccion_envio " +
                     "FROM pedidos WHERE usuario_id = ? ORDER BY fecha_pedido DESC";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setInt(1, user.getId());
        ResultSet rs = stmt.executeQuery();
        
        while (rs.next()) {
            Pedido p = new Pedido();
            p.id = rs.getInt("id");
            p.total = rs.getDouble("total");
            p.estado = rs.getString("estado");
            p.fecha = rs.getTimestamp("fecha_pedido");
            p.direccion = rs.getString("direccion_envio");
            
            // Obtener detalles
            String sqlDet = "SELECT producto_nombre, cantidad, precio_unitario, subtotal " +
                            "FROM pedido_detalles WHERE pedido_id = ?";
            PreparedStatement stmtDet = conn.prepareStatement(sqlDet);
            stmtDet.setInt(1, p.id);
            ResultSet rsDet = stmtDet.executeQuery();
            
            while (rsDet.next()) {
                DetallePedido d = new DetallePedido();
                d.producto = rsDet.getString("producto_nombre");
                d.cantidad = rsDet.getInt("cantidad");
                d.precioUnitario = rsDet.getDouble("precio_unitario");
                d.subtotal = rsDet.getDouble("subtotal");
                p.detalles.add(d);
            }
            
            pedidos.add(p);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Mis Pedidos</title>
    <style>
        :root {
            --primary: #2563eb;
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
        }

        .container {
            max-width: 1200px;
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
            font-size: 24px;
            font-weight: 600;
        }

        .btn-back {
            background: var(--surface);
            color: var(--text);
            border: 1px solid var(--border);
            padding: 10px 20px;
            border-radius: 10px;
            text-decoration: none;
            font-weight: 500;
            font-size: 14px;
        }

        .pedido-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 24px;
            margin-bottom: 20px;
        }

        .pedido-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 16px;
            border-bottom: 1px solid var(--border);
        }

        .pedido-id {
            font-size: 18px;
            font-weight: 600;
        }

        .pedido-fecha {
            font-size: 14px;
            color: var(--text-secondary);
        }

        .estado-badge {
            padding: 6px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
        }

        .estado-PENDIENTE {
            background: #fef3c7;
            color: #92400e;
        }

        .estado-PROCESANDO {
            background: #dbeafe;
            color: #1e40af;
        }

        .estado-COMPLETADO {
            background: #d1fae5;
            color: #065f46;
        }

        .estado-CANCELADO {
            background: #fee2e2;
            color: #991b1b;
        }

        .pedido-items {
            margin: 20px 0;
        }

        .item {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid var(--border);
        }

        .item:last-child {
            border-bottom: none;
        }

        .item-info {
            font-size: 14px;
        }

        .item-precio {
            font-weight: 600;
            color: var(--primary);
        }

        .pedido-total {
            display: flex;
            justify-content: space-between;
            margin-top: 20px;
            padding-top: 16px;
            border-top: 2px solid var(--border);
            font-size: 20px;
            font-weight: 700;
            color: var(--primary);
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            background: var(--surface);
            border-radius: 16px;
            border: 1px solid var(--border);
        }

        .empty-icon {
            font-size: 64px;
            margin-bottom: 16px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📦 Mis Pedidos</h1>
            <a href="shop.jsp" class="btn-back">← Volver a la Tienda</a>
        </div>

        <% if (pedidos.isEmpty()) { %>
        <div class="empty-state">
            <div class="empty-icon">📦</div>
            <h2>No tienes pedidos aún</h2>
            <p style="color: var(--text-secondary); margin-top: 8px;">
                Comienza a comprar en nuestra tienda
            </p>
            <a href="shop.jsp" style="display: inline-block; margin-top: 20px; padding: 12px 24px; background: var(--primary); color: white; text-decoration: none; border-radius: 10px; font-weight: 500;">
                Ir a la Tienda
            </a>
        </div>
        <% } else { %>
            <% for (Pedido p : pedidos) { %>
            <div class="pedido-card">
                <div class="pedido-header">
                    <div>
                        <div class="pedido-id">Pedido #<%= p.id %></div>
                        <div class="pedido-fecha">
                            <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(p.fecha) %>
                        </div>
                    </div>
                    <span class="estado-badge estado-<%= p.estado %>">
                        <%= p.estado %>
                    </span>
                </div>

                <div class="pedido-items">
                    <% for (DetallePedido d : p.detalles) { %>
                    <div class="item">
                        <div class="item-info">
                            <strong><%= d.producto %></strong><br>
                            <span style="color: var(--text-secondary); font-size: 13px;">
                                Cantidad: <%= d.cantidad %> × $<%= String.format("%.2f", d.precioUnitario) %>
                            </span>
                        </div>
                        <div class="item-precio">
                            $<%= String.format("%.2f", d.subtotal) %>
                        </div>
                    </div>
                    <% } %>
                </div>

                <div class="pedido-total">
                    <span>Total:</span>
                    <span>$<%= String.format("%.2f", p.total) %></span>
                </div>

                <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--border); font-size: 13px; color: var(--text-secondary);">
                    📍 <%= p.direccion %>
                </div>
            </div>
            <% } %>
        <% } %>
    </div>
</body>
</html>