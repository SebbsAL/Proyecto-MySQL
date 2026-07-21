-- Objetivo: Comprobar la capacidad de escribir consultas SQL correctas usando el modelo del sistema de coworking.
-- Enunciado:
-- Crea una consulta SQL que muestre el nombre del usuario, el tipo de membresía y el total pagado por reservas de todos los usuarios que tengan una membresía activa.
-- La consulta debe incluir al menos una unión (JOIN) entre las tablas de usuarios, membresías, pagos y reservas.
-- Muestra solo a los usuarios cuyo total pagado por reservas sea mayor a 100 dólares o en cualquier coneda que se maneje en los registros.
-- Ordena los resultados del mayor al menor total pagado.


use coworking;

SELECT
	us.id, -- traigo el id para hacer la consulta mas profesional
	CONCAT(us.nombre,' ',us.apellidos) AS Nombre_completo, -- concateno el nombre y el apellido pues para tener el nombre completo
	tm.nombre AS tipo_membresia, -- muestro el tipo de membresia
	SUM(re.precio_final) AS total_pagado -- y usando SUM extraigo de reservas el precio final de la reserva 
	FROM usuario us
	JOIN membresia_usuario mu ON mu.usuario_id = us.id -- conecto la tabla membresia_usuario con usuario por medio del id de la tabla usuario 
	JOIN tipos_membresia tm ON mu.tipo_membresia_id = tm.id -- luego conecto la tabla tipos_membresia con membresia_usuario por medio de tipo_membresia_id
	JOIN reservas re ON  re.usuario_id = us.id -- y por ultimo conecto la tabla reservas con la de usuarios por medio del id del usuario
	WHERE mu.estado = 'ACTIVA' -- verifico que en la tabla membresia_usuario el estado sea = 'ACTIVA', pongo 'ACTIVA' pq asi eta 
	GROUP BY us.id, Nombre_completo, tm.nombre  -- agrupo por todos los valores para q sum funcione bien
	HAVING  total_pagado > 100 -- verifico mediante el la forma q nombre re.precio_final que sea mayor que 100 
	ORDER BY total_pagado DESC  -- y ordeno de forma descendente... DE MAS a menos
