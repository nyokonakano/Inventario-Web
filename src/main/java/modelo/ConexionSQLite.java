package modelo;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexionSQLite {

    protected static final String URL = "jdbc:sqlite:C:/Users/motta/Downloads/inventario.db";

    public static Connection conectar() throws SQLException {
        try {
            Class.forName("org.sqlite.JDBC");
        } catch (ClassNotFoundException e) {
            System.out.println("ERROR: No se encontró el driver JDBC de SQLite.");
            e.printStackTrace();
        }

        return DriverManager.getConnection(URL);
    }
}
