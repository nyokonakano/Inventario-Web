<%@page import="modelo.Producto"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Editar Producto</title>
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

            .editar-container {
                max-width: 600px;
                margin: 0 auto;
                background: var(--surface);
                padding: 40px;
                border-radius: 16px;
                border: 1px solid var(--border);
            }

            h1 {
                text-align: center;
                color: var(--text);
                margin-bottom: 32px;
                font-size: 24px;
                font-weight: 600;
            }

            label {
                display: block;
                margin-top: 20px;
                font-weight: 500;
                color: var(--text);
                margin-bottom: 8px;
                font-size: 14px;
            }

            input[type="text"],
            input[type="number"] {
                width: 100%;
                padding: 12px 16px;
                margin-bottom: 4px;
                border-radius: 10px;
                border: 1px solid var(--border);
                font-size: 15px;
                transition: all 0.2s;
                background: var(--surface);
            }

            input[type="text"]:focus,
            input[type="number"]:focus {
                outline: none;
                border-color: var(--primary);
                background: var(--bg);
            }

            button {
                margin-top: 24px;
                padding: 14px;
                width: 100%;
                background: var(--success);
                color: white;
                font-weight: 500;
                border: none;
                border-radius: 10px;
                cursor: pointer;
                font-size: 15px;
                transition: all 0.2s;
            }

            button:hover {
                background: #059669;
            }

            .cancelar {
                display: block;
                text-align: center;
                margin-top: 16px;
                text-decoration: none;
                color: var(--text-secondary);
                font-weight: 500;
                font-size: 14px;
                padding: 12px;
                border-radius: 10px;
                transition: all 0.2s;
            }

            .cancelar:hover {
                background: var(--bg);
                color: var(--text);
            }

            .not-found {
                text-align: center;
                color: var(--danger);
                font-weight: 500;
                padding: 40px;
                background: #fee2e2;
                border-radius: 10px;
                border: 1px solid #fca5a5;
            }
        </style>
    </head>
    <body>
        <h1>Editar Producto</h1>
        
        <%
            Producto p = (Producto) request.getAttribute("producto");
            if (p == null) {
        %>
        <p class="not-found">Producto no encontrado.</p>
        <%
        } else {
        %>

        <div class="editar-container">
            <h1>Editar Producto</h1>
            <form method="post" action="editar">
                <input type="hidden" name="nombre" value="<%= p.getNombre()%>">

                <label>Cantidad:</label>
                <input type="number" name="cantidad" value="<%= p.getCantidad()%>" required>

                <label>Precio:</label>
                <input type="number" step="0.01" name="precio" value="<%= p.getPrecio()%>" required>

                <label>Categoría:</label>
                <input type="text" name="categoria" value="<%= p.getCategoria()%>" required>

                <button type="submit">💾 Guardar Cambios</button>
            </form>

            <a class="cancelar" href="productos">Cancelar y volver</a>
        </div>

        <%
            }
        %>
    </body>
</html>
