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

-- 51. Mostrar el top 5 de usuarios que más han pagado en total.
	SELECT
		CONCAT(us.nombre,' ',us.apellidos) as nombre,
		SUM(pg.monto_neto) AS total_Pagado
	FROM usuario us
	JOIN pagos pg ON pg.usuario_id = us.id
	WHERE pg.estado = 'PAGADO'
	GROUP BY us.id
	ORDER BY total_Pagado DESC
	LIMIT 5;
-- 52. Mostrar facturas con monto mayor a $1000.
	SELECT 
		numero_factura,
		fecha_emision,
		total AS Monto
	FROM facturas
	WHERE total > 1000;
-- 53. Listar pagos realizados después de la fecha de vencimiento.
	SELECT 
		pg.id,
		pg.monto_neto,
		pg.fecha_pago,
		fc.fecha_vencimiento
	FROM pagos pg
	JOIN facturas fc ON pg.factura_id = fc.id
	WHERE pg.fecha_pago > fc.fecha_vencimiento
		AND pg.estado = 'PAGADO';
-- 54. Calcular el total recaudado en el año actual.
	SELECT 
		YEAR(NOW()) AS ANIO_actual,
		SUM(monto_neto) AS total_recaudado
		FROM pagos
		WHERE estado = 'PAGADO'
			AND YEAR(fecha_pago) = YEAR(NOW());
-- 55. Mostrar facturas anuladas y su motivo.
	SELECT
		numero_factura,
		tipo_factura,
		total,
		estado,
		motivo_anulacion
	FROM facturas
	WHERE estado ='ANULADA';
-- 56. Mostrar usuarios con facturas pendientes mayores a $200.
	SELECT
		fc.usuario_id,
		CONCAT(us.nombre,' ',us.apellidos) as nombre,
		fc.numero_factura,
		fc.total,
		fc.estado
	FROM usuario us
	JOIN facturas fc ON fc.usuario_id = us.id
	WHERE fc.estado = 'PENDIENTE'
		AND fc.total > 200;
-- 57. Mostrar usuarios que han pagado más de una vez el mismo servicio.
	SELECT
	    sc.usuario_id,                          -- el usuario
	    CONCAT(us.nombre,' ',us.apellidos) AS nombre, -- nombre 
	    sc.servicio_id,                         -- el servicio contratado
	    COUNT(*) AS veces_pagado                -- cuántas veces aparece esa combinación usuario+servicio
	FROM servicios_contratados sc
	JOIN usuario us ON us.id = sc.usuario_id    -- para poder traer el nombre
	WHERE sc.estado = 'FACTURADO'               -- solo cuento contrataciones que efectivamente se pagaron/facturaron
	GROUP BY sc.usuario_id, sc.servicio_id      -- agrupo por la COMBINACIÓN usuario+servicio, no cada uno por separado
	HAVING COUNT(*) > 1;
-- 58. Listar ingresos por cada método de pago.
		SELECT 
			mt.id,
			mt.nombre AS nombre_metodoPago,
			SUM(pg.monto_neto) AS ingreso_total
			FROM metodos_pago mt
			JOIN pagos pg ON pg.metodo_pago_id = mt.id
			WHERE pg.estado = 'PAGADO'
			GROUP BY mt.id
-- 59. Mostrar facturación acumulada por empresa.
	SELECT
		em.nombre AS nombre_empresa,
		SUM(fc.total) AS total
	FROM empresas em
	JOIN facturas fc ON em.id = fc.empresa_id
	GROUP BY em.nombre
-- 60. Mostrar ingresos netos por mes del último año.
	SELECT
		YEAR(fecha_pago) AS ANIO,
		MONTH(fecha_pago) AS MES,
		SUM(monto_neto) AS total_ingresos
	FROM pagos
	WHERE fecha_pago >= CURDATE() - INTERVAL 1 YEAR -- mi fecha actual - un año
		AND estado = 'PAGADO'
	GROUP BY YEAR(fecha_pago), MONTH(fecha_pago);			

-- 61. Listar todos los accesos registrados hoy.
	SELECT
		id,             -- O el identificador del acceso
    	usuario_id,     -- Quién entró
    	fecha_hora,     -- A qué hora entró
    	estado
	FROM accesos
	WHERE estado= 'PERMITIDO' 
		AND DATE(fecha_hora) = CURDATE();
-- 62. Mostrar usuarios con más de 20 asistencias en el mes.
	SELECT
		usuario_id,
		COUNT(*) AS asistencias
		FROM accesos
		WHERE tipo_acceso = 'ENTRADA'
			AND estado= 'PERMITIDO'
			AND MONTH(fecha_hora) = MONTH(NOW()) 
			AND YEAR(fecha_hora) = YEAR(NOW())
		GROUP BY usuario_id
		HAVING asistencias > 20;
-- 63. Mostrar usuarios que no asistieron en la última semana.

	SELECT
	us.id AS usuario_id
	CONCAT(us.nombre,' ',us.apellidos) AS nombre
	FROM usuario us
	LEFT JOIN accesos ac ON us.id = ac.usuario_id AND ac.fecha_hora >= CURDATE() - INTERVAL 7 DAY
	WHERE ac.usuario_id IS NULL

-- 64. Calcular la asistencia promedio por día de la semana.

SELECT
    DAYNAME(sub.dia_exacto) AS dia_semana, 
    AVG(sub.total_ese_dia) AS promedio_asistencias
FROM (
    SELECT
        DATE(fecha_hora) AS dia_exacto,  - 
        COUNT(*) AS total_ese_dia
    FROM accesos
    WHERE tipo_acceso = 'ENTRADA'
    GROUP BY DATE(fecha_hora)
) AS sub
GROUP BY DAYNAME(sub.dia_exacto)
ORDER BY DAYOFWEEK(MIN(sub.dia_exacto));

-- 65. Mostrar los 10 usuarios más constantes (más asistencias)
SELECT
    ac.usuario_id,                              -- el usuario
    CONCAT(us.nombre,' ',us.apellidos) AS nombre, -- nombre completo, solo para mostrar
    COUNT(*) AS total_asistencias                -- cuántas entradas tiene cada usuario
FROM accesos ac
JOIN usuario us ON us.id = ac.usuario_id
WHERE ac.tipo_acceso = 'ENTRADA'                 -- solo entradas, para no duplicar con las salidas
GROUP BY ac.usuario_id                            -- un grupo por usuario
ORDER BY total_asistencias DESC                    -- de mayor a menor cantidad
LIMIT 10;                                          -- me quedo con los primeros 10

-- 66. Mostrar accesos fuera del horario permitido
SELECT
    ac.id,
    ac.usuario_id,
    ac.fecha_hora,
    TIME(ac.fecha_hora) AS hora_del_acceso        -- extraigo solo la hora, sin la fecha
FROM accesos ac
WHERE TIME(ac.fecha_hora) NOT BETWEEN '08:00:00' AND '20:00:00'; -- fuera del horario general del coworking

-- 67. Mostrar usuarios que accedieron sin membresía activa (rechazados).
	SELECT 
		us.id,
		CONCAT(us.nombre,' ',us.apellidos) as nombre,
		ac.estado
	FROM accesos ac
	JOIN usuario us ON ac.usuario_id = us.id
	WHERE ac.estado= 'RECHAZADO';


-- 68. Listar usuarios que solo acceden los fines de semana.
SELECT
    us.id AS usuario_id,                                          -- ID único del usuario
    CONCAT(us.nombre, ' ', us.apellidos) AS nombre                -- Nombre completo para visualización
FROM usuario us
JOIN accesos ac ON us.id = ac.usuario_id                          -- Relacionamos con sus registros de acceso
GROUP BY us.id, us.nombre, us.apellidos                          -- Agrupamos por usuario para analizar su historial completo
HAVING SUM(
    CASE 
        -- DAYOFWEEK devuelve: 1=Domingo, 2=Lunes, 3=Martes, 4=Miércoles, 5=Jueves, 6=Viernes, 7=Sábado
        -- Si el acceso fue en un día de semana laboral (Lunes a Viernes)...
        WHEN DAYOFWEEK(ac.fecha_hora) IN (2, 3, 4, 5, 6) THEN 1 
        -- Si fue en fin de semana (Sábado o Domingo)...
        ELSE 0 
    END
) = 0; -- Exigimos que la suma de accesos en días hábiles sea 0 (es decir, nunca fue entre lunes y viernes)


-- 69. Mostrar usuarios que accedieron más de 2 veces en el mismo día.
SELECT 
    us.id AS usuario_id,
    CONCAT(us.nombre,' ',us.apellidos) AS nombre,
    COUNT(ac.usuario_id) AS ingresos
FROM usuario us
JOIN accesos ac ON us.id = ac.usuario_id
WHERE ac.estado = 'PERMITIDO'
    AND DATE(ac.fecha_hora) = CURDATE()
GROUP BY us.id
HAVING ingresos > 2;
-- 70. Mostrar el total de accesos diarios en el último mes.

SELECT
    DATE(ac.fecha_hora) AS fecha,                        -- Extraemos solo la parte de la fecha (YYYY-MM-DD)
    COUNT(*) AS total_accesos                           -- Contamos el número total de registros de ese día
FROM accesos ac
WHERE ac.fecha_hora >= NOW() - INTERVAL 1 MONTH         -- Filtramos para que solo tome los registros del último mes (últimos 30 días)
GROUP BY DATE(ac.fecha_hora)                            -- Agrupamos los resultados día por día
ORDER BY fecha DESC;                                    -- Ordenamos de la fecha más reciente a la más antigua


-- 71. Mostrar usuarios que han accedido pero no tienen reservas.
SELECT DISTINCT
    us.id AS usuario_id,
    CONCAT(us.nombre, ' ', us.apellidos) AS nombre
FROM usuario us
JOIN accesos ac ON us.id = ac.usuario_id
WHERE NOT EXISTS (
    SELECT 1 
    FROM reservas re 
    WHERE re.usuario_id = us.id
);
-- 72. Mostrar los días con más concurrencia en el coworking.
SELECT
    DAYNAME(ac.fecha_hora) AS dia_semana,                      -- Nombre del día (Monday, Tuesday, etc.)
    COUNT(*) AS total_accesos                                  -- Total de accesos registrados en ese día de la semana
FROM accesos ac
WHERE ac.tipo_acceso = 'ENTRADA'                               -- Contamos solo las entradas para medir concurrencia real
GROUP BY DAYNAME(ac.fecha_hora), DAYOFWEEK(ac.fecha_hora)      -- Agrupamos por el nombre y el número del día
ORDER BY total_accesos DESC;                                   -- Ordenamos de mayor a menor concurrencia

-- 73. Mostrar usuarios que entraron pero no registraron salida.
SELECT 
    us.id AS usuario_id,
    CONCAT(us.nombre, ' ', us.apellidos) AS nombre,
    ult_acceso.fecha_hora AS fecha_hora_entrada                -- Fecha y hora en la que entró
FROM usuario us
JOIN (
    -- Subconsulta para obtener el último acceso de cada usuario
    SELECT ac1.usuario_id, ac1.tipo_acceso, ac1.fecha_hora
    FROM accesos ac1
    WHERE ac1.fecha_hora = (
        SELECT MAX(ac2.fecha_hora)
        FROM accesos ac2
        WHERE ac2.usuario_id = ac1.usuario_id
    )
) AS ult_acceso ON us.id = ult_acceso.usuario_id
WHERE ult_acceso.tipo_acceso = 'ENTRADA';                     -- Si el último registro es ENTRADA, no ha registrado salida

-- 74. Mostrar accesos de usuarios con membresía vencida.

SELECT 
    ac.id AS acceso_id,
    ac.usuario_id,
    CONCAT(us.nombre, ' ', us.apellidos) AS nombre_usuario,
    ac.fecha_hora AS fecha_hora_acceso,
    m.fecha_fin AS fecha_vencimiento_membresia
FROM accesos ac
JOIN usuario us ON ac.usuario_id = us.id
JOIN membresia_usuario m ON us.id = m.usuario_id
WHERE ac.fecha_hora > m.fecha_fin
    AND m.estado = 'VENCIDA'
ORDER BY ac.fecha_hora DESC;

-- 75. Mostrar accesos de usuarios corporativos por empresa.

SELECT
    em.nombre AS nombre_empresa,
    us.id AS usuario_id,
    CONCAT(us.nombre, ' ', us.apellidos) AS nombre_empleado,
    ac.fecha_hora AS fecha_hora_acceso,
    ac.tipo_acceso,
    ac.estado
FROM accesos ac
JOIN usuario us ON ac.usuario_id = us.id
JOIN empresas em ON us.empresa_id = em.id
ORDER BY em.nombre ASC, ac.fecha_hora DESC;

-- 76. Mostrar clientes que nunca han usado el coworking a pesar de pagar membresía.

SELECT 
    us.id AS usuario_id,
    CONCAT(us.nombre, ' ', us.apellidos) AS nombre_cliente,
    m.fecha_inicio AS inicio_membresia,
    m.fecha_fin AS fin_membresia
FROM usuario us
JOIN membresia_usuario m ON us.id = m.usuario_id
LEFT JOIN accesos ac ON us.id = ac.usuario_id
    AND ac.tipo_acceso = 'ENTRADA'
    AND ac.estado = 'PERMITIDO'
WHERE ac.usuario_id IS NULL;

-- 77. Mostrar accesos rechazados por intentos con QR inválido.
SELECT 
    ac.id AS acceso_id,
    ac.usuario_id,
    CONCAT(us.nombre, ' ', us.apellidos) AS nombre_usuario,
    ac.fecha_hora,
    ac.tipo_acceso,
    ac.motivo_rechazo
FROM accesos ac
LEFT JOIN usuario us ON ac.usuario_id = us.id
WHERE ac.estado = 'RECHAZADO' 
  AND (ac.motivo_rechazo LIKE '%QR%' OR ac.motivo_rechazo LIKE '%inv%lido%')
ORDER BY ac.fecha_hora DESC;

-- 78. Mostrar accesos promedio por usuario.
SELECT 
    AVG(sub.total_accesos) AS promedio_accesos_por_usuario    -- Calculamos el promedio de los totales obtenidos
FROM (
    -- Subconsulta: Cuenta el total de accesos permitidos de cada usuario individual
    SELECT 
        usuario_id, 
        COUNT(*) AS total_accesos
    FROM accesos
    WHERE tipo_acceso = 'ENTRADA'                             -- Contamos solo las entradas para medir asistencias reales
      AND estado = 'PERMITIDO'                                -- Solo accesos que sí se concretaron con éxito
    GROUP BY usuario_id
) AS sub;                                                     -- Le asignamos un alias obligatorio a la subconsulta
	
-- 79. Identificar usuarios que asisten más en la mañana.
SELECT 
    us.id AS usuario_id,
    CONCAT(us.nombre, ' ', us.apellidos) AS nombre,
    COUNT(*) AS total_asistencias,                              -- Cuántas veces ha asistido en total
    SUM(CASE WHEN TIME(ac.fecha_hora) BETWEEN '06:00:00' AND '11:59:59' THEN 1 ELSE 0 END) AS asistencias_manana
FROM usuario us
JOIN accesos ac ON us.id = ac.usuario_id
WHERE ac.tipo_acceso = 'ENTRADA'                                -- Solo medimos entradas reales
  AND ac.estado = 'PERMITIDO'
GROUP BY us.id, us.nombre, us.apellidos
-- Filtramos con HAVING para quedarnos solo con quienes van principalmente en la mañana (> 50% de sus visitas)
HAVING asistencias_manana > (total_asistencias / 2)
ORDER BY asistencias_manana DESC;                               -- Ordenamos para ver primero a los más madrugadores

-- 80. Identificar usuarios que asisten más en la noche.
SELECT 
    us.id AS usuario_id,
    CONCAT(us.nombre, ' ', us.apellidos) AS nombre,
    COUNT(*) AS total_asistencias,                              -- Total de asistencias del usuario
    SUM(CASE WHEN TIME(ac.fecha_hora) >= '18:00:00' THEN 1 ELSE 0 END) AS asistencias_noche  -- Entradas a partir de las 6 PM
FROM usuario us
JOIN accesos ac ON us.id = ac.usuario_id
WHERE ac.tipo_acceso = 'ENTRADA'                                -- Solo entradas permitidas
  AND ac.estado = 'PERMITIDO'
GROUP BY us.id, us.nombre, us.apellidos
-- Filtramos para quedarnos con quienes hacen más de la mitad de sus visitas en horario nocturno
HAVING asistencias_noche > (total_asistencias / 2)
ORDER BY asistencias_noche DESC;                               -- Ordenamos para ver a los más nocturnos primero


-- Consultas Avanzadas (20 con subconsultas, joins)
-- 81. Mostrar los usuarios con el mayor gasto acumulado (subconsulta con SUM;).

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    (SELECT SUM(monto) FROM pagos WHERE usuario_id = u.id AND estado = 'PAGADO') AS gasto_total
FROM usuario u
WHERE u.id IN (SELECT usuario_id FROM pagos WHERE estado = 'PAGADO' GROUP BY usuario_id)
ORDER BY gasto_total DESC
LIMIT 1;

-- 82. Mostrar los espacios más ocupados considerando reservas confirmadas y asistencias reales.

SELECT
    e.id,
    e.codigo,
    e.nombre,
    COUNT(r.id) AS total_reservas_asistidas
FROM espacios e
JOIN reservas r ON e.id = r.espacio_id
JOIN reservas_clientes rc ON r.id = rc.reserva_id
WHERE r.estado = 'CONFIRMADA'
    AND rc.asistio = TRUE
GROUP BY e.id, e.codigo, e.nombre
ORDER BY total_reservas_asistidas DESC;

-- 83. Calcular el promedio de ingresos por usuario usando subconsultas.

SELECT
    (SELECT SUM(monto) 
	FROM pagos 
	WHERE estado = 'PAGADO') / (SELECT COUNT(DISTINCT id) FROM usuario) AS promedio_ingreso_por_usuario;

-- 84. Listar usuarios que tienen reservas activas y facturas pendientes.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre
FROM usuario u
JOIN reservas r ON u.id = r.usuario_id
JOIN facturas f ON u.id = f.usuario_id
WHERE r.estado IN ('PENDIENTE', 'CONFIRMADA')
    AND f.estado IN ('PENDIENTE', 'PARCIAL');

-- 85. Mostrar empresas cuyos empleados generan más del 20% de los ingresos totales.

SELECT
    e.nombre,
    SUM(p.monto) AS total_empresa,
    (SUM(p.monto) / (SELECT SUM(monto) FROM pagos WHERE estado = 'PAGADO')) * 100 AS porcentaje_contribucion
FROM empresas e
JOIN usuario u ON e.id = u.empresa_id
JOIN pagos p ON u.id = p.usuario_id
WHERE p.estado = 'PAGADO'
GROUP BY e.id, e.nombre
HAVING porcentaje_contribucion > 20.00;


-- 86. Mostrar el top 5 de usuarios que más usan servicios adicionales.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    COUNT(sc.id) AS total_servicios
FROM usuario u
JOIN servicios_contratados sc ON u.id = sc.usuario_id
WHERE sc.estado = 'USADO'
GROUP BY u.id, u.nombre, u.apellidos
ORDER BY total_servicios DESC
LIMIT 5;

-- 87. Mostrar reservas que generaron facturas mayores al promedio.

SELECT
    r.codigo,
    f.numero_factura,
    f.total
FROM reservas r
JOIN detalle_factura df ON r.id = df.referencia_id
    AND df.referencia_tipo = 'RESERVA'
JOIN facturas f ON df.factura_id = f.id
WHERE f.total > (SELECT AVG(total) FROM facturas WHERE tipo_factura = 'RESERVA');

-- 88. Calcular el porcentaje de ocupación global del coworking por mes.

SELECT
    DATE_FORMAT(r.fecha_reserva, '%Y-%m') AS mes,
    SUM(r.duracion_horas) AS horas_reservadas,
    (SUM(r.duracion_horas) / ((SELECT COUNT(id) FROM espacios) * 360.0)) * 100 AS porcentaje_ocupacion
FROM reservas r
WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
GROUP BY mes
ORDER BY mes ASC;

-- 89. Mostrar usuarios que tienen más horas de reserva que el promedio del sistema.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    SUM(r.duracion_horas) AS total_horas
FROM usuario u
JOIN reservas r ON u.id = r.usuario_id
GROUP BY u.id, u.nombre, u.apellidos
HAVING total_horas > (SELECT AVG(total_horas_usuario) FROM (SELECT usuario_id, SUM(duracion_horas) AS total_horas_usuario FROM reservas GROUP BY usuario_id) AS sub);

-- 90. Mostrar el top 3 de salas más usadas en el último trimestre.

SELECT
    e.id,
    e.codigo,
    e.nombre,
    COUNT(r.id) AS total_usos
FROM espacios e
JOIN reservas r ON e.id = r.espacio_id
JOIN tipos_espacios te ON e.tipo_espacio_id = te.id
WHERE te.nombre IN ('Sala de Reuniones', 'Sala de Eventos')
    AND r.fecha_reserva >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
GROUP BY e.id, e.codigo, e.nombre
ORDER BY total_usos DESC
LIMIT 3;

-- 91. Calcular ingresos promedio por tipo de membresía (agrupado con AVG).

SELECT
    tm.nombre AS membresia,
    AVG(mu.precio_pagado) AS precio_promedio_pagado
FROM tipos_membresia tm
JOIN membresia_usuario mu ON tm.id = mu.tipo_membresia_id
GROUP BY tm.id, tm.nombre;

-- 92. Mostrar usuarios que pagan solo con un método de pago (subconsulta).

SELECT
    mp.codigo AS mp_codigo,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre
FROM usuario u
JOIN (
    SELECT usuario_id, MIN(metodo_pago_id) AS metodo_pago_id
    FROM pagos
    WHERE estado = 'PAGADO'
    GROUP BY usuario_id
    HAVING COUNT(DISTINCT metodo_pago_id) = 1
) p ON u.id = p.usuario_id
JOIN metodos_pago mp ON p.metodo_pago_id = mp.id;

-- 93. Mostrar reservas canceladas por usuarios que nunca asistieron.

SELECT
    r.id,
    r.codigo,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre
FROM reservas r
JOIN usuario u ON r.usuario_id = u.id
WHERE r.estado = 'CANCELADA'
    AND u.id NOT IN (SELECT DISTINCT usuario_id FROM accesos WHERE estado = 'PERMITIDO');

-- 94. Mostrar facturas con pagos parciales y calcular saldo pendiente.

SELECT
    id,
    numero_factura,
    total,
    saldo_pendiente,
    (total - saldo_pendiente) AS total_pagado
FROM facturas
WHERE estado = 'PARCIAL';

-- 95. Calcular la facturación total de cada empresa y ordenarla de mayor a menor.

SELECT
    e.nombre AS empresa,
    SUM(f.total) AS total_facturado
FROM empresas e
LEFT JOIN usuario u ON e.id = u.empresa_id
LEFT JOIN facturas f ON u.id = f.usuario_id
GROUP BY e.id, e.nombre
ORDER BY total_facturado DESC;

-- 96. Identificar usuarios que superan en reservas al promedio de su empresa.

SELECT
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
    u.empresa_id,
    COUNT(r.id) AS reservas_usuario,
    (SELECT COUNT(r2.id) / COUNT(DISTINCT u2.id) FROM usuario u2 LEFT JOIN reservas r2 ON u2.id = r2.usuario_id WHERE u2.empresa_id = u.empresa_id) AS promedio_empresa
FROM usuario u
JOIN reservas r ON u.id = r.usuario_id
WHERE u.empresa_id IS NOT NULL
GROUP BY u.id, u.nombre, u.apellidos, u.empresa_id
HAVING reservas_usuario > promedio_empresa;

-- 97. Mostrar las 3 empresas con más empleados activos en el coworking.

SELECT
    e.nombre,
    COUNT(DISTINCT u.id) AS empleados_activos
FROM empresas e
JOIN usuario u ON e.id = u.empresa_id
JOIN membresia_usuario mu ON u.id = mu.usuario_id
WHERE mu.estado = 'ACTIVA'
GROUP BY e.id, e.nombre
ORDER BY empleados_activos DESC
LIMIT 3;

-- 98. Calcular el porcentaje de usuarios (tmb re cacorro el que lea esto) activos frente al total de registrados.

SELECT
    (COUNT(DISTINCT CASE WHEN mu.estado = 'ACTIVA' THEN u.id END) / COUNT(DISTINCT u.id)) * 100 AS porcentaje_activos
FROM usuario u
LEFT JOIN membresia_usuario mu ON u.id = mu.usuario_id;
	
-- 99. Mostrar ingresos mensuales acumulados con función de ventana (OVER).

SELECT
    DATE_FORMAT(fecha_pago, '%Y-%m') AS mes,
    SUM(monto) AS ingresos_mes,
    SUM(SUM(monto)) OVER (ORDER BY DATE_FORMAT(fecha_pago, '%Y-%m')) AS ingresos_acumulados
FROM pagos
WHERE estado = 'PAGADO'
GROUP BY mes;

-- 100. Mostrar usuarios con más de 10 reservas, más de $500 en facturación y membresía activa (con múltiples joins). abraza penes el q lea esto

SELECT
    u.id,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre
FROM usuario u
JOIN membresia_usuario mu ON u.id = mu.usuario_id
JOIN 
	(SELECT usuario_id, 
	COUNT(id) AS total_res 
	FROM reservas 
	GROUP BY usuario_id 
	HAVING total_res > 10) r_count ON u.id = r_count.usuario_id
JOIN (SELECT usuario_id, SUM(total) AS total_fact FROM facturas WHERE estado = 'PAGADA' GROUP BY usuario_id HAVING total_fact > 500.00) f_sum ON u.id = f_sum.usuario_id
WHERE mu.estado = 'ACTIVA';
