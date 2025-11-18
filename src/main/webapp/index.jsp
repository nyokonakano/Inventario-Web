<%@page import="java.util.*, modelo.Producto"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String user = (String) session.getAttribute("usuario");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Inventario Web</title>
        <style>
            body {
                font-family: 'Segoe UI', sans-serif;
                background-color: #f4f4f4;
                padding: 40px;
                margin: 0;
            }

            h1 {
                color: #333;
                text-align: center;
                margin-bottom: 30px;
            }

            form {
                max-width: 500px;
                margin: 0 auto;
                background-color: white;
                padding: 30px;
                border-radius: 12px;
                box-shadow: 0 0 15px rgba(0, 0, 0, 0.1);
            }

            input[type="text"],
            input[type="number"],
            button {
                width: 100%;
                padding: 12px;
                margin-bottom: 15px;
                border: 1px solid #ccc;
                border-radius: 6px;
                box-sizing: border-box;
                font-size: 16px;
            }

            button {
                background-color: #4CAF50;
                color: white;
                border: none;
                cursor: pointer;
                transition: background-color 0.3s ease;
            }

            button:hover {
                background-color: #45a049;
            }

            .acciones {
                display: flex;
                justify-content: space-between;
                margin-top: 20px;
                max-width: 500px;
                margin-left: auto;
                margin-right: auto;
            }

            .mensaje {
                color: green;
                text-align: center;
                font-weight: bold;
                margin-top: 15px;
            }
        </style>
    </head>
    <body>

        <h1>Gestión de Inventario</h1>
        <form method="post" action="productos">
            <input type="text" name="nombre" placeholder="Nombre del producto" required>
            <input type="number" name="cantidad" placeholder="Cantidad" required>
            <input type="number" step="0.01" name="precio" placeholder="Precio" required>
            <input type="text" name="categoria" placeholder="Categoría" required>
            <button type="submit">Agregar Producto</button>
        </form>
        
        <%
            String error = request.getParameter("error");
            if ("datos_incompletos".equals(error)) {
        %>
        <p class="error">Por favor complete todos los campos</p>
        <%
        } else if ("producto_existe".equals(error)) {
        %>
        <p class="error">El producto ya existe en el inventario</p>
        <%
            }
        %>

        <%
            String mensaje = request.getParameter("mensaje");
            if ("agregado".equals(mensaje)) {
        %>
        <p class="mensaje">Producto agregado correctamente</p>
        <%
            }
        %>

        <div class="acciones">
            <form action="productos" method="get">
                <button type="submit">Ver Inventario</button>
            </form>

            <form action="logout" method="post">
                <button type="submit">Cerrar sesión</button>
            </form>
        </div>

    </body>
</html>
