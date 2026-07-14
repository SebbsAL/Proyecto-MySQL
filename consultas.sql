-- ================================================
-- 100 consultas predefinidas, divididas en módulos
-- ================================================

-- Usuarios y Membresías (20)

-- 1. Listar todos los usuarios con su información básica.

SELECT
	CONCAT(u.nombre,' ',u.apellidos) AS nombre, -- concatenamos el nombre y el apellido como nombre
	u.fecha_nacimiento,
	u.identificacion,
	u.email,
	u.telefono,
	u.direccion
FROM usuario u -- los datos del select se van a selecionar de esta tabla
ORDER BY nombre ASC; -- se organizan por nombre en orden descendente. 

-- 2. Listar los usuarios con membresía activa.

SELECT
	CONCAT(u.nombre,' ',u.apellidos) AS nombre,
	mu.estado
FROM usuario u
INNER JOIN membresia_usuario mu ON u.id = mu.usuario_id
WHERE mu.estado = 'ACTIVA'
ORDER BY nombre ASC;

-- 3. Listar los usuarios cuya membresía está vencida.

SELECT
	CONCAT(u.nombre,' ',u.apellidos) AS nombre,
	mu.estado
FROM usuario u
INNER JOIN membresia_usuario mu ON u.id = mu.usuario_id
WHERE mu.estado = 'VENCIDA'
ORDER BY nombre;

-- 4. Listar los usuarios con membresía suspendida.

SELECT
	CONCAT(u.nombre,' ',u.apellidos) as nombre,
	mu.estado
FROM usuario u
INNER JOIN membresia_usuario mu ON u.id = mu.usuario_id
WHERE mu.estado = 'SUSPENDIDA'
ORDER BY nombre; 

-- 5. Contar cuántos usuarios tienen cada tipo de membresía.
SELECT 
	CONCAT (u.nombre,' ',u.apellidos) AS nombre,
	tm.nombre AS Tipo
FROM usuario u
INNER JOIN membresia_usuario mu ON u.id = mu.usuario_id
INNER JOIN tipos_membresia tm ON mu.tipo_membresia_id = tm.id
ORDER BY nombre;

-- 6. Mostrar el top 10 de usuarios con más antigüedad en el coworking.

SELECT
	CONCAT(u.nombre,' ',u.apellidos) AS nombre,
	mu.fecha_inicio as fecha
FROM usuario u
INNER JOIN membresia_usuario mu ON u.id = mu.usuario_id
ORDER BY fecha ASC
LIMIT 10;

-- 7. Listar usuarios que pertenecen a una empresa específica.

SELECT
	CONCAT (u.nombre, ' ',u.apellidos) AS nombre,
	e.nombre AS empresa
FROM usuario u
INNER JOIN empresas e ON e.id = u.empresa_id
ORDER BY empresa DESC;

-- 8. Contar cuántos usuarios están asociados a cada empresa.

SELECT
	e.nombre AS empresa,
	COUNT(u.id) as usuario
FROM empresas e
JOIN usuario u ON u.empresa_id = e.id
GROUP BY empresa;

-- 9. Mostrar usuarios que nunca han hecho una reserva.
-- la logica es  LEFT JOIN dice: "Tráeme todos los registros de la tabla izquierda 
-- (usuario) y emparéjalos con la tabla derecha (reservas) si es posible

SELECT
	CONCAT(u.nombre,' ',u.apellidos) AS nombre
FROM usuario u
LEFT JOIN reservas r ON u.id = r.usuario_id
WHERE r.id IS NULL
ORDER BY nombre;
	
-- 10. Mostrar usuarios con más de 5 reservas activas en el mes.

SELECT
    u.id,
    u.nombre,
    u.apellidos,
    COUNT(r.id) AS total_reservas
FROM usuario u
JOIN reservas r ON u.id = r.usuario_id
WHERE r.estado IN ('CONFIRMADA', 'PENDIENTE', 'COMPLETADA') -- Se incluye COMPLETADA
    AND YEAR(r.fecha_reserva) = YEAR(CURDATE())
    AND MONTH(r.fecha_reserva) = MONTH(CURDATE())
GROUP BY u.id, u.nombre, u.apellidos
HAVING total_reservas > 5;

-- 11. Calcular el promedio de edad de los usuarios.

SELECT
    AVG(TIMESTAMPDIFF(YEAR, fecha_nacimiento, CURDATE())) AS promedio_edad
FROM usuario
WHERE fecha_nacimiento IS NOT NULL;

-- 12. Listar usuarios que han cambiado de membresía más de 2 veces.

SELECT
    u.nombre,
    u.apellidos,
    COUNT(hcm.id) AS cambios
FROM usuario u
JOIN historial_cambio_membresia hcm ON u.id = hcm.usuario_id
GROUP BY u.id, u.nombre, u.apellidos
HAVING cambios > 2;

-- 13. Listar usuarios que han gastado más de $500 en reservas.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    SUM(r.precio_final) AS total_gastado
FROM usuario u
JOIN reservas r ON u.id = r.usuario_id
WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
GROUP BY u.id, nombre
HAVING total_gastado > 500;

-- 14. Mostrar usuarios que tienen tanto membresía como servicios adicionales.

SELECT
    DISTINCT u.id,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre
FROM usuario u
JOIN membresia_usuario mu ON u.id = mu.usuario_id
JOIN servicios_contratados sc ON u.id = sc.usuario_id
WHERE mu.estado = 'ACTIVA'
    AND sc.estado IN ('PENDIENTE', 'ACTIVO', 'USADO', 'FACTURADO')
ORDER BY nombre;

-- 15. Listar usuarios con membresía Premium y reservas activas.

SELECT
    DISTINCT u.id,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre
FROM usuario u
JOIN membresia_usuario mu ON u.id = mu.usuario_id
JOIN tipos_membresia tm ON mu.tipo_membresia_id = tm.id
JOIN reservas r ON u.id = r.usuario_id
WHERE tm.nombre = 'Premium'
    AND mu.estado = 'ACTIVA'
    AND r.estado IN ('PENDIENTE', 'CONFIRMADA');

-- 16. Mostrar usuarios con membresía Corporativa y su empresa.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    e.nombre AS empresa
FROM usuario u
JOIN empresas e ON u.empresa_id = e.id
JOIN membresia_usuario mu ON u.id = mu.usuario_id
JOIN tipos_membresia tm ON mu.tipo_membresia_id = tm.id
WHERE tm.nombre = 'Corporativa'
    AND mu.estado = 'ACTIVA';

-- 17. Identificar usuarios con membresía diaria que la han renovado más de 10 veces.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    mu.renovaciones
FROM usuario u
JOIN membresia_usuario mu ON u.id = mu.usuario_id
JOIN tipos_membresia tm ON mu.tipo_membresia_id = tm.id
WHERE tm.nombre = 'Diaria'
    AND mu.renovaciones > 10;

-- 18. Mostrar usuarios cuya membresía vence en los próximos 7 días.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    mu.fecha_fin
FROM usuario u
JOIN membresia_usuario mu ON u.id = mu.usuario_id
WHERE mu.estado = 'ACTIVA'
    AND mu.fecha_fin BETWEEN CURDATE()
    AND DATE_ADD(CURDATE(), INTERVAL 7 DAY);

-- 19. Listar usuarios que se registraron en el último mes.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    MIN(mu.fecha_contratacion) AS fecha_registro
FROM usuario u
JOIN membresia_usuario mu ON u.id = mu.usuario_id
GROUP BY u.id, u.nombre, u.apellidos
HAVING fecha_registro >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

-- 20. Mostrar usuarios que nunca han asistido al coworking (0 accesos).

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre
FROM usuario u
LEFT JOIN accesos a ON u.id = a.usuario_id
WHERE a.id IS NULL;

-- Espacios y Reservas (20)

-- 21. Listar todos los espacios disponibles con su capacidad.

SELECT
    codigo,
    nombre,
    capacidad,
    estado
FROM espacios
WHERE estado = 'DISPONIBLE';

-- 22. Listar reservas activas en el día actual.

SELECT * FROM reservas
WHERE fecha_reserva = CURDATE()
    AND estado IN ('PENDIENTE', 'CONFIRMADA');

-- 23. Mostrar reservas canceladas en el último mes.

SELECT * FROM reservas
WHERE estado = 'CANCELADA'
    AND fecha_creacion >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

-- 24. Listar reservas de salas de reuniones en horario pico (9 am – 11 am).

SELECT r.*
FROM reservas r
JOIN espacios e ON r.espacio_id = e.id
JOIN tipos_espacios te ON e.tipo_espacio_id = te.id
WHERE te.nombre = 'Sala de Reuniones'
    AND r.hora_inicio <= '11:00:00'
    AND r.hora_fin >= '09:00:00';

-- 25. Contar cuántas reservas se hacen por cada tipo de espacio.

SELECT
    te.nombre,
    COUNT(r.id) AS total_reservas
FROM tipos_espacios te
JOIN espacios e ON te.id = e.tipo_espacio_id
LEFT JOIN reservas r ON e.id = r.espacio_id
GROUP BY te.id, te.nombre;

-- 26. Mostrar el espacio más reservado del último mes.

SELECT
    e.id,
    e.codigo,
    e.nombre,
    COUNT(r.id) AS total_reservas
FROM espacios e
JOIN reservas r ON e.id = r.espacio_id
WHERE r.fecha_reserva >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY e.id, e.codigo, e.nombre
ORDER BY total_reservas DESC
LIMIT 1;

-- 27. Listar usuarios que más han reservado salas privadas.

SELECT
    u.id,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    COUNT(r.id) AS total_reservas
FROM usuario u
JOIN reservas r ON u.id = r.usuario_id
JOIN espacios e ON r.espacio_id = e.id
JOIN tipos_espacios te ON e.tipo_espacio_id = te.id
WHERE te.nombre = 'Oficina Privada'
GROUP BY u.id, u.nombre, u.apellidos
ORDER BY total_reservas DESC;

-- 28. Mostrar reservas que exceden la capacidad máxima del espacio.

SELECT
    r.id,
    r.codigo,
    e.nombre AS espacio,
    r.numero_asistentes,
    e.capacidad AS capacidad_maxima
FROM reservas r
JOIN espacios e ON r.espacio_id = e.id
WHERE r.numero_asistentes > e.capacidad;

-- 29. Listar espacios que no se han reservado en la última semana.

SELECT
    e.id,
    e.codigo,
    e.nombre
FROM espacios e
LEFT JOIN reservas r ON e.id = r.espacio_id
    AND r.fecha_reserva >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
WHERE r.id IS NULL;

-- 30. Calcular la tasa de ocupación promedio de cada espacio.

SELECT
    e.codigo,
    e.nombre,
    SUM(COALESCE(r.duracion_horas, 0)) AS horas_reservadas,
    (SUM(COALESCE(r.duracion_horas, 0)) / 360.0) * 100 AS tasa_ocupacion_porcentaje
FROM espacios e
LEFT JOIN reservas r ON e.id = r.espacio_id
    AND r.fecha_reserva >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY e.id, e.codigo, e.nombre;

-- 31. Mostrar reservas de más de 8 horas.

SELECT
    id,
    codigo,
    duracion_horas,
    motivo
FROM reservas
WHERE duracion_horas > 8.00;

-- 32. Identificar usuarios con más de 20 reservas en total.

SELECT
    u.id,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    COUNT(r.id) AS total_reservas
FROM usuario u
JOIN reservas r ON u.id = r.usuario_id
GROUP BY u.id, u.nombre, u.apellidos
HAVING total_reservas > 20;

-- 33. Mostrar reservas realizadas por empresas con más de 10 empleados.

SELECT
    r.id,
    r.codigo,
    e.nombre AS empresa,
    u.nombre AS usuario
FROM reservas r
JOIN usuario u ON r.usuario_id = u.id
JOIN empresas e ON u.empresa_id = e.id
WHERE e.id IN (SELECT empresa_id FROM usuario WHERE empresa_id IS NOT NULL GROUP BY empresa_id HAVING COUNT(id) > 10);


-- 34. Listar reservas que se solapan en horario.

SELECT
    r1.id AS reserva1_id,
    r1.codigo AS reserva1_codigo,
    r2.id AS reserva2_id,
    r2.codigo AS reserva2_codigo,
    r1.espacio_id,
    r1.fecha_reserva
FROM reservas r1
JOIN reservas r2 ON r1.espacio_id = r2.espacio_id
    AND r1.fecha_reserva = r2.fecha_reserva
    AND r1.id < r2.id
WHERE (r1.hora_inicio < r2.hora_fin AND r1.hora_fin > r2.hora_inicio)
    AND r1.estado != 'CANCELADA'
    AND r2.estado != 'CANCELADA';

-- 35. Listar reservas de fin de semana.

SELECT
    id,
    codigo,
    fecha_reserva
FROM reservas
WHERE DAYOFWEEK(fecha_reserva) IN (1, 7);

-- 36. Mostrar el porcentaje de ocupación por cada tipo de espacio.

SELECT
    te.nombre AS tipo_espacio,
    SUM(COALESCE(r.duracion_horas, 0)) AS horas_reservadas,
    (SUM(COALESCE(r.duracion_horas, 0)) / (COUNT(DISTINCT e.id) * 360.0)) * 100 AS porcentaje_ocupacion
FROM tipos_espacios te
JOIN espacios e ON te.id = e.tipo_espacio_id
LEFT JOIN reservas r ON e.id = r.espacio_id
    AND r.fecha_reserva >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY te.id, te.nombre;

-- 37. Mostrar la duración promedio de reservas por tipo de espacio.

SELECT
    te.nombre,
    AVG(r.duracion_horas) AS duracion_promedio
FROM tipos_espacios te
JOIN espacios e ON te.id = e.tipo_espacio_id
JOIN reservas r ON e.id = r.espacio_id
GROUP BY te.id, te.nombre;
	
-- 38. Mostrar reservas con servicios adicionales incluidos.

SELECT
    DISTINCT r.id,
    r.codigo,
    r.fecha_reserva
FROM reservas r
JOIN servicios_contratados sc ON r.id = sc.reserva_id;

-- 39. Listar usuarios que reservaron sala de eventos en los últimos 6 meses.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre
FROM usuario u
JOIN reservas r ON u.id = r.usuario_id
JOIN espacios e ON r.espacio_id = e.id
JOIN tipos_espacios te ON e.tipo_espacio_id = te.id
WHERE te.nombre = 'Sala de Eventos'
    AND r.fecha_reserva >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH);

-- 40. Identificar reservas realizadas y nunca asistidas.

SELECT
    r.id,
    r.codigo,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre
FROM reservas r
JOIN usuario u ON r.usuario_id = u.id
JOIN reservas_clientes rc ON r.id = rc.reserva_id
WHERE r.estado = 'CONFIRMADA'
    AND r.fecha_reserva < CURDATE()
    AND rc.asistio = FALSE;

-- Pagos y Facturación (20)
-- 41. Listar todos los pagos realizados con método tarjeta.

SELECT p.*
FROM pagos p
JOIN metodos_pago mp ON p.metodo_pago_id = mp.id
WHERE mp.nombre LIKE '%Tarjeta%';

-- 42. Listar pagos pendientes de usuarios.

SELECT
    f.numero_factura,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    f.total,
    f.saldo_pendiente,
    f.fecha_vencimiento
FROM facturas f
JOIN usuario u ON f.usuario_id = u.id
WHERE f.estado IN ('PENDIENTE', 'PARCIAL');

-- 43. Mostrar pagos cancelados en los últimos 3 meses.

SELECT *
FROM pagos
WHERE estado = 'CANCELADO'
    AND fecha_creacion >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH);

-- 44. Listar facturas generadas por membresías.

SELECT *
FROM facturas
WHERE tipo_factura = 'MEMBRESIA';

-- 45. Listar facturas generadas por reservas.

SELECT *
FROM facturas
WHERE tipo_factura = 'RESERVA';

-- 46. Mostrar el total de ingresos por membresías en el último mes.

SELECT
    SUM(p.monto) AS ingresos_membresias
FROM pagos p
JOIN facturas f ON p.factura_id = f.id
WHERE f.tipo_factura = 'MEMBRESIA'
    AND p.estado = 'PAGADO'
    AND p.fecha_pago >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

-- 47. Mostrar el total de ingresos por reservas en el último mes.

SELECT
    SUM(p.monto) AS ingresos_reservas
FROM pagos p
JOIN facturas f ON p.factura_id = f.id
WHERE f.tipo_factura = 'RESERVA'
    AND p.estado = 'PAGADO'
    AND p.fecha_pago >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

-- 48. Mostrar el total de ingresos por servicios adicionales.

SELECT
    SUM(df.total) AS total_ingresos_servicios
FROM detalle_factura df
JOIN facturas f ON df.factura_id = f.id
JOIN pagos p ON p.factura_id = f.id
WHERE df.referencia_tipo = 'SERVICIO'
    AND p.estado = 'PAGADO';

-- 49. Identificar usuarios que nunca han pagado con PayPal.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre
FROM usuario u
WHERE u.id NOT IN (SELECT DISTINCT p.usuario_id FROM pagos p JOIN metodos_pago mp ON p.metodo_pago_id = mp.id WHERE mp.nombre = 'PayPal' AND p.estado = 'PAGADO');


-- 50. Calcular el promedio de gasto por usuario.

SELECT
    AVG(total_gastado) AS promedio_gasto
FROM (SELECT usuario_id, SUM(monto) AS total_gastado FROM pagos WHERE estado = 'PAGADO' GROUP BY usuario_id) AS gastos_usuarios;
