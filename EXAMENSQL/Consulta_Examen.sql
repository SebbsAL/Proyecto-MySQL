-- Objetivo: Comprobar la capacidad de escribir consultas SQL correctas usando el modelo del sistema de coworking.
-- Enunciado:
-- Crea una consulta SQL que muestre el nombre del usuario, el tipo de membresía y el total pagado por reservas de todos los usuarios que tengan una membresía activa.
-- La consulta debe incluir al menos una unión (JOIN) entre las tablas de usuarios, membresías, pagos y reservas.
-- Muestra solo a los usuarios cuyo total pagado por reservas sea mayor a 100 dólares o en cualquier coneda que se maneje en los registros.
-- Ordena los resultados del mayor al menor total pagado.


use coworking;

SELECT
	us.id,
	CONCAT(us.nombre,' ',us.apellidos) AS Nombre_completo,
	tm.nombre AS tipo_membresia,
	SUM(re.precio_final) AS total_pagado
	FROM usuario us
	JOIN membresia_usuario mu ON mu.usuario_id = us.id
	JOIN tipos_membresia tm ON mu.tipo_membresia_id = tm.id
	JOIN reservas re ON  re.usuario_id = us.id
	WHERE mu.estado = 'ACTIVA'
	GROUP BY us.id, Nombre_completo, tm.nombre 
	HAVING  total_pagado > 100
	ORDER BY total_pagado DESC 
	 
	
