USE coworking;
-- Procedimientos Almacenados
-- Membresias
-- 1. Registrar nueva membresia y asignarla a un usuario
-- Inserta una nueva membresia con fecha de inicio, fecha de vencimiento y estado inicial
DELIMITER //
CREATE PROCEDURE RegistrarNuevaMembresia(
	IN p_usuario_id VARCHAR(36),
	IN p_tipo_membresia_id VARCHAR(36),
	IN p_fecha_inicio DATE
)
BEGIN
	DECLARE v_duracion INT;
	DECLARE v_precio DECIMAL(10,2);
	DECLARE v_fecha_fin DATE;
	DECLARE v_membresia_activa INT;
-- Validar que el usuario no tenga una membresia activa
	SELECT COUNT(*) INTO v_membresia_activa
	FROM membresia_usuario
	WHERE usuario_id = p_usuario_id AND estado = 'ACTIVA';
	IF v_membresia_activa > 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: El usuario ya tiene una membresia activa.';
	END IF;
-- Obtener los datos del tipo de membresia (Su duracion y su precio)
	SELECT duracion_dias, precio_base INTO v_duracion, v_precio
	FROM tipos_membresia
	WHERE id = p_tipo_membresia AND estado = 'ACTIVO';
	IF v_duracion IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: El tipo de membresia no existe o esta inactivo.';
	END IF;
-- Calculamos la fecha de vencimiento
	SET v_fecha_fin = DATE_ADD(p_fecha_inicio, INTERVAL v_duracion DAY);
-- Insertamos la nueva membresia
	INSERT INTO membresia_usuario(
		usuario_id,
		tipo_membresia_id,
		fecha_inicio,
		fecha_fin,
		estado,
		precio_pagado
	) VALUES (
		p_usuario_id,
		p_tipo_membresia_id,
		p_fecha_inicio,
		v_fecha_fin,
		'ACTIVA',
		v_precio
	);
END // 
DELIMITER ;	
-- 2. Renovar una membresia existente
-- Extiende la vigencia de una membresia segun el tipo contratado
