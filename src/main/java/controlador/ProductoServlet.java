package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/productos")
public class ProductoServlet extends HttpServlet{
    
    // GET para mostrar los productos
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException{
        
        // Configurar codificación
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        List<Producto> lista = new ArrayList<>();
        String busqueda = request.getParameter("busqueda");
        
        try (Connection conn = ConexionSQLite.conectar()) {
            PreparedStatement stmt;
            if (busqueda != null && !busqueda.trim().isEmpty()) {
                String sql = "SELECT * FROM productos WHERE LOWER(nombre) LIKE ? OR LOWER(categoria) LIKE ?";
                stmt = conn.prepareStatement(sql);
                String termino = "%" + busqueda.toLowerCase().trim() + "%";
                stmt.setString(1, termino);
                stmt.setString(2, termino);
            } else {
                String sql = "SELECT * FROM productos ORDER BY nombre";
                stmt = conn.prepareStatement(sql);
            }

            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                Producto p = new Producto();
                p.setNombre(rs.getString("nombre"));
                p.setCantidad(rs.getInt("cantidad"));
                p.setPrecio(rs.getDouble("precio"));
                p.setCategoria(rs.getString("categoria"));
                lista.add(p);
            }

        } catch (SQLException e) {
            System.out.println("Error al consultar productos: " + e.getMessage());
            e.printStackTrace();
        }

        request.setAttribute("listaProductos", lista);
        request.getRequestDispatcher("inventario.jsp").forward(request, response);
    }
    
    // POST para agregar/eliminar productos
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Configurar codificación
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");
        
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String accion = request.getParameter("accion");
        System.out.println("Acción: " + accion);

        if ("eliminar".equals(accion)) {
            String nombreEliminar = request.getParameter("nombre");
            
            if (nombreEliminar == null || nombreEliminar.trim().isEmpty()) {
                response.sendRedirect("productos");
                return;
            }
            
            System.out.println("Producto a eliminar: " + nombreEliminar);

            try (Connection conn = ConexionSQLite.conectar()) {
                String sql = "DELETE FROM productos WHERE nombre = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setString(1, nombreEliminar.trim());
                int filas = stmt.executeUpdate();
                System.out.println("Filas eliminadas: " + filas);
            } catch (SQLException e) {
                System.out.println("Error al eliminar producto: " + e.getMessage());
                e.printStackTrace();
            }
            
            response.sendRedirect("productos");
            
        } else {
            //agregar
            String nombre = request.getParameter("nombre");
            String cantidadStr = request.getParameter("cantidad");
            String precioStr = request.getParameter("precio");
            String categoria = request.getParameter("categoria");
            
            //validar
            if (nombre == null || cantidadStr == null || precioStr == null || categoria == null ||
                nombre.trim().isEmpty() || categoria.trim().isEmpty()) {
                response.sendRedirect("index.jsp?error=datos_incompletos");
                return;
            }

            System.out.println("Nombre recibido: " + nombre);
            System.out.println("Cantidad recibida: " + cantidadStr);
            System.out.println("Precio recibido: " + precioStr);
            System.out.println("Categoría recibida: " + categoria);

            try {
                int cantidad = Integer.parseInt(cantidadStr);
                double precio = Double.parseDouble(precioStr);
                
                if (cantidad < 0 || precio < 0) {
                    response.sendRedirect("index.jsp?error=valores_negativos");
                    return;
                }

                Producto producto = new Producto();
                producto.setNombre(nombre.trim());
                producto.setCantidad(cantidad);
                producto.setPrecio(precio);
                producto.setCategoria(categoria.trim());

                try (Connection conn = ConexionSQLite.conectar()) {
                    // Verificar si el producto ya existe
                    String sqlCheck = "SELECT COUNT(*) FROM productos WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(?))";
                    PreparedStatement stmtCheck = conn.prepareStatement(sqlCheck);
                    stmtCheck.setString(1, producto.getNombre());
                    ResultSet rsCheck = stmtCheck.executeQuery();
                    
                    if (rsCheck.next() && rsCheck.getInt(1) > 0) {
                        response.sendRedirect("index.jsp?error=producto_existe");
                        return;
                    }
                    
                    String sql = "INSERT INTO productos(nombre, cantidad, precio, categoria) VALUES (?, ?, ?, ?)";
                    PreparedStatement stmt = conn.prepareStatement(sql);
                    stmt.setString(1, producto.getNombre());
                    stmt.setInt(2, producto.getCantidad());
                    stmt.setDouble(3, producto.getPrecio());
                    stmt.setString(4, producto.getCategoria());
                    stmt.executeUpdate();
                    System.out.println("Producto insertado correctamente.");
                    
                } catch (SQLException e) {
                    System.out.println("ERROR al insertar producto: " + e.getMessage());
                    e.printStackTrace();
                    response.sendRedirect("index.jsp?error=base_datos");
                    return;
                }
                
                // mensaje de conexion
                response.sendRedirect("index.jsp?mensaje=agregado");
                
            } catch (NumberFormatException e) {
                System.out.println("Error en formato de números: " + e.getMessage());
                response.sendRedirect("index.jsp?error=formato_numeros");
            }
        }
    }
}