<%@page import="modelo.Usuario"%>
<%@page import="modelo.Producto"%>
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
    
    // Obtener productos
    List<Producto> productos = new ArrayList<>();
    String busqueda = request.getParameter("busqueda");
    String categoriaFiltro = request.getParameter("categoria");
    
    try (Connection conn = ConexionMySQL.conectar()) {
        String sql = "SELECT * FROM productos WHERE 1=1";
        
        if (busqueda != null && !busqueda.trim().isEmpty()) {
            sql += " AND (LOWER(nombre) LIKE ? OR LOWER(categoria) LIKE ?)";
        }
        
        if (categoriaFiltro != null && !categoriaFiltro.isEmpty() && !"TODAS".equals(categoriaFiltro)) {
            sql += " AND categoria = ?";
        }
        
        sql += " ORDER BY nombre";
        
        PreparedStatement stmt = conn.prepareStatement(sql);
        int paramIndex = 1;
        
        if (busqueda != null && !busqueda.trim().isEmpty()) {
            String termino = "%" + busqueda.toLowerCase() + "%";
            stmt.setString(paramIndex++, termino);
            stmt.setString(paramIndex++, termino);
        }
        
        if (categoriaFiltro != null && !categoriaFiltro.isEmpty() && !"TODAS".equals(categoriaFiltro)) {
            stmt.setString(paramIndex, categoriaFiltro);
        }
        
        ResultSet rs = stmt.executeQuery();
        while (rs.next()) {
            Producto p = new Producto();
            p.setNombre(rs.getString("nombre"));
            p.setCantidad(rs.getInt("cantidad"));
            p.setPrecio(rs.getDouble("precio"));
            p.setCategoria(rs.getString("categoria"));
            productos.add(p);
        }
        
    } catch (SQLException e) {
        e.printStackTrace();
    }
    
    // Obtener categorías únicas
    Set<String> categorias = new TreeSet<>();
    try (Connection conn = ConexionMySQL.conectar()) {
        ResultSet rs = conn.createStatement().executeQuery("SELECT DISTINCT categoria FROM productos ORDER BY categoria");
        while (rs.next()) {
            categorias.add(rs.getString("categoria"));
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    
    // Contar items en carrito
    int itemsCarrito = 0;
    try (Connection conn = ConexionMySQL.conectar()) {
        String sql = "SELECT SUM(cantidad) FROM carritos WHERE usuario_id = ?";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setInt(1, user.getId());
        ResultSet rs = stmt.executeQuery();
        if (rs.next()) {
            itemsCarrito = rs.getInt(1);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tienda - <%= user.getNombreCompleto() %></title>
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
            color: var(--text);
        }

        .shop-container {
            max-width: 1600px;
            margin: 0 auto;
            padding: 24px;
        }

        .shop-header {
            background: var(--surface);
            padding: 24px 32px;
            border-radius: 16px;
            border: 1px solid var(--border);
            margin-bottom: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .shop-header h1 {
            font-size: 24px;
            font-weight: 600;
        }

        .cart-button {
            position: relative;
            background: var(--primary);
            color: white;
            padding: 10px 20px;
            border-radius: 10px;
            border: none;
            cursor: pointer;
            font-weight: 500;
            font-size: 14px;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .cart-button:hover {
            background: var(--primary-dark);
        }

        .cart-badge {
            position: absolute;
            top: -8px;
            right: -8px;
            background: var(--danger);
            color: white;
            border-radius: 50%;
            width: 24px;
            height: 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            font-weight: 700;
        }

        .search-bar {
            background: var(--surface);
            padding: 16px 24px;
            border-radius: 12px;
            border: 1px solid var(--border);
            margin-bottom: 24px;
            display: flex;
            gap: 12px;
        }

        .search-bar input {
            flex: 1;
            padding: 12px 16px;
            border: 1px solid var(--border);
            border-radius: 10px;
            font-size: 14px;
        }

        .search-bar select {
            padding: 12px 16px;
            border: 1px solid var(--border);
            border-radius: 10px;
            font-size: 14px;
            background: var(--surface);
        }

        .products-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 24px;
        }

        .product-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 20px;
            transition: all 0.2s;
        }

        .product-card:hover {
            border-color: var(--primary);
            transform: translateY(-4px);
        }

        .product-image {
            width: 100%;
            height: 180px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 64px;
            margin-bottom: 16px;
        }

        .product-name {
            font-size: 16px;
            font-weight: 600;
            color: var(--text);
            margin-bottom: 8px;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }

        .product-category {
            font-size: 12px;
            color: var(--text-secondary);
            margin-bottom: 8px;
        }

        .product-price {
            font-size: 24px;
            font-weight: 700;
            color: var(--primary);
            margin-bottom: 8px;
        }

        .product-stock {
            font-size: 13px;
            margin-bottom: 16px;
        }

        .stock-available {
            color: var(--success);
        }

        .stock-low {
            color: var(--warning);
        }

        .stock-out {
            color: var(--danger);
        }

        .quantity-selector {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 12px;
        }

        .quantity-btn {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            border: 1px solid var(--border);
            background: var(--surface);
            cursor: pointer;
            font-size: 18px;
            font-weight: 600;
            transition: all 0.2s;
        }

        .quantity-btn:hover {
            background: var(--bg);
        }

        .quantity-input {
            width: 60px;
            text-align: center;
            padding: 8px;
            border: 1px solid var(--border);
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
        }

        .add-to-cart-btn {
            width: 100%;
            padding: 12px;
            background: var(--primary);
            color: white;
            border: none;
            border-radius: 10px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
            font-size: 14px;
        }

        .add-to-cart-btn:hover {
            background: var(--primary-dark);
        }

        .add-to-cart-btn:disabled {
            background: var(--border);
            cursor: not-allowed;
        }

        /* Modal Carrito */
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
            max-width: 900px;
            margin: 0 auto;
            border-radius: 16px;
            max-height: 90vh;
            overflow-y: auto;
            position: relative;
        }

        .modal-header {
            padding: 24px 32px;
            border-bottom: 1px solid var(--border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .modal-header h2 {
            font-size: 24px;
            font-weight: 600;
        }

        .close-modal {
            width: 40px;
            height: 40px;
            border-radius: 8px;
            border: none;
            background: var(--bg);
            cursor: pointer;
            font-size: 24px;
            transition: all 0.2s;
        }

        .close-modal:hover {
            background: var(--border);
        }

        .modal-body {
            padding: 24px 32px;
        }

        .cart-item {
            display: flex;
            gap: 20px;
            padding: 20px;
            border: 1px solid var(--border);
            border-radius: 12px;
            margin-bottom: 16px;
            align-items: center;
        }

        .cart-item-image {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 32px;
        }

        .cart-item-info {
            flex: 1;
        }

        .cart-item-name {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 4px;
        }

        .cart-item-price {
            font-size: 14px;
            color: var(--text-secondary);
        }

        .cart-item-actions {
            display: flex;
            flex-direction: column;
            gap: 12px;
            align-items: flex-end;
        }

        .remove-item-btn {
            background: var(--danger);
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 500;
            transition: all 0.2s;
        }

        .remove-item-btn:hover {
            background: #dc2626;
        }

        .cart-total {
            background: var(--bg);
            padding: 24px;
            border-radius: 12px;
            margin-top: 24px;
        }

        .total-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 12px;
            font-size: 16px;
        }

        .total-row.grand-total {
            font-size: 24px;
            font-weight: 700;
            color: var(--primary);
            padding-top: 12px;
            border-top: 2px solid var(--border);
        }

        .checkout-btn {
            width: 100%;
            padding: 16px;
            background: var(--success);
            color: white;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            margin-top: 16px;
            transition: all 0.2s;
        }

        .checkout-btn:hover {
            background: #059669;
        }

        .empty-cart {
            text-align: center;
            padding: 60px 20px;
            color: var(--text-secondary);
        }

        .empty-cart-icon {
            font-size: 64px;
            margin-bottom: 16px;
        }
    </style>
</head>
<body>
    <div class="shop-container">
        <div class="shop-header">
            <div>
                <h1>🛒 Tienda de Productos</h1>
                <small style="color: var(--text-secondary);">Bienvenido, <%= user.getNombreCompleto() %></small>
            </div>
            <div style="display: flex; gap: 12px;">
                <a href="<%= user.esAdministrador() ? "admin.jsp" : "index.jsp" %>" 
                   style="padding: 10px 20px; background: var(--surface); border: 1px solid var(--border); border-radius: 10px; text-decoration: none; color: var(--text); font-weight: 500; font-size: 14px;">
                    ← Volver
                </a>
                <button class="cart-button" onclick="abrirCarrito()">
                    🛒 Carrito
                    <% if (itemsCarrito > 0) { %>
                    <span class="cart-badge"><%= itemsCarrito %></span>
                    <% } %>
                </button>
            </div>
        </div>

        <div class="search-bar">
            <input type="text" id="busqueda" placeholder="Buscar productos..." 
                   value="<%= busqueda != null ? busqueda : "" %>">
            <select id="categoria">
                <option value="TODAS">Todas las categorías</option>
                <% for (String cat : categorias) { %>
                <option value="<%= cat %>" <%= cat.equals(categoriaFiltro) ? "selected" : "" %>><%= cat %></option>
                <% } %>
            </select>
            <button class="cart-button" onclick="filtrar()">Buscar</button>
        </div>

        <div class="products-grid">
            <% for (Producto p : productos) { %>
            <div class="product-card">
                <div class="product-image">📦</div>
                <div class="product-name"><%= p.getNombre() %></div>
                <div class="product-category"><%= p.getCategoria() %></div>
                <div class="product-price">$<%= String.format("%.2f", p.getPrecio()) %></div>
                <div class="product-stock <%= p.getCantidad() == 0 ? "stock-out" : p.getCantidad() < 10 ? "stock-low" : "stock-available" %>">
                    <% if (p.getCantidad() == 0) { %>
                        ❌ Agotado
                    <% } else if (p.getCantidad() < 10) { %>
                        ⚠️ Solo <%= p.getCantidad() %> disponibles
                    <% } else { %>
                        ✅ <%= p.getCantidad() %> disponibles
                    <% } %>
                </div>
                
                <div class="quantity-selector">
                    <button class="quantity-btn" onclick="cambiarCantidad('<%= p.getNombre() %>', -1)">−</button>
                    <input type="number" id="qty-<%= p.getNombre().hashCode() %>" class="quantity-input" value="1" min="1" max="<%= p.getCantidad() %>">
                    <button class="quantity-btn" onclick="cambiarCantidad('<%= p.getNombre() %>', 1)">+</button>
                </div>
                
                <button class="add-to-cart-btn" onclick="agregarAlCarrito('<%= p.getNombre() %>', <%= p.getPrecio() %>, <%= p.getCantidad() %>)"
                        <%= p.getCantidad() == 0 ? "disabled" : "" %>>
                    Agregar al Carrito
                </button>
            </div>
            <% } %>
            
            <% if (productos.isEmpty()) { %>
            <div style="grid-column: 1/-1; text-align: center; padding: 60px; color: var(--text-secondary);">
                <div style="font-size: 64px; margin-bottom: 16px;">📭</div>
                <h3>No se encontraron productos</h3>
                <p>Intenta con otra búsqueda o categoría</p>
            </div>
            <% } %>
        </div>
    </div>

    <!-- Modal Carrito -->
    <div id="modalCarrito" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>🛒 Mi Carrito</h2>
                <button class="close-modal" onclick="cerrarCarrito()">×</button>
            </div>
            <div class="modal-body" id="carritoContenido">
                <div class="empty-cart">
                    <div class="empty-cart-icon">🛒</div>
                    <p>Cargando...</p>
                </div>
            </div>
        </div>
    </div>

    <script>
        function cambiarCantidad(nombre, cambio) {
            const inputId = 'qty-' + nombre.hashCode();
            const input = document.getElementById(inputId);
            let valor = parseInt(input.value) || 1;
            valor += cambio;
            
            if (valor < 1) valor = 1;
            if (valor > parseInt(input.max)) valor = parseInt(input.max);
            
            input.value = valor;
        }

        String.prototype.hashCode = function() {
            var hash = 0;
            for (var i = 0; i < this.length; i++) {
                var char = this.charCodeAt(i);
                hash = ((hash<<5)-hash)+char;
                hash = hash & hash;
            }
            return Math.abs(hash);
        };

        function agregarAlCarrito(nombre, precio, stockMax) {
            const inputId = 'qty-' + nombre.hashCode();
            const cantidad = parseInt(document.getElementById(inputId).value) || 1;
            
            if (cantidad > stockMax) {
                alert('No hay suficiente stock disponible');
                return;
            }
            
            fetch('CarritoServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: `accion=agregar&producto=${encodeURIComponent(nombre)}&cantidad=${cantidad}&precio=${precio}`
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('✅ Producto agregado al carrito');
                    location.reload();
                } else {
                    alert('❌ Error: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error al agregar al carrito');
            });
        }

        function abrirCarrito() {
            document.getElementById('modalCarrito').style.display = 'block';
            cargarCarrito();
        }

        function cerrarCarrito() {
            document.getElementById('modalCarrito').style.display = 'none';
        }

        function cargarCarrito() {
            fetch('CarritoServlet?accion=listar')
                .then(response => response.json())
                .then(data => {
                    mostrarCarrito(data);
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('carritoContenido').innerHTML = 
                        '<div class="empty-cart"><div class="empty-cart-icon">❌</div><p>Error al cargar el carrito</p></div>';
                });
        }

        function mostrarCarrito(data) {
            const contenido = document.getElementById('carritoContenido');
            
            if (!data.items || data.items.length === 0) {
                contenido.innerHTML = `
                    <div class="empty-cart">
                        <div class="empty-cart-icon">🛒</div>
                        <h3>Tu carrito está vacío</h3>
                        <p>Agrega productos para comenzar a comprar</p>
                    </div>
                `;
                return;
            }
            
            let html = '';
            data.items.forEach(item => {
                html += `
                    <div class="cart-item">
                        <div class="cart-item-image">📦</div>
                        <div class="cart-item-info">
                            <div class="cart-item-name">${item.producto}</div>
                            <div class="cart-item-price">$${item.precio.toFixed(2)} × ${item.cantidad} = $${(item.precio * item.cantidad).toFixed(2)}</div>
                        </div>
                        <div class="cart-item-actions">
                            <div style="font-size: 18px; font-weight: 700; color: var(--primary);">$${(item.precio * item.cantidad).toFixed(2)}</div>
                            <button class="remove-item-btn" onclick="eliminarDelCarrito('${item.producto}')">Eliminar</button>
                        </div>
                    </div>
                `;
            });
            
            html += `
                <div class="cart-total">
                    <div class="total-row">
                        <span>Subtotal:</span>
                        <span>$${data.total.toFixed(2)}</span>
                    </div>
                    <div class="total-row">
                        <span>Envío:</span>
                        <span>Gratis</span>
                    </div>
                    <div class="total-row grand-total">
                        <span>Total:</span>
                        <span>$${data.total.toFixed(2)}</span>
                    </div>
                    <button class="checkout-btn" onclick="irAlCheckout()">Proceder al Pago</button>
                </div>
            `;
            
            contenido.innerHTML = html;
        }

        function eliminarDelCarrito(producto) {
            if (!confirm('¿Eliminar este producto del carrito?')) return;
            
            fetch('CarritoServlet', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: `accion=eliminar&producto=${encodeURIComponent(producto)}`
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    cargarCarrito();
                    location.reload();
                } else {
                    alert('Error al eliminar');
                }
            });
        }

        function irAlCheckout() {
            window.location.href = 'checkout.jsp';
        }

        function filtrar() {
            const busqueda = document.getElementById('busqueda').value;
            const categoria = document.getElementById('categoria').value;
            window.location.href = `shop.jsp?busqueda=${encodeURIComponent(busqueda)}&categoria=${encodeURIComponent(categoria)}`;
        }

        // Cerrar modal al hacer clic fuera
        window.onclick = function(event) {
            const modal = document.getElementById('modalCarrito');
            if (event.target == modal) {
                cerrarCarrito();
            }
        }
    </script>
</body>
</html>