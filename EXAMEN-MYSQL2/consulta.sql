USE coworking;
-- Crea una consulta SQL que muestre el nombre del usuario, el tipo de membresía y el total pagado por reservas de todos los usuarios que tengan una membresía activa.
-- La consulta debe incluir al menos una unión (JOIN) entre las tablas de usuarios, membresías, pagos y reservas.
-- Muestra solo a los usuarios cuyo total pagado por reservas sea mayor a 100 dólares o en cualquier coneda que se maneje en los registros.
-- Ordena los resultados del mayor al menor total pagado.
SELECT 
	CONCAT(u.nombre,' ',u.apellidos) AS NombreUsuario, -- Nombre del usuario
	mu.tipo_membresia_id AS TipoMembresia, -- Tipo membresia del usuario,
	mu.estado AS EstadoMembresia, -- Estado de la membresia para verificar si esta activo
	p.moneda AS TipoMoneda,  -- El tipo de moneda con el que el usuario realizo el pago
	SUM(r.precio_final) AS total_gastado -- Sumatoria de la cantidad del dinero gastado en las reservas
	FROM usuario u -- Tomamos datos de la tabla Usuario
	INNER JOIN membresia_usuario mu ON mu.usuario_id  = u.id -- Tomamos datos de la tabla membresia_usuario que hagan match
	INNER JOIN reservas r ON r.usuario_id = u.id -- Tomamos datos de la tabla reservas que hagan match
	INNER JOIN pagos p ON p.usuario_id = u.id -- Tomamos datos de la tabla Pagos que hagan match
	WHERE mu.estado = 'ACTIVA' -- Toma unicamente los usuarios con membresias activas
	GROUP BY NombreUsuario, TipoMembresia, EstadoMembresia, TipoMoneda -- Se agrupa los resultados por el id del usuario mas su nombre que ya se concateno arriba en el select
	HAVING total_gastado > 100 -- Se descarta a los usuarios que hayan gastado mas de 100 dolares o en la moneda en la que pagaron
	ORDER BY total_gastado DESC; -- Se ordena de mayor a menor de manera descendente
