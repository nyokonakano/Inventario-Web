<%@page import="java.util.List"%>
<%@page import="modelo.Producto"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Inventario</title>
        <style>
            body {
                font-family: 'Segoe UI', sans-serif;
                background-color: #f9f9f9;
                padding: 40px;
            }

            h1 {
                text-align: center;
                color: #333;
            }

            .top-bar {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 20px;
            }

            form.search-form {
                display: flex;
            }

            input[type="text"] {
                padding: 8px;
                font-size: 14px;
                border-radius: 6px;
                border: 1px solid #ccc;
                width: 250px;
            }

            button {
                padding: 8px 14px;
                font-size: 14px;
                border-radius: 6px;
                border: none;
                background-color: #4CAF50;
                color: white;
                cursor: pointer;
                margin-left: 5px;
                transition: background-color 0.3s ease;
            }

            button:hover {
                background-color: #388e3c;
            }

            table {
                width: 100%;
                border-collapse: collapse;
                margin-top: 15px;
                background-color: white;
                box-shadow: 0 0 10px rgba(0,0,0,0.05);
            }

            th, td {
                border: 1px solid #ccc;
                padding: 12px;
                text-align: center;
            }

            th {
                background-color: #e0e0e0;
            }

            td form {
                display: inline-block;
            }

            .no-result {
                text-align: center;
                padding: 20px;
                color: gray;
            }
        </style>
    </head>
    <body>
        <h1>Inventario</h1>
        <div class="top-bar">
            <form action="index.jsp" method="get">
                <button type="submit">Volver</button>
            </form>

            <form action="productos" method="get" class="search-form">
                <input type="text" name="busqueda" placeholder="Buscar por nombre o categoría" required>
                <button type="submit">Buscar</button>
            </form>
        </div>

        <table>
            <tr>
                <th>Nombre</th>
                <th>Cantidad</th>
                <th>Precio</th>
                <th>Categoría</th>
                <th>Total</th>
                <th>Acciones</th>
            </tr>

            <%
                List<Producto> lista = (List<Producto>) request.getAttribute("listaProductos");
                if (lista != null && !lista.isEmpty()) {
                    for (Producto p : lista) {
            %>
            <tr>
                <td><%= p.getNombre()%></td>
                <td><%= p.getCantidad()%></td>
                <td>$<%= String.format("%.2f", p.getPrecio())%></td>
                <td><%= p.getCategoria()%></td>
                <td>$<%= String.format("%.2f", p.getCantidad() * p.getPrecio())%></td>
                <td>
                    <!-- Editar -->
                    <form method="get" action="editar" style="display:inline;">
                        <input type="hidden" name="nombre" value="<%= p.getNombre()%>">
                        <button type="submit">Editar</button>
                    </form>

                    <!-- Eliminar -->
                    <form method="post" action="productos" style="display:inline;" onsubmit="return confirm('¿Eliminar este producto?');">
                        <input type="hidden" name="accion" value="eliminar">
                        <input type="hidden" name="nombre" value="<%= p.getNombre()%>">
                        <button type="submit">Eliminar</button>
                    </form>
                </td>
            </tr>
            <%
                }
            } else {
            %>
            <tr>
                <td colspan="6" class="no-result">No hay productos en el inventario.</td>
            </tr>
            <%
                }
            %>
        </table>
    </body>
</html>
