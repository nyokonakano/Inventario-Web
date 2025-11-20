<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Login - Sistema de Inventario</title>
    <style>
        :root {
            --primary: #2563eb;
            --primary-dark: #1e40af;
            --bg: #f8fafc;
            --surface: #ffffff;
            --text: #0f172a;
            --text-secondary: #64748b;
            --border: #e2e8f0;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            min-height: 100vh;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .login-container {
            background: var(--surface);
            padding: 48px 40px;
            border-radius: 20px;
            width: 420px;
            max-width: 100%;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }

        .logo {
            font-size: 48px;
            text-align: center;
            margin-bottom: 8px;
        }

        h1 {
            margin-bottom: 8px;
            color: var(--text);
            font-size: 28px;
            font-weight: 600;
            text-align: center;
        }

        .subtitle {
            color: var(--text-secondary);
            margin-bottom: 32px;
            font-size: 14px;
            text-align: center;
        }

        input[type="text"],
        input[type="password"] {
            width: 100%;
            padding: 14px 16px;
            margin: 10px 0;
            border: 1px solid var(--border);
            border-radius: 10px;
            font-size: 15px;
            transition: all 0.2s;
        }

        input[type="text"]:focus,
        input[type="password"]:focus {
            outline: none;
            border-color: var(--primary);
            background: var(--bg);
        }

        button {
            width: 100%;
            background: var(--primary);
            color: white;
            font-weight: 500;
            font-size: 15px;
            cursor: pointer;
            border: none;
            padding: 14px;
            border-radius: 10px;
            margin-top: 16px;
            transition: all 0.2s;
        }

        button:hover {
            background: var(--primary-dark);
        }

        .error {
            background: #fee2e2;
            border: 1px solid #fca5a5;
            color: #991b1b;
            padding: 14px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-size: 14px;
            font-weight: 500;
        }

        .demo-users {
            margin-top: 32px;
            padding: 20px;
            background: var(--bg);
            border-radius: 12px;
            text-align: left;
            border: 1px solid var(--border);
        }

        .demo-users h3 {
            color: var(--text);
            font-size: 14px;
            margin-bottom: 12px;
            font-weight: 600;
        }

        .demo-users p {
            color: var(--text-secondary);
            font-size: 13px;
            margin: 8px 0;
        }

        .demo-users strong {
            color: var(--text);
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