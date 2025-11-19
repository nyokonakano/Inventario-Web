package modelo;

import java.sql.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.List;
import java.util.ArrayList;

/**
 * Sistema de caché thread-safe para productos
 * Reduce consultas a la base de datos y mejora el rendimiento
 */
public class CacheManager {
    
    // Caché principal de productos (thread-safe)
    private static final ConcurrentHashMap<String, ProductoCache> cacheProductos = 
        new ConcurrentHashMap<>();
    
    // Tiempo de vida del caché en milisegundos (5 minutos)
    private static final long CACHE_TTL = 5 * 60 * 1000;
    
    // Executor para limpieza automática
    private static final ScheduledExecutorService cleanupExecutor = 
        Executors.newScheduledThreadPool(1);
    
    // Estadísticas
    private static long hits = 0;
    private static long misses = 0;
    
    /**
     * Clase interna para almacenar productos en caché con timestamp
     */
    private static class ProductoCache {
        Producto producto;
        long timestamp;
        
        ProductoCache(Producto producto) {
            this.producto = producto;
            this.timestamp = System.currentTimeMillis();
        }
        
        boolean esValido() {
            return (System.currentTimeMillis() - timestamp) < CACHE_TTL;
        }
    }
    
    static {
        // Iniciar limpieza automática cada 5 minutos
        iniciarLimpiezaAutomatica();
    }
    
    /**
     * Obtiene un producto del caché o de la BD
     */
    public static Producto obtenerProducto(String nombre) {
        // 1. Buscar en caché
        ProductoCache cached = cacheProductos.get(nombre);
        
        if (cached != null && cached.esValido()) {
            hits++;
            System.out.println("🎯 [CACHE HIT] Producto: " + nombre + 
                              " | Hits: " + hits + " | Miss: " + misses);
            return cached.producto;
        }
        
        // 2. Si no está en caché o expiró, buscar en BD
        misses++;
        System.out.println("💾 [CACHE MISS] Consultando BD para: " + nombre + 
                          " | Hits: " + hits + " | Miss: " + misses);
        
        Producto producto = consultarProductoBD(nombre);
        
        if (producto != null) {
            // Almacenar en caché
            cacheProductos.put(nombre, new ProductoCache(producto));
            System.out.println("💾 Producto agregado al caché: " + nombre);
        }
        
        return producto;
    }
    
    /**
     * Obtiene todos los productos (con caché selectivo)
     */
    public static List<Producto> obtenerTodosLosProductos() {
        List<Producto> productos = new ArrayList<>();
        
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "SELECT * FROM productos ORDER BY nombre";
            PreparedStatement stmt = conn.prepareStatement(sql);
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                String nombre = rs.getString("nombre");
                
                // Verificar si está en caché
                ProductoCache cached = cacheProductos.get(nombre);
                
                if (cached != null && cached.esValido()) {
                    productos.add(cached.producto);
                    hits++;
                } else {
                    // Crear producto desde BD
                    Producto p = new Producto();
                    p.setNombre(nombre);
                    p.setCantidad(rs.getInt("cantidad"));
                    p.setPrecio(rs.getDouble("precio"));
                    p.setCategoria(rs.getString("categoria"));
                    productos.add(p);
                    
                    // Agregar al caché
                    cacheProductos.put(nombre, new ProductoCache(p));
                    misses++;
                }
            }
            
            System.out.println("📋 Productos obtenidos: " + productos.size() + 
                              " | Cache hits: " + hits + " | Misses: " + misses);
            
        } catch (SQLException e) {
            System.err.println("❌ Error obteniendo productos: " + e.getMessage());
        }
        
        return productos;
    }
    
    /**
     * Consulta un producto directamente de la BD
     */
    private static Producto consultarProductoBD(String nombre) {
        try (Connection conn = ConexionMySQL.conectar()) {
            String sql = "SELECT * FROM productos WHERE nombre = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, nombre);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                Producto p = new Producto();
                p.setNombre(rs.getString("nombre"));
                p.setCantidad(rs.getInt("cantidad"));
                p.setPrecio(rs.getDouble("precio"));
                p.setCategoria(rs.getString("categoria"));
                return p;
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Error consultando producto: " + e.getMessage());
        }
        
        return null;
    }
    
    /**
     * Invalida el caché de un producto específico
     * Llamar después de actualizar/eliminar un producto
     */
    public static void invalidarProducto(String nombre) {
        ProductoCache removed = cacheProductos.remove(nombre);
        if (removed != null) {
            System.out.println("🗑️ [CACHE INVALIDADO] Producto: " + nombre);
        }
    }
    
    /**
     * Invalida todo el caché
     */
    public static void invalidarTodo() {
        int size = cacheProductos.size();
        cacheProductos.clear();
        hits = 0;
        misses = 0;
        System.out.println("🗑️ [CACHE LIMPIADO] " + size + " productos removidos");
    }
    
    /**
     * Actualiza un producto en el caché
     * Llamar después de editar un producto
     */
    public static void actualizarProducto(Producto producto) {
        cacheProductos.put(producto.getNombre(), new ProductoCache(producto));
        System.out.println("🔄 [CACHE ACTUALIZADO] Producto: " + producto.getNombre());
    }
    
    /**
     * Precarga productos frecuentes en el caché
     */
    public static void precargarProductosPopulares(int limite) {
        System.out.println("⚡ Precargando productos populares...");
        
        try (Connection conn = ConexionMySQL.conectar()) {
            // Productos más consultados (puedes ajustar el criterio)
            String sql = "SELECT * FROM productos ORDER BY cantidad DESC LIMIT ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, limite);
            ResultSet rs = stmt.executeQuery();
            
            int cargados = 0;
            while (rs.next()) {
                Producto p = new Producto();
                p.setNombre(rs.getString("nombre"));
                p.setCantidad(rs.getInt("cantidad"));
                p.setPrecio(rs.getDouble("precio"));
                p.setCategoria(rs.getString("categoria"));
                
                cacheProductos.put(p.getNombre(), new ProductoCache(p));
                cargados++;
            }
            
            System.out.println("✅ " + cargados + " productos precargados en caché");
            
        } catch (SQLException e) {
            System.err.println("❌ Error precargando productos: " + e.getMessage());
        }
    }
    
    /**
     * Limpia entradas expiradas del caché
     */
    private static void limpiarExpirados() {
        int removidos = 0;
        
        for (String key : cacheProductos.keySet()) {
            ProductoCache cached = cacheProductos.get(key);
            if (cached != null && !cached.esValido()) {
                cacheProductos.remove(key);
                removidos++;
            }
        }
        
        if (removidos > 0) {
            System.out.println("🧹 Limpieza de caché: " + removidos + " entradas expiradas removidas");
        }
    }
    
    /**
     * Inicia la limpieza automática periódica
     */
    private static void iniciarLimpiezaAutomatica() {
        cleanupExecutor.scheduleAtFixedRate(() -> {
            System.out.println("\n🧹 [SCHEDULED] Limpiando caché expirado...");
            limpiarExpirados();
        }, 5, 5, TimeUnit.MINUTES);
        
        System.out.println("⏰ Limpieza automática de caché iniciada (cada 5 minutos)");
    }
    
    /**
     * Obtiene estadísticas del caché
     */
    public static String getEstadisticas() {
        long total = hits + misses;
        double hitRate = total > 0 ? (hits * 100.0 / total) : 0;
        
        return String.format(
            "📊 Estadísticas de Caché:\n" +
            "   - Entradas en caché: %d\n" +
            "   - Cache hits: %d\n" +
            "   - Cache misses: %d\n" +
            "   - Hit rate: %.2f%%\n" +
            "   - TTL: %d minutos",
            cacheProductos.size(),
            hits,
            misses,
            hitRate,
            CACHE_TTL / 60000
        );
    }
    
    /**
     * Obtiene el tamaño del caché
     */
    public static int getSize() {
        return cacheProductos.size();
    }
    
    /**
     * Detiene el sistema de caché
     */
    public static void shutdown() {
        System.out.println("⏹️ Deteniendo CacheManager...");
        cleanupExecutor.shutdown();
        invalidarTodo();
        System.out.println("✅ CacheManager detenido");
    }
}