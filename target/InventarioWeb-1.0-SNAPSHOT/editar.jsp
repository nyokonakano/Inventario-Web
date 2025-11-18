<%@page import="modelo.Producto"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Editar Producto</title>
        <style>
            body {
                font-family: 'Segoe UI', sans-serif;
                background-color: #f0f0f0;
                margin: 0;
                padding: 40px;
            }

            .editar-container {
                max-width: 500px;
                margin: auto;
                background-color: white;
                padding: 30px;
                border-radius: 12px;
                box-shadow: 0 0 15px rgba(0,0,0,0.1);
            }

            h1 {
                text-align: center;
                color: #333;
                margin-bottom: 25px;
            }

            label {
                display: block;
                margin-top: 15px;
                font-weight: bold;
                color: #555;
            }

            input[type="text"],
            input[type="number"] {
                width: 100%;
                padding: 10px;
                margin-top: 5px;
                border-radius: 6px;
                border: 1px solid #ccc;
                box-sizing: border-box;
            }

            button {
                margin-top: 20px;
                padding: 12px;
                width: 100%;
                background-color: #4CAF50;
                color: white;
                font-weight: bold;
                border: none;
                border-radius: 6px;
                cursor: pointer;
                font-size: 16px;
                transition: background-color 0.3s ease;
            }

            button:hover {
                background-color: #388e3c;
            }

            .cancelar {
                display: block;
                text-align: center;
                margin-top: 15px;
                text-decoration: none;
                color: #555;
                font-weight: bold;
            }

            .cancelar:hover {
                text-decoration: underline;
            }

            .not-found {
                text-align: center;
                color: red;
                font-weight: bold;
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
