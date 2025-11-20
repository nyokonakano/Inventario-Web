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
    
    // Clase auxiliar para items del carrito
    class ItemCarrito {
        String producto;
        int cantidad;
        double precio;
        public ItemCarrito(String p, int c, double pr) {
            producto = p; cantidad = c; precio = pr;
        }
    }
    
    // Obtener items del carrito
    List<ItemCarrito> items = new ArrayList<>();
    double total = 0;
    
    try (Connection conn = ConexionMySQL.conectar()) {
        String sql = "SELECT producto_nombre, cantidad, precio_unitario FROM carritos WHERE usuario_id = ?";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setInt(1, user.getId());
        ResultSet rs = stmt.executeQuery();
        
        while (rs.next()) {
            ItemCarrito item = new ItemCarrito(
                rs.getString("producto_nombre"),
                rs.getInt("cantidad"),
                rs.getDouble("precio_unitario")
            );
            items.add(item);
            total += item.cantidad * item.precio;
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    
    if (items.isEmpty()) {
        response.sendRedirect("shop.jsp");
        return;
    }
    
    // Obtener tarjetas del usuario
    class Tarjeta {
        int id;
        String numero;
        String titular;
        String expiracion;
        String tipo;
        String banco;
        public Tarjeta(int i, String n, String t, String e, String ti, String b) {
            id = i; numero = n; titular = t; expiracion = e; tipo = ti; banco = b;
        }
    }
    
    List<Tarjeta> tarjetas = new ArrayList<>();
    try (Connection conn = ConexionMySQL.conectar()) {
        String sql = "SELECT id, numero_tarjeta, nombre_titular, fecha_expiracion, tipo, banco " +
                     "FROM tarjetas WHERE usuario_id = ?";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setInt(1, user.getId());
        ResultSet rs = stmt.executeQuery();
        
        while (rs.next()) {
            tarjetas.add(new Tarjeta(
                rs.getInt("id"),
                rs.getString("numero_tarjeta"),
                rs.getString("nombre_titular"),
                rs.getString("fecha_expiracion"),
                rs.getString("tipo"),
                rs.getString("banco")
            ));
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Checkout - Finalizar Compra</title>
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
        }

        .checkout-container {
            max-width: 1200px;
            margin: 0 auto;
        }

        .checkout-header {
            background: var(--surface);
            padding: 24px 32px;
            border-radius: 16px;
            border: 1px solid var(--border);
            margin-bottom: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .checkout-header h1 {
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
            transition: all 0.2s;
        }

        .btn-back:hover {
            background: var(--bg);
        }

        .checkout-grid {
            display: grid;
            grid-template-columns: 1fr 400px;
            gap: 24px;
        }

        .section {
            background: var(--surface);
            padding: 32px;
            border-radius: 16px;
            border: 1px solid var(--border);
            margin-bottom: 24px;
        }

        .section h2 {
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 24px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            font-size: 14px;
            color: var(--text);
        }

        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 12px 16px;
            border: 1px solid var(--border);
            border-radius: 10px;
            font-size: 14px;
            transition: all 0.2s;
        }

        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: var(--primary);
        }

        .tarjeta-card {
            border: 2px solid var(--border);
            padding: 16px;
            border-radius: 12px;
            margin-bottom: 12px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .tarjeta-card:hover {
            border-color: var(--primary);
        }

        .tarjeta-card.selected {
            border-color: var(--primary);
            background: rgba(37, 99, 235, 0.05);
        }

        .tarjeta-numero {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 8px;
            letter-spacing: 2px;
        }

        .tarjeta-info {
            display: flex;
            justify-content: space-between;
            font-size: 13px;
            color: var(--text-secondary);
        }

        .nueva-tarjeta-btn {
            width: 100%;
            padding: 14px;
            background: var(--surface);
            border: 2px dashed var(--border);
            border-radius: 10px;
            color: var(--text);
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
        }

        .nueva-tarjeta-btn:hover {
            border-color: var(--primary);
            color: var(--primary);
        }

        .order-summary {
            background: var(--surface);
            padding: 32px;
            border-radius: 16px;
            border: 1px solid var(--border);
        }

        .order-item {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid var(--border);
        }

        .order-item:last-child {
            border-bottom: none;
        }

        .order-item-name {
            font-weight: 500;
            font-size: 14px;
        }

        .order-item-qty {
            color: var(--text-secondary);
            font-size: 13px;
        }

        .order-item-price {
            font-weight: 600;
            color: var(--text);
        }

        .order-totals {
            margin-top: 24px;
            padding-top: 24px;
            border-top: 2px solid var(--border);
        }

        .total-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 12px;
            font-size: 15px;
        }

        .total-row.grand-total {
            font-size: 24px;
            font-weight: 700;
            color: var(--primary);
            margin-top: 12px;
            padding-top: 12px;
            border-top: 2px solid var(--border);
        }

        .place-order-btn {
            width: 100%;
            padding: 16px;
            background: var(--success);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            margin-top: 24px;
            transition: all 0.2s;
        }

        .place-order-btn:hover {
            background: #059669;
        }

        .place-order-btn:disabled {
            background: var(--border);
            cursor: not-allowed;
        }

        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            z-index: 1000;
            padding: 24px;
        }

        .modal-content {
            background: var(--surface);
            max-width: 600px;
            margin: 50px auto;
            border-radius: 16px;
            padding: 32px;
        }

        .modal-header {
            margin-bottom: 24px;
        }

        .modal-header h3 {
            font-size: 20px;
            font-weight: 600;
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }

        @media (max-width: 1024px) {
            .checkout-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="checkout-container">
        <div class="checkout-header">
            <h1>🛒 Finalizar Compra</h1>
            <a href="shop.jsp" class="btn-back">← Volver a la tienda</a>
        </div>

        <div class="checkout-grid">
            <!-- Formulario de checkout -->
            <div>
                <!-- Método de Pago -->
                <div class="section">
                    <h2>💳 Método de Pago</h2>
                    
                    <% if (!tarjetas.isEmpty()) { %>
                        <div id="tarjetas-list">
                            <% for (Tarjeta t : tarjetas) { %>
                            <div class="tarjeta-card" onclick="seleccionarTarjeta(<%= t.id %>)">
                                <input type="radio" name="tarjeta" value="<%= t.id %>" id="tarjeta-<%= t.id %>" style="display:none;">
                                <div class="tarjeta-numero">
                                    <% if ("CREDITO".equals(t.tipo)) { %>💳<% } else { %>🏦<% } %>
                                    <%= t.numero %>
                                </div>
                                <div class="tarjeta-info">
                                    <span><%= t.titular %></span>
                                    <span><%= t.banco %> | <%= t.tipo %></span>
                                    <span>Exp: <%= t.expiracion %></span>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    <% } %>
                    
                    <button class="nueva-tarjeta-btn" onclick="mostrarFormularioTarjeta()">
                        ➕ Agregar Nueva Tarjeta
                    </button>
                </div>

                <!-- Dirección de Envío -->
                <div class="section">
                    <h2>📦 Dirección de Envío</h2>
                    <form id="checkout-form">
                        <div class="form-group">
                            <label>Dirección Completa *</label>
                            <textarea name="direccion" rows="3" required placeholder="Calle, número, distrito, ciudad"></textarea>
                        </div>
                        
                        <div class="form-row">
                            <div class="form-group">
                                <label>Teléfono *</label>
                                <input type="tel" name="telefono" required placeholder="999 999 999">
                            </div>
                            <div class="form-group">
                                <label>Código Postal</label>
                                <input type="text" name="codigo_postal" placeholder="15001">
                            </div>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Resumen del pedido -->
            <div>
                <div class="order-summary">
                    <h2 style="margin-bottom: 24px;">📋 Resumen del Pedido</h2>
                    
                    <% for (ItemCarrito item : items) { %>
                    <div class="order-item">
                        <div>
                            <div class="order-item-name"><%= item.producto %></div>
                            <div class="order-item-qty">Cantidad: <%= item.cantidad %></div>
                        </div>
                        <div class="order-item-price">
                            $<%= String.format("%.2f", item.cantidad * item.precio) %>
                        </div>
                    </div>
                    <% } %>
                    
                    <div class="order-totals">
                        <div class="total-row">
                            <span>Subtotal:</span>
                            <span>$<%= String.format("%.2f", total) %></span>
                        </div>
                        <div class="total-row">
                            <span>Envío:</span>
                            <span>Gratis</span>
                        </div>
                        <div class="total-row">
                            <span>Impuestos:</span>
                            <span>$<%= String.format("%.2f", total * 0.18) %></span>
                        </div>
                        <div class="total-row grand-total">
                            <span>Total:</span>
                            <span>$<%= String.format("%.2f", total * 1.18) %></span>
                        </div>
                    </div>
                    
                    <button class="place-order-btn" onclick="realizarPedido()">
                        Realizar Pedido
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal Nueva Tarjeta -->
    <div id="modalNuevaTarjeta" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3>➕ Agregar Nueva Tarjeta</h3>
            </div>
            <form id="form-nueva-tarjeta" onsubmit="agregarTarjeta(event)">
                <div class="form-group">
                    <label>Número de Tarjeta *</label>
                    <input type="text" name="numero" required placeholder="1234-5678-9012-3456" 
                           pattern="[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}" maxlength="19">
                </div>
                
                <div class="form-group">
                    <label>Nombre del Titular *</label>
                    <input type="text" name="titular" required placeholder="NOMBRE APELLIDO" style="text-transform: uppercase;">
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label>Fecha de Expiración *</label>
                        <input type="text" name="expiracion" required placeholder="MM/YYYY" 
                               pattern="[0-9]{2}/[0-9]{4}" maxlength="7">
                    </div>
                    <div class="form-group">
                        <label>CVV *</label>
                        <input type="text" name="cvv" required placeholder="123" 
                               pattern="[0-9]{3,4}" maxlength="4">
                    </div>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label>Tipo *</label>
                        <select name="tipo" required>
                            <option value="CREDITO">Crédito</option>
                            <option value="DEBITO">Débito</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Banco *</label>
                        <input type="text" name="banco" required placeholder="Nombre del banco">
                    </div>
                </div>
                
                <div style="display: flex; gap: 12px; margin-top: 24px;">
                    <button type="submit" style="flex: 1; padding: 14px; background: var(--primary); color: white; border: none; border-radius: 10px; font-weight: 500; cursor: pointer;">
                        Guardar Tarjeta
                    </button>
                    <button type="button" onclick="cerrarModalTarjeta()" style="flex: 1; padding: 14px; background: var(--surface); color: var(--text); border: 1px solid var(--border); border-radius: 10px; font-weight: 500; cursor: pointer;">
                        Cancelar
                    </button>
                </div>
            </form>
        </div>
    </div>

    <script>
        let tarjetaSeleccionada = null;

        function seleccionarTarjeta(id) {
            document.querySelectorAll('.tarjeta-card').forEach(card => {
                card.classList.remove('selected');
            });
            
            event.currentTarget.classList.add('selected');
            document.getElementById('tarjeta-' + id).checked = true;
            tarjetaSeleccionada = id;
        }

        function mostrarFormularioTarjeta() {
            document.getElementById('modalNuevaTarjeta').style.display = 'block';
        }

        function cerrarModalTarjeta() {
            document.getElementById('modalNuevaTarjeta').style.display = 'none';
            document.getElementById('form-nueva-tarjeta').reset();
        }

        function agregarTarjeta(event) {
            event.preventDefault();
            const formData = new FormData(event.target);
            
            fetch('TarjetaServlet', {
                method: 'POST',
                body: new URLSearchParams({
                    accion: 'agregar',
                    numero: formData.get('numero'),
                    titular: formData.get('titular'),
                    expiracion: formData.get('expiracion'),
                    cvv: formData.get('cvv'),
                    tipo: formData.get('tipo'),
                    banco: formData.get('banco')
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✅ Tarjeta agregada exitosamente');
                    location.reload();
                } else {
                    alert('❌ Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error al agregar tarjeta');
            });
        }

        function realizarPedido() {
            if (!tarjetaSeleccionada) {
                alert('Por favor selecciona un método de pago');
                return;
            }
            
            const form = document.getElementById('checkout-form');
            if (!form.checkValidity()) {
                form.reportValidity();
                return;
            }
            
            const formData = new FormData(form);
            formData.append('tarjeta_id', tarjetaSeleccionada);
            
            if (!confirm('¿Confirmar pedido por $<%= String.format("%.2f", total * 1.18) %>?')) {
                return;
            }
            
            fetch('PedidoServlet', {
                method: 'POST',
                body: new URLSearchParams(formData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✅ ¡Pedido realizado exitosamente!');
                    window.location.href = 'mis-pedidos.jsp';
                } else {
                    alert('❌ Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error al procesar el pedido');
            });
        }

        // Auto-formateo número de tarjeta
        document.querySelector('input[name="numero"]')?.addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            let formatted = value.match(/.{1,4}/g)?.join('-') || value;
            e.target.value = formatted.substring(0, 19);
        });

        // Auto-formateo fecha
        document.querySelector('input[name="expiracion"]')?.addEventListener('input', function(e) {
            let value = e.target.value.replace(/\D/g, '');
            if (value.length >= 2) {
                value = value.substring(0, 2) + '/' + value.substring(2, 6);
            }
            e.target.value = value;
        });
    </script>
</body>
</html>