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
