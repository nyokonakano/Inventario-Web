<%@page import="modelo.Usuario"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    Usuario user = (Usuario) session.getAttribute("usuario");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Monitor en Tiempo Real</title>
    <style>
        :root {
            --primary: #2563eb;
            --bg: #0f172a;
            --surface: #1e293b;
            --text: #f1f5f9;
            --text-secondary: #94a3b8;
            --border: #334155;
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
            font-family: 'JetBrains Mono', 'Courier New', monospace;
            background-color: var(--bg);
            color: var(--text);
            padding: 24px;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        .header {
            background: var(--surface);
            padding: 24px 32px;
            border-radius: 12px;
            border: 1px solid var(--border);
            margin-bottom: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        h1 {
            color: var(--text);
            font-size: 20px;
            font-weight: 600;
        }

        .status {
            display: flex;
            gap: 16px;
            align-items: center;
        }

        .status-indicator {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }

        .online {
            background: var(--success);
            box-shadow: 0 0 20px var(--success);
        }

        .offline {
            background: var(--danger);
            box-shadow: 0 0 20px var(--danger);
        }

        @keyframes pulse {
            0%, 100% {
                opacity: 1;
            }
            50% {
                opacity: 0.5;
            }
        }

        .btn {
            background: var(--surface);
            color: var(--text);
            border: 1px solid var(--border);
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 500;
            font-size: 14px;
            transition: all 0.2s;
            text-decoration: none;
        }

        .btn:hover {
            background: var(--primary);
            border-color: var(--primary);
        }

        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 24px;
        }

        .panel {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 24px;
        }

        .panel h2 {
            color: var(--text);
            margin-bottom: 20px;
            font-size: 16px;
            font-weight: 600;
            border-bottom: 1px solid var(--border);
            padding-bottom: 12px;
        }

        #log-messages {
            height: 400px;
            overflow-y: auto;
            background: var(--bg);
            padding: 16px;
            border-radius: 8px;
            font-size: 13px;
            line-height: 1.6;
            border: 1px solid var(--border);
        }

        #log-messages::-webkit-scrollbar {
            width: 8px;
        }

        #log-messages::-webkit-scrollbar-track {
            background: var(--bg);
            border-radius: 4px;
        }

        #log-messages::-webkit-scrollbar-thumb {
            background: var(--border);
            border-radius: 4px;
        }

        .log-entry {
            margin: 6px 0;
            padding: 8px 12px;
            border-left: 3px solid var(--success);
            background: rgba(16, 185, 129, 0.05);
            border-radius: 4px;
        }

        .log-alert {
            border-left-color: var(--danger);
            background: rgba(239, 68, 68, 0.05);
            color: #fca5a5;
        }

        .log-warning {
            border-left-color: var(--warning);
            background: rgba(245, 158, 11, 0.05);
            color: #fcd34d;
        }

        .log-info {
            border-left-color: var(--success);
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 16px;
            margin: 24px 0;
        }

        .stat-box {
            background: var(--bg);
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border: 1px solid var(--border);
        }

        .stat-number {
            font-size: 32px;
            font-weight: 700;
            color: var(--success);
            margin-bottom: 4px;
        }

        .stat-label {
            font-size: 12px;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        #usuarios-online {
            list-style: none;
            padding: 0;
            max-height: 200px;
            overflow-y: auto;
        }

        #usuarios-online li {
            padding: 12px;
            background: var(--bg);
            margin: 8px 0;
            border-radius: 8px;
            border-left: 3px solid var(--success);
            font-size: 14px;
        }

        @media (max-width: 1024px) {
            .grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <h1>🌐 MONITOR EN TIEMPO REAL</h1>
                <small>Usuario: <%= user.getNombreCompleto() %></small>
            </div>
            <div class="status">
                <div id="status-indicator" class="status-indicator offline"></div>
                <span id="status-text">Desconectado</span>
                <button class="btn" onclick="location.href='admin.jsp'">← Volver</button>
            </div>
        </div>

        <div class="grid">
            <!-- Panel de Logs -->
            <div class="panel">
                <h2>📋 LOG DE EVENTOS</h2>
                <div id="log-messages"></div>
                <button class="btn" onclick="limpiarLog()" style="margin-top:10px;">🗑️ Limpiar Log</button>
            </div>

            <!-- Panel de Usuarios Conectados -->
            <div class="panel">
                <h2>👥 USUARIOS CONECTADOS</h2>
                <ul id="usuarios-online"></ul>
                
                <div class="stats">
                    <div class="stat-box">
                        <div class="stat-number" id="stat-usuarios">0</div>
                        <div class="stat-label">Conectados</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-number" id="stat-mensajes">0</div>
                        <div class="stat-label">Mensajes</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-number" id="stat-cambios">0</div>
                        <div class="stat-label">Cambios</div>
                    </div>
                </div>

                <button class="btn" onclick="enviarPing()" style="margin-top:20px;">📡 Enviar Ping</button>
            </div>
        </div>
    </div>

    <script>
        let websocket = null;
        let mensajesRecibidos = 0;
        let cambiosDetectados = 0;
        const usuario = "<%= user.getUsuario() %>";

        // Conectar al WebSocket al cargar la página
        window.onload = function() {
            conectarWebSocket();
        };

        function conectarWebSocket() {
            const wsUrl = "ws://" + window.location.host + "/InventarioWeb/websocket/inventario";
            console.log("Conectando a:", wsUrl);

            try {
                websocket = new WebSocket(wsUrl);

                websocket.onopen = function(event) {
                    console.log("WebSocket conectado");
                    actualizarEstado(true);
                    agregarLog("✅ Conectado al servidor", "info");

                    // Registrar usuario
                    enviarMensaje({
                        tipo: "registrar_usuario",
                        usuario: usuario
                    });

                    // Solicitar estado inicial
                    setTimeout(() => {
                        enviarMensaje({ tipo: "solicitar_estado" });
                    }, 500);
                };

                websocket.onmessage = function(event) {
                    console.log("Mensaje recibido:", event.data);
                    mensajesRecibidos++;
                    document.getElementById("stat-mensajes").textContent = mensajesRecibidos;

                    try {
                        const mensaje = JSON.parse(event.data);
                        procesarMensaje(mensaje);
                    } catch (e) {
                        console.error("Error parseando mensaje:", e);
                    }
                };

                websocket.onerror = function(event) {
                    console.error("Error en WebSocket:", event);
                    agregarLog("❌ Error en la conexión", "alert");
                };

                websocket.onclose = function(event) {
                    console.log("WebSocket cerrado:", event);
                    actualizarEstado(false);
                    agregarLog("🔴 Conexión cerrada - Reconectando en 5 segundos...", "warning");

                    // Intentar reconectar
                    setTimeout(conectarWebSocket, 5000);
                };

            } catch (e) {
                console.error("Error creando WebSocket:", e);
                agregarLog("❌ Error al conectar", "alert");
            }
        }

        function procesarMensaje(mensaje) {
            const { tipo, mensaje: msg, datos, producto, accion, usuario: usuarioAccion, cantidad } = mensaje;

            switch (tipo) {
                case "conexion":
                    agregarLog("✅ " + msg, "info");
                    break;

                case "usuario_conectado":
                    agregarLog("👤 " + msg, "info");
                    actualizarContadorUsuarios(datos);
                    break;

                case "usuario_desconectado":
                    agregarLog("👋 " + msg, "warning");
                    actualizarContadorUsuarios(datos);
                    break;

                case "producto_actualizado":
                    cambiosDetectados++;
                    document.getElementById("stat-cambios").textContent = cambiosDetectados;
                    agregarLog(`🔄 ${usuarioAccion} ${accion} el producto: ${producto}`, "info");
                    
                    // Aquí podrías actualizar la tabla del inventario automáticamente
                    break;

                case "alerta_stock_bajo":
                    agregarLog(`⚠️ ${msg}`, "alert");
                    // Reproducir sonido de alerta si lo deseas
                    break;

                case "actualizar_inventario":
                    agregarLog(`📦 ${msg} - ${datos}`, "warning");
                    break;

                case "estado_servidor":
                    agregarLog(`ℹ️ ${msg} - ${datos}`, "info");
                    break;

                case "pong":
                    agregarLog("🏓 Pong recibido - Conexión activa", "info");
                    break;

                default:
                    console.log("Tipo de mensaje desconocido:", tipo);
            }
        }

        function enviarMensaje(mensaje) {
            if (websocket && websocket.readyState === WebSocket.OPEN) {
                websocket.send(JSON.stringify(mensaje));
                console.log("Mensaje enviado:", mensaje);
            } else {
                console.error("WebSocket no conectado");
                agregarLog("❌ No se puede enviar mensaje - Desconectado", "alert");
            }
        }

        function enviarPing() {
            enviarMensaje({ tipo: "ping" });
            agregarLog("🏓 Ping enviado...", "info");
        }

        function agregarLog(mensaje, tipo = "info") {
            const log = document.getElementById("log-messages");
            const timestamp = new Date().toLocaleTimeString();
            const entry = document.createElement("div");
            entry.className = `log-entry log-${tipo}`;
            entry.textContent = `[${timestamp}] ${mensaje}`;
            log.appendChild(entry);
            log.scrollTop = log.scrollHeight;
        }

        function limpiarLog() {
            document.getElementById("log-messages").innerHTML = "";
            agregarLog("📋 Log limpiado", "info");
        }

        function actualizarEstado(conectado) {
            const indicator = document.getElementById("status-indicator");
            const text = document.getElementById("status-text");

            if (conectado) {
                indicator.className = "status-indicator online";
                text.textContent = "Conectado";
                text.style.color = "#00ff00";
            } else {
                indicator.className = "status-indicator offline";
                text.textContent = "Desconectado";
                text.style.color = "#ff0000";
            }
        }

        function actualizarContadorUsuarios(datos) {
            const match = datos.match(/(\d+)/);
            if (match) {
                document.getElementById("stat-usuarios").textContent = match[1];
            }
        }

        // Cerrar WebSocket al salir
        window.onbeforeunload = function() {
            if (websocket) {
                websocket.close();
            }
        };
    </script>
</body>
</html>