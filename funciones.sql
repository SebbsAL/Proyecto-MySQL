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

-- =============================================================================================================================================================

