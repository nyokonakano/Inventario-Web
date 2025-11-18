<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Login - Sistema de Inventario</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            min-height: 100vh;
            align-items: center;
            justify-content: center;
        }

        .login-container {
            background: white;
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            width: 400px;
            text-align: center;
        }

        .logo {
            font-size: 60px;
            margin-bottom: 10px;
        }

        h1 {
            margin-bottom: 10px;
            color: #1f2937;
            font-size: 28px;
        }

        .subtitle {
            color: #6b7280;
            margin-bottom: 30px;
            font-size: 14px;
        }

        input[type="text"],
        input[type="password"] {
            width: 100%;
            padding: 14px;
            margin: 10px 0;
            border: 2px solid #e5e7eb;
            border-radius: 10px;
            font-size: 16px;
            transition: border 0.3s;
        }

        input[type="text"]:focus,
        input[type="password"]:focus {
            outline: none;
            border-color: #667eea;
        }

        button {
            width: 100%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            font-weight: bold;
            font-size: 16px;
            cursor: pointer;
            border: none;
            padding: 14px;
            border-radius: 10px;
            margin-top: 10px;
            transition: all 0.3s;
        }

        button:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
        }

        .error {
            background: #fee2e2;
            border: 2px solid #ef4444;
            color: #991b1b;
            padding: 12px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-size: 14px;
            font-weight: bold;
        }

        .demo-users {
            margin-top: 30px;
            padding: 20px;
            background: #f3f4f6;
            border-radius: 10px;
            text-align: left;
        }

        .demo-users h3 {
            color: #374151;
            font-size: 14px;
            margin-bottom: 10px;
        }

        .demo-users p {
            color: #6b7280;
            font-size: 13px;
            margin: 5px 0;
        }

        .demo-users strong {
            color: #1f2937;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="logo">🔐</div>
        <h1>Iniciar Sesión</h1>
        <p class="subtitle">Sistema de Gestión de Inventario</p>

        <%
            String error = request.getParameter("error");
            if ("credenciales".equals(error)) {
        %>
            <div class="error">❌ Usuario o contraseña incorrectos</div>
        <%
            } else if ("usuario_inactivo".equals(error)) {
        %>
            <div class="error">⚠️ Tu cuenta está desactivada. Contacta al administrador.</div>
        <%
            } else if ("datos_vacios".equals(error)) {
        %>
            <div class="error">⚠️ Por favor complete todos los campos</div>
        <%
            } else if ("sistema".equals(error)) {
        %>
            <div class="error">❌ Error del sistema. Intenta más tarde.</div>
        <%
            } else if ("acceso_denegado".equals(error)) {
        %>
            <div class="error">🚫 No tienes permisos para acceder a esa sección</div>
        <%
            }
        %>

        <form method="post" action="login">
            <input type="text" name="usuario" placeholder="👤 Usuario" required autofocus>
            <input type="password" name="clave" placeholder="🔒 Contraseña" required>
            <button type="submit">Ingresar al Sistema</button>
        </form>
    </div>
</body>
</html>