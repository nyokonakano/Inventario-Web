<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Login - Inventario</title>
        <style>
            body {
                font-family: 'Segoe UI', sans-serif;
                background-color: #f2f2f2;
                display: flex;
                height: 100vh;
                align-items: center;
                justify-content: center;
                margin: 0;
            }

            .login-container {
                background-color: white;
                padding: 30px 40px;
                border-radius: 10px;
                box-shadow: 0 0 15px rgba(0, 0, 0, 0.1);
                width: 350px;
                text-align: center;
            }

            h1 {
                margin-bottom: 25px;
                color: #333;
            }

            input[type="text"],
            input[type="password"],
            button {
                width: 100%;
                padding: 12px;
                margin: 10px 0;
                border: 1px solid #ccc;
                border-radius: 6px;
                font-size: 16px;
                box-sizing: border-box;
            }

            button {
                background-color: #4CAF50;
                color: white;
                font-weight: bold;
                cursor: pointer;
                border: none;
                transition: background-color 0.3s ease;
            }

            button:hover {
                background-color: #45a049;
            }

            .error {
                color: red;
                font-size: 14px;
                margin-top: 10px;
            }
        </style>
    </head>
    <body>

        <div class="login-container">
            <h1>Iniciar Sesión</h1>

            <form method="post" action="login">
                <input type="text" name="usuario" placeholder="Usuario" required>
                <input type="password" name="clave" placeholder="Contraseña" required>
                <button type="submit">Ingresar</button>
            </form>

            <%
                String error = request.getParameter("error");
                if (error != null) {
            %>
            <p class="error">Usuario o contraseña incorrectos</p>
            <%
                }
            %>
        </div>

    </body>
</html>
