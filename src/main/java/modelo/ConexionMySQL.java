package modelo;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexionMySQL {

    // Configuración de XAMPP MySQL por defecto
    private static final String URL = "jdbc:mysql://localhost:3306/inventario";
    private static final String USUARIO = "root";
    private static final String CONTRASENA = "";  // XAMPP no tiene contraseña por defecto
    
    // Configuración adicional para MySQL 8+
    private static final String PARAMETROS = "?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";

    /**
     * Establece conexión con MySQL de XAMPP
     * @return Connection objeto de conexión
     * @throws SQLException si hay error en la conexión
     */
    public static Connection conectar() throws SQLException {
        Connection conn = null;
        
        try {
            // Cargar el driver de MySQL
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            // Establecer conexión
            conn = DriverManager.getConnection(URL + PARAMETROS, USUARIO, CONTRASENA);
            
            System.out.println("✅ Conexión exitosa a MySQL (XAMPP)");
            
        } catch (ClassNotFoundException e) {
            System.err.println("❌ ERROR: No se encontró el driver JDBC de MySQL");
            System.err.println("   Asegúrate de tener mysql-connector-j en tu proyecto");
            e.printStackTrace();
            throw new SQLException("Driver MySQL no encontrado", e);
        } catch (SQLException e) {
            System.err.println("❌ ERROR de conexión a MySQL:");
            System.err.println("   - Verifica que MySQL esté corriendo en XAMPP");
            System.err.println("   - Verifica que la base de datos 'inventario' exista");
            System.err.println("   - Usuario: " + USUARIO);
            System.err.println("   - URL: " + URL);
            e.printStackTrace();
            throw e;
        }
        
        return conn;
    }
    
    /**
     * Prueba la conexión a la base de datos
     * @return true si la conexión es exitosa
     */
    public static boolean probarConexion() {
        try (Connection conn = conectar()) {
            return conn != null && !conn.isClosed();
        } catch (SQLException e) {
            return false;
        }
    }
}