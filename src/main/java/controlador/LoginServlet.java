package controlador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.*;

import java.io.IOException;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    // DATOS HARDCODEADOS (puedes luego hacer esto desde BD)
    protected final String USUARIO = "admin";
    protected final String CLAVE = "123";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String usuario = request.getParameter("usuario");
        String clave = request.getParameter("clave");

        if (USUARIO.equals(usuario) && CLAVE.equals(clave)) {
            // CREAR SESIÓN
            HttpSession sesion = request.getSession();
            sesion.setAttribute("usuario", usuario);
            response.sendRedirect("index.jsp");
        } else {
            // VOLVER A LOGIN CON MENSAJE
            response.sendRedirect("login.jsp?error=1");
        }
    }
}
