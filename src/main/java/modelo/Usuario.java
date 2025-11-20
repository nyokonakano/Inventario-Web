package modelo;

import java.sql.Timestamp;

public class Usuario {
    private int id;
    private String usuario;
    private String clave;
    private String nombreCompleto;
    private String email;
    private int rolId;
    private String rolNombre;
    private boolean activo;
    private Timestamp fechaCreacion;
    private Timestamp ultimoAcceso;
    
    // Constructores
    public Usuario() {}
    
    public Usuario(int id, String usuario, String nombreCompleto, String rolNombre) {
        this.id = id;
        this.usuario = usuario;
        this.nombreCompleto = nombreCompleto;
        this.rolNombre = rolNombre;
    }

    // Métodos de verificación de permisos
    public boolean esAdministrador() {
        return "ADMINISTRADOR".equalsIgnoreCase(rolNombre);
    }
    
    public boolean esUsuario() {
        return "USUARIO".equalsIgnoreCase(rolNombre);
    }
    
    public boolean puedeEliminar() {
        return esAdministrador();
    }
    
    public boolean puedeEditar() {
        return esAdministrador();
    }
    
    public boolean puedeAgregar() {
        return true; // Ambos roles pueden agregar
    }
    
    public boolean puedeVerInventario() {
        return true; // Ambos roles pueden ver
    }
    
    public boolean puedeGestionarUsuarios() {
        return esAdministrador();
    }

    // Getters y Setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getUsuario() {
        return usuario;
    }

    public void setUsuario(String usuario) {
        this.usuario = usuario;
    }

    public String getClave() {
        return clave;
    }

    public void setClave(String clave) {
        this.clave = clave;
    }

    public String getNombreCompleto() {
        return nombreCompleto;
    }

    public void setNombreCompleto(String nombreCompleto) {
        this.nombreCompleto = nombreCompleto;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public int getRolId() {
        return rolId;
    }

    public void setRolId(int rolId) {
        this.rolId = rolId;
    }

    public String getRolNombre() {
        return rolNombre;
    }

    public void setRolNombre(String rolNombre) {
        this.rolNombre = rolNombre;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }

    public Timestamp getFechaCreacion() {
        return fechaCreacion;
    }

    public void setFechaCreacion(Timestamp fechaCreacion) {
        this.fechaCreacion = fechaCreacion;
    }

    public Timestamp getUltimoAcceso() {
        return ultimoAcceso;
    }

    public void setUltimoAcceso(Timestamp ultimoAcceso) {
        this.ultimoAcceso = ultimoAcceso;
    }
}