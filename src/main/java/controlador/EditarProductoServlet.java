package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;
import modelo.*;

import java.io.IOException;
import java.sql.*;

@WebServlet("/editar")
public class EditarProductoServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession sesion = request.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        String nombre = request.getParameter("nombre");
        if (nombre == null || nombre.trim().isEmpty()) {
            response.sendRedirect("productos");
            return;
        }
        
        nombre = nombre.trim();
        Producto producto = null;

        try (Connection conn = ConexionSQLite.conectar()){
            String sql = "SELECT * FROM productos WHERE TRIM(nombre) = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, nombre);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                producto = new Producto();
                producto.setNombre(rs.getString("nombre"));
                producto.setCantidad(rs.getInt("cantidad"));
                producto.setPrecio(rs.getDouble("precio"));
                producto.setCategoria(rs.getString("categoria"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        // ✅ CORRECIÓN: Cambiar "productos" por "producto"
        request.setAttribute("producto", producto);
        request.getRequestDispatcher("editar.jsp").forward(request, response);
    }

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
        
        // Validar parámetros
        String nombre = request.getParameter("nombre");
        String cantidadStr = request.getParameter("cantidad");
        String precioStr = request.getParameter("precio");
        String categoria = request.getParameter("categoria");
        
        if (nombre == null || cantidadStr == null || precioStr == null || categoria == null) {
            response.sendRedirect("productos");
            return;
        }
        
        try {
            Producto producto = new Producto();
            producto.setNombre(nombre.trim());
            producto.setCantidad(Integer.parseInt(cantidadStr));
            producto.setPrecio(Double.parseDouble(precioStr));
            producto.setCategoria(categoria.trim());

            try (Connection conn = ConexionSQLite.conectar()) {
                String sql = "UPDATE productos SET cantidad = ?, precio = ?, categoria = ? WHERE nombre = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);
                stmt.setInt(1, producto.getCantidad());
                stmt.setDouble(2, producto.getPrecio());
                stmt.setString(3, producto.getCategoria());
                stmt.setString(4, producto.getNombre());
                
                int filasActualizadas = stmt.executeUpdate();
                System.out.println("Filas actualizadas: " + filasActualizadas);
                
            } catch (SQLException e) {
                e.printStackTrace();
            }
        } catch (NumberFormatException e) {
            System.out.println("Error en formato de números: " + e.getMessage());
        }

        response.sendRedirect("productos");
    }
}