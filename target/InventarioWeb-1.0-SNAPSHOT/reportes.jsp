<%@page import="modelo.Usuario"%>
<%@page import="java.sql.*"%>
<%@page import="modelo.ConexionMySQL"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    Usuario user = (Usuario) session.getAttribute("usuario");
    if (user == null || !user.esAdministrador()) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    // Obtener estadísticas generales
    int totalProductos = 0;
    int totalUnidades = 0;
    double valorTotal = 0;
    int productosConStockBajo = 0;
    int productosAgotados = 0;
    
    try (Connection conn = ConexionMySQL.conectar()) {
        // Total productos
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM productos");
        if (rs.next()) totalProductos = rs.getInt(1);
        
        // Total unidades
        rs = stmt.executeQuery("SELECT SUM(cantidad) FROM productos");
        if (rs.next()) totalUnidades = rs.getInt(1);
        
        // Valor total del inventario
        rs = stmt.executeQuery("SELECT SUM(cantidad * precio) FROM productos");
        if (rs.next()) valorTotal = rs.getDouble(1);
        
        // Stock bajo (< 10)
        rs = stmt.executeQuery("SELECT COUNT(*) FROM productos WHERE cantidad < 10 AND cantidad > 0");
        if (rs.next()) productosConStockBajo = rs.getInt(1);
        
        // Productos agotados
        rs = stmt.executeQuery("SELECT COUNT(*) FROM productos WHERE cantidad = 0");
        if (rs.next()) productosAgotados = rs.getInt(1);
        
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Reportes del Inventario</title>
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
            max-width: 1400px;
            margin: 0 auto;
        }

        .header {
            background: var(--surface);
            padding: 24px 32px;
            border-radius: 16px;
            margin-bottom: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border: 1px solid var(--border);
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

        .btn-success {
            background: var(--success);
            color: white;
        }

        .btn-success:hover {
            background: #059669;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 32px;
        }

        .stat-card {
            background: var(--surface);
            padding: 28px;
            border-radius: 16px;
            border: 1px solid var(--border);
            text-align: center;
            transition: all 0.2s;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            border-color: var(--primary);
        }

        .stat-icon {
            font-size: 36px;
            margin-bottom: 12px;
        }

        .stat-number {
            font-size: 32px;
            font-weight: 700;
            color: var(--primary);
            margin: 8px 0;
        }

        .stat-label {
            color: var(--text-secondary);
            font-size: 13px;
            font-weight: 500;
        }

        .reports-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 24px;
            margin-bottom: 24px;
        }

        .report-card {
            background: var(--surface);
            padding: 32px;
            border-radius: 16px;
            border: 1px solid var(--border);
            transition: all 0.2s;
        }

        .report-card:hover {
            border-color: var(--primary);
        }

        .report-card h2 {
            color: var(--text);
            margin-bottom: 12px;
            font-size: 18px;
            font-weight: 600;
        }

        .report-card p {
            color: var(--text-secondary);
            margin-bottom: 20px;
            line-height: 1.6;
            font-size: 14px;
        }

        .report-actions {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }

        table {
            width: 100%;
            background: var(--surface);
            border-radius: 16px;
            overflow: hidden;
            border: 1px solid var(--border);
            border-collapse: separate;
            border-spacing: 0;
            margin-top: 24px;
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

        .badge-success {
            background: #d1fae5;
            color: #065f46;
        }

        .badge-warning {
            background: #fef3c7;
            color: #92400e;
        }

        .badge-danger {
            background: #fee2e2;
            color: #991b1b;
        }

        .loading {
            display: none;
            text-align: center;
            padding: 48px;
            background: var(--surface);
            border-radius: 16px;
            border: 1px solid var(--border);
            margin-top: 24px;
        }

        .spinner {
            border: 4px solid var(--border);
            border-top: 4px solid var(--primary);
            border-radius: 50%;
            width: 48px;
            height: 48px;
            animation: spin 1s linear infinite;
            margin: 0 auto 16px;
        }

        @keyframes spin {
            0% {
                transform: rotate(0deg);
            }
            100% {
                transform: rotate(360deg);
            }
        }

        #reporte-resultado {
            background: var(--surface);
            padding: 32px;
            border-radius: 16px;
            border: 1px solid var(--border);
            margin-top: 24px;
            display: none;
        }

        #reporte-resultado h2 {
            color: var(--text);
            margin-bottom: 20px;
            font-size: 20px;
            font-weight: 600;
        }

        #reporte-resultado pre {
            background: var(--bg);
            padding: 24px;
            border-radius: 12px;
            overflow-x: auto;
            white-space: pre-wrap;
            line-height: 1.6;
            font-size: 13px;
            border: 1px solid var(--border);
        }

        .export-options {
            display: flex;
            gap: 12px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Reportes e Informes</h1>
            <a href="admin.jsp" class="btn btn-secondary">← Volver al Panel</a>
        </div>

        <!-- Estadísticas Principales -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon">📦</div>
                <div class="stat-number"><%= totalProductos %></div>
                <div class="stat-label">Total Productos</div>
            </div>

            <div class="stat-card">
                <div class="stat-icon">📈</div>
                <div class="stat-number"><%= totalUnidades %></div>
                <div class="stat-label">Total Unidades</div>
            </div>

            <div class="stat-card">
                <div class="stat-icon">💰</div>
                <div class="stat-number">$<%= String.format("%.2f", valorTotal) %></div>
                <div class="stat-label">Valor Total Inventario</div>
            </div>

            <div class="stat-card">
                <div class="stat-icon">⚠️</div>
                <div class="stat-number"><%= productosConStockBajo %></div>
                <div class="stat-label">Stock Bajo</div>
            </div>

            <div class="stat-card">
                <div class="stat-icon">🔴</div>
                <div class="stat-number"><%= productosAgotados %></div>
                <div class="stat-label">Productos Agotados</div>
            </div>
        </div>

        <!-- Reportes Disponibles -->
        <div class="reports-grid">
            <!-- Reporte General -->
            <div class="report-card">
                <h2>📋 Reporte General Completo</h2>
                <p>Genera un informe detallado con todos los productos, estadísticas por categoría y análisis de stock.</p>
                <div class="report-actions">
                    <button class="btn btn-primary" onclick="generarReporteAsync('completo')">
                        🔄 Generar Reporte
                    </button>
                    <button class="btn btn-success" onclick="exportarPDF('completo')">
                        📄 Exportar PDF
                    </button>
                </div>
            </div>

            <!-- Stock Bajo -->
            <div class="report-card">
                <h2>⚠️ Productos con Stock Bajo</h2>
                <p>Lista de productos que necesitan reabastecimiento urgente (menos de 10 unidades).</p>
                <div class="report-actions">
                    <button class="btn btn-primary" onclick="generarReporteAsync('stock-bajo')">
                        🔄 Ver Reporte
                    </button>
                    <a href="ReportesServlet?tipo=stock-bajo&formato=excel" class="btn btn-success">
                        📊 Exportar Excel
                    </a>
                </div>
            </div>

            <!-- Por Categoría -->
            <div class="report-card">
                <h2>📂 Análisis por Categoría</h2>
                <p>Estadísticas agrupadas por categoría: cantidad de productos, valor total y stock promedio.</p>
                <div class="report-actions">
                    <button class="btn btn-primary" onclick="generarReporteAsync('categorias')">
                        🔄 Generar
                    </button>
                    <button class="btn btn-success" onclick="exportarGrafico()">
                        📊 Ver Gráfico
                    </button>
                </div>
            </div>

            <!-- Productos Más Valiosos -->
            <div class="report-card">
                <h2>💎 Productos Más Valiosos</h2>
                <p>Top 10 productos con mayor valor total en inventario (precio × cantidad).</p>
                <div class="report-actions">
                    <button class="btn btn-primary" onclick="generarReporteAsync('valiosos')">
                        🔄 Ver Top 10
                    </button>
                </div>
            </div>

            <!-- Auditoría de Cambios -->
            <div class="report-card">
                <h2>📝 Reporte de Auditoría</h2>
                <p>Historial de cambios realizados en el inventario en los últimos 7 días.</p>
                <div class="report-actions">
                    <a href="auditoria.jsp" class="btn btn-primary">
                        🔍 Ver Auditoría
                    </a>
                    <button class="btn btn-success" onclick="generarReporteAsync('auditoria')">
                        📄 Generar Informe
                    </button>
                </div>
            </div>

            <!-- Proyecciones -->
            <div class="report-card">
                <h2>🔮 Proyecciones de Stock</h2>
                <p>Análisis predictivo basado en el consumo histórico (requiere procesamiento intensivo).</p>
                <div class="report-actions">
                    <button class="btn btn-primary" onclick="generarReporteAsync('proyecciones')">
                        ⚡ Generar (Async)
                    </button>
                </div>
            </div>
        </div>

        <!-- Loading Indicator -->
        <div id="loading" class="loading">
            <div class="spinner"></div>
            <p>Generando reporte en segundo plano...</p>
            <small>Este proceso puede tardar varios segundos</small>
        </div>

        <!-- Resultado del Reporte -->
        <div id="reporte-resultado">
            <h2>📊 Resultado del Reporte</h2>
            <div class="export-options">
                <button class="btn btn-success" onclick="descargarReporte()">💾 Descargar</button>
                <button class="btn btn-secondary" onclick="cerrarReporte()">✖ Cerrar</button>
            </div>
            <pre id="reporte-contenido"></pre>
        </div>

        <!-- Tabla de Stock Bajo (ejemplo) -->
        <%
            String verStockBajo = request.getParameter("ver");
            if ("stock-bajo".equals(verStockBajo)) {
        %>
        <div style="background:white; padding:30px; border-radius:15px; box-shadow: 0 10px 30px rgba(0,0,0,0.1);">
            <h2 style="color:#1f2937; margin-bottom:20px;">⚠️ Productos con Stock Bajo</h2>
            <table>
                <thead>
                    <tr>
                        <th>Producto</th>
                        <th>Cantidad</th>
                        <th>Precio</th>
                        <th>Categoría</th>
                        <th>Estado</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try (Connection conn = ConexionMySQL.conectar()) {
                            String sql = "SELECT * FROM productos WHERE cantidad < 10 ORDER BY cantidad";
                            PreparedStatement stmt = conn.prepareStatement(sql);
                            ResultSet rs = stmt.executeQuery();
                            
                            while (rs.next()) {
                                int cantidad = rs.getInt("cantidad");
                                String badge = cantidad == 0 ? "badge-danger" : 
                                               cantidad < 5 ? "badge-danger" : "badge-warning";
                                String estado = cantidad == 0 ? "AGOTADO" : 
                                               cantidad < 5 ? "CRÍTICO" : "BAJO";
                    %>
                    <tr>
                        <td><strong><%= rs.getString("nombre") %></strong></td>
                        <td><%= cantidad %></td>
                        <td>$<%= String.format("%.2f", rs.getDouble("precio")) %></td>
                        <td><%= rs.getString("categoria") %></td>
                        <td><span class="badge <%= badge %>"><%= estado %></span></td>
                    </tr>
                    <%
                            }
                        } catch (SQLException e) {
                            e.printStackTrace();
                        }
                    %>
                </tbody>
            </table>
        </div>
        <% } %>
    </div>

    <script>
        // 🔄 Generar reporte de forma asíncrona usando AJAX
        function generarReporteAsync(tipo) {
            console.log("Generando reporte:", tipo);
            
            // Mostrar loading
            document.getElementById("loading").style.display = "block";
            document.getElementById("reporte-resultado").style.display = "none";
            
            // Llamar al servlet que usa AsyncTaskManager
            fetch('ReportesServlet?tipo=' + tipo + '&async=true')
                .then(response => response.text())
                .then(data => {
                    console.log("Reporte recibido");
                    
                    // Ocultar loading
                    document.getElementById("loading").style.display = "none";
                    
                    // Mostrar resultado
                    document.getElementById("reporte-contenido").textContent = data;
                    document.getElementById("reporte-resultado").style.display = "block";
                    
                    // Scroll al resultado
                    document.getElementById("reporte-resultado").scrollIntoView({ 
                        behavior: 'smooth' 
                    });
                })
                .catch(error => {
                    console.error("Error:", error);
                    document.getElementById("loading").style.display = "none";
                    alert("Error al generar el reporte: " + error);
                });
        }

        function cerrarReporte() {
            document.getElementById("reporte-resultado").style.display = "none";
        }

        function descargarReporte() {
            const contenido = document.getElementById("reporte-contenido").textContent;
            const blob = new Blob([contenido], { type: 'text/plain' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'reporte-inventario-' + new Date().getTime() + '.txt';
            a.click();
            window.URL.revokeObjectURL(url);
        }

        function exportarPDF(tipo) {
            window.location.href = 'ReportesServlet?tipo=' + tipo + '&formato=pdf';
        }

        function exportarGrafico() {
            alert("Funcionalidad de gráficos en desarrollo. Próximamente disponible.");
            // Aquí podrías integrar Chart.js o similar
        }
    </script>
</body>
</html>