-- ================================================================================================================================================
-- 1. devuelve true si hay una membresia activa
CREATE FUNCTION fn_membresia_activa(p_usuario_id VARCHAR(36) )
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE v_activas INT DEFAULT 0; -- variable donde voy a guardar cuántas filas cumplen la condición

SELECT COUNT(*) INTO v_activas -- cuento las filas que pasan el filtro del WHERE y guardo el resultadofunciones.sql
FROM membresia_usuario
WHERE usuario_id = p_usuario_id -- el WHERE filtra: solo deja pasar filas del usuario q coincidan con la id
  	AND estado = 'ACTIVA';        -- y que además tengan estado "ACTIVA"
IF v_activas > 0 THEN -- si el conteo dio mayor a 0 hay al menos una membresía activa
    RETURN TRUE;
ELSE
    RETURN FALSE; -- de lo contrario no hay por lo tanto retornara FALSE
END IF;	
END;
-- ================================================================================================================================================
-- 2. dias restantes membresia

CREATE FUNCTION fn_dias_restantes_membresia(p_usuario_id VARCHAR(36))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_fecha_fin DATE;
    DECLARE v_dias INT;

    SELECT MAX(fecha_fin) INTO v_fecha_fin -- max lo que hace es q toma todo lo q sobrevio a where y devuelve el -
    FROM membresia_usuario -- ..mas grande, aunque un usuario no debe tener 2 membresias pero x si acaso
    WHERE usuario_id = p_usuario_id
      AND estado = 'ACTIVA';

    IF v_fecha_fin IS NULL THEN
        SET v_dias = 0; -- no tiene membresía activa, no hay días restantes 
    ELSE
        SET v_dias = DATEDIFF(v_fecha_fin, CURDATE()); 
    END IF;

    RETURN v_dias;
END;
-- ================================================================================================================================================
-- 3. tipo actual de membresia

CREATE FUNCTION fn_tipo_membresia(p_usuario_id VARCHAR(36))
RETURNS VARCHAR(255)
DETERMINISTIC 
READS SQL DATA
BEGIN
	DECLARE tipoMemb VARCHAR(255);  -- declaro variable para retornar el tipo de memb
	SELECT tm.nombre INTO tipoMemb
	FROM tipos_membresia tm 
	JOIN membresia_usuario mu ON mu.tipo_membresia_id = tm.id -- uno las tablas que se conenctan, con joins
		WHERE p_usuario_id = mu.usuario_id  -- filtro por id y
			AND	mu.estado = 'ACTIVA' -- el estado activo
		LIMIT 1; --  hace q retorne una sola fila
	RETURN IFNULL(tipoMemb,"no tiene ninguna membresia activa");
END;

-- =============================================================================================================================================
-- 4. numero de veces que renovo una membresia

	CREATE FUNCTION fn_renovaciones_membresia(p_usuario_id VARCHAR(36))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_renovaciones INT DEFAULT 0; -- guarda el número de renovaciones
    SELECT renovaciones INTO v_renovaciones
    FROM membresia_usuario
    WHERE usuario_id = p_usuario_id
      AND estado = 'ACTIVA'
    LIMIT 1; -- evita errores x si hubiera mas de una memb en setado activa

    RETURN IFNULL(v_renovaciones, 0); -- si no tiene membresía activa, devuelve 0
END;
-- ==========================================================================================================================================
-- =============================================================================================================================================================
	-- 5. Estado de la membresia

CREATE FUNCTION fn_estado_membresia(p_usuario_id VARCHAR(36))
RETURNS VARCHAR(100)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_estado VARCHAR(100);
    SELECT estado INTO v_estado
    FROM membresia_usuario
    WHERE usuario_id = p_usuario_id
      AND estado IN ('ACTIVA','SUSPENDIDA','VENCIDA') -- descarta CANCELADA
    ORDER BY fecha_inicio DESC -- prioriza la membresía más reciente
    LIMIT 1; -- evita error por si hay varios por x oy motivo
    RETURN IFNULL(v_estado, 'SIN MEMBRESIA'); -- si no tiene memrbesia devolvera este texto
END;

-- =============================================================================================================================================================
	-- 6. cantidad total de reservas del usuario

CREATE FUNCTION fn_total_reservas(r_usuario_id VARCHAR(36))
RETURNS INT
DETERMINISTIC 
READS SQL DATA
BEGIN
	DECLARE r_Treservas INT DEFAULT 0;
	SELECT COUNT(*) INTO r_Treservas
	FROM reservas
	WHERE usuario_id = r_usuario_id;
	RETURN IFNULL(r_Treservas,0);
END;

-- ===========================================================================================================================================================

	-- 7. total de horas reservadas en un un periodo

CREATE FUNCTION fn_horas_reservadas(p_usuario_id VARCHAR(36), p_mes INT, p_anio INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_horas DECIMAL(10,2) DEFAULT 0; -- extraigo de la tabla la cant de horas q se uso

    SELECT SUM(duracion_horas) INTO v_horas 
    FROM reservas
    WHERE usuario_id = p_usuario_id  -- donde los id's coincidan Y ..
      AND MONTH(fecha_reserva) = p_mes -- .. el mes de reserva coincida con el parametro 
      AND YEAR(fecha_reserva) = p_anio -- y el año
      AND estado IN ('COMPLETADA','CONFIRMADA' ); -- solo cuenta horas que realmente se usaron
    RETURN IFNULL(v_horas, 0);
END;
-- =============================================================================================================================================================

	-- 8. retorna el ID del espacio más usado.

CREATE FUNCTION fn_espacio_mas_reservado()
RETURNS VARCHAR(36)
DETERMINISTIC
READS SQL DATA
BEGIN 
	DECLARE v_espacio_id VARCHAR(36); -- variables para guardar el id y 
	DECLARE v_cantidad INT; 			-- .. cantidad de veces q se reservo
	SELECT espacio_id, COUNT(*) AS total -- seleciono el id y cuento la cantidad de veces q se repite -> 
	INTO v_espacio_id, v_cantidad			-- .. y lo "guardo" como total para abajo llamarlo
	FROM reservas
	GROUP BY espacio_id -- junto las filas por id de espacio asi como formando grupos...
	ORDER BY total DESC	 -- .. el COUNT cuenta cuántas filas hay en cada grupo
	LIMIT 1; -- traigo el ganador
	RETURN v_espacio_id; -- retorno el id
END;

-- =============================================================================================================================================================

	-- 9. reservas activas del usuario

	CREATE FUNCTION fn_reservas_activas(r_usuario_id VARCHAR(36))
	RETURNS INT
	DETERMINISTIC 
	READS SQL DATA
	BEGIN
		DECLARE r_activas INT DEFAULT 0;
		SELECT COUNT(*) INTO r_activas
		FROM reservas
		WHERE usuario_id = r_usuario_id
			AND estado NOT IN ('CANCELADA','NOSHOW','COMPLETADA');
		RETURN IFNULL(r_activas,0);
	END;
		

-- =============================================================================================================================================================
	-- 10. promedio de duración de reservas en un espacio

CREATE FUNCTION fn_duracion_promedio_reservas(p_espacio_id VARCHAR(36) )
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE v_duracion DECIMAL(5,2);
	SELECT AVG(duracion_horas) INTO v_duracion
	FROM reservas
	WHERE espacio_id = p_espacio_id
		AND estado IN ('COMPLETADA','CONFIRMADA');
	RETURN IFNULL(v_duracion, 0);
END;


-- =============================================================================================================================================================
	-- 11.total pagado por un usuario
CREATE FUNCTION fn_total_pagado(p_usuario_id VARCHAR(36) )
RETURNS DECIMAL(12,2)
DETERMINISTIC 
READS SQL DATA
BEGIN
	DECLARE v_total_gastado DECIMAL(12,2); 
	SELECT SUM(monto_neto) INTO	v_total_gastado   -- uso sum para extraer el monto neto de la t. pagos  q se almacene en la variable
	FROM pagos   							
	WHERE usuario_id = p_usuario_id -- id's q coincidan
		AND estado = 'PAGADO'; -- y su estado sea pagado
	RETURN IFNULL(v_total_gastado, 0); -- ifnull para evitar errores
END;
-- =============================================================================================================================================================
	-- 12. ingresos totales en un mes.

CREATE FUNCTION fn_ingresos_por_mes(p_mes INT, p_anio INT)
RETURNS DECIMAL (14,2)
DETERMINISTIC 
READS SQL DATA
BEGIN
	DECLARE v_total_ingreso DECIMAL(14,2);
	SELECT SUM(monto_neto) INTO v_total_ingreso
	FROM pagos
	WHERE MONTH(fecha_pago) = p_mes
		AND YEAR(fecha_pago) = p_anio
		AND	estado = 'PAGADO';
	RETURN IFNULL(v_total_ingreso,0.00);
END;
-- =============================================================================================================================================================
	-- 13. total de ingresos por membresias

CREATE FUNCTION fn_ingresos_por_membresias()
RETURNS DECIMAL(14,2)
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE v_total_ingreso DECIMAL(14,2);
	SELECT SUM(pg.monto_neto) INTO v_total_ingreso
	FROM pagos pg
	JOIN facturas fc ON fc.id = pg.factura_id
		WHERE fc.tipo_factura = 'MEMBRESIA'
			AND pg.estado = 'PAGADO';
	RETURN IFNULL(v_total_ingreso,0);
END;
-- =============================================================================================================================================================
	-- 14. total de ingresos por reservas

CREATE FUNCTION fn_ingresos_por_reservas()
RETURNS DECIMAL(14,2)
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE v_total_ingreso DECIMAL(14,2);
	SELECT SUM(pg.monto_neto) INTO v_total_ingreso
	FROM pagos pg
	JOIN facturas fc ON fc.id = pg.factura_id
		WHERE fc.tipo_factura = 'RESERVA'
			AND pg.estado = 'PAGADO';
	RETURN IFNULL(v_total_ingreso,0);
END;
-- =============================================================================================================================================================
	-- 15. ingresos totales por una empresa

CREATE FUNCTION fn_ingresos_por_empresa(p_empresa_id VARCHAR(36) )
RETURNS DECIMAL(14,2)
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE v_total_ingreso DECIMAL(14,2);
	SELECT SUM(pg.monto_neto) INTO v_total_ingreso
	FROM pagos pg
	JOIN facturas fc ON fc.id = pg.factura_id
		WHERE fc.empresa_id = p_empresa_id
			AND pg.estado = 'PAGADO';
	RETURN IFNULL(v_total_ingreso,0);
END;
-- =============================================================================================================================================================
	-- 16.  cantidad total de asistencias del usuario

CREATE FUNCTION fn_total_asistencias(p_usuario_id VARCHAR(36) )
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE v_total_asistencias INT;
	SELECT COUNT(id)                     -- cuento los id's q pasen por el WHERE
	INTO v_total_asistencias
	FROM accesos
	WHERE tipo_acceso = 'ENTRADA'
		AND usuario_id = p_usuario_id;
	RETURN v_total_asistencias;
END;