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
DELIMITER //
CREATE PROCEDURE RenovarMembresia(
	IN p_membresia_usuario_id VARCHAR(36),
	IN p_nueva_fecha_inicio DATE
)
BEGIN
	DECLARE v_duracion INT;
	DECLARE v_tipo_membresia_id VARCHAR(36);
	DECLARE v_fecha_fin_actual DATE;
	DECLARE v_nueva_fecha_fin DATE;
-- Verificamos si la membresia ya existe y obtenemos sus datos actuales
	SELECT tipo_membresia_id, fecha_fin
	INTO v_tipo_membresia_id, v_fecha_fin_actual
	FROM membresia_usuario
	WHERE id = p_membresia_usuario_id;
	IF v_tipo_membresia_id IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: La membresia a renovar no existe.';
	END IF;
-- Obtenemos la duracion del tipo de membresia para calcularla
	SELECT duracion_dias INTO v_duracion 
	FROM tipos_membresia
	WHERE id = v_tipo_membresia_id;
-- Calculamos la nueva fecha final de la membresia
-- Si la membresia no ha vencido, se le suman los dias sobrantes a la nueva fecha final
-- Se realiza el calculo basandose en la fecha inicial
	SET v_nueva_fecha_fin = DATE_ADD(p_nueva_fecha_inicio, INTERVAL v_duracion DAY);
-- Actualizamos la nueva membresia
	UPDATE membresia_usuario
	SET fecha_inicio = p_nueva_fecha_inicio,
		fecha_fin = v_nueva_fecha_fin,
		estado = 'ACTIVA',
		renovaciones = renovaciones + 1,
		fecha_suspension = NULL, -- En caso de que estuviese suspendida, se sanatizan los datos
		motivo_suspension = NULL 
	WHERE id = p_membresia_usuario_id;
END // 
DELIMITER ;
-- 3. Actualizar estado de membresias vencidas
-- Recorre las membresias y marca como "Vencida" las que superan la fecha final
DELIMITER //
CREATE PROCEDURE ActualizarEstadoMembresias()
BEGIN 
-- Se actualizan todas las membresias cuyo estado sea 'ACTIVA' y su fecha de fin sea menor a la fecha actual
	UPDATE membresia_usuario
	SET estado = 'VENCIDA'
	WHERE estado = 'ACTIVA'
	AND fecha_fin < CURRENT_DATE();
-- Al ser una operacion masiva ya que trabaja toda la tabla, la base de datos avisa cuantas filas fueron afectadas
-- Util para scripts de mantenimiento
END // 
DELIMITER ;
-- 4. Suspender membresias con facturas impagas por mas de X dias
-- Cambia el estado a "Suspendida" para usuarios con deudas
DELIMITER //
CREATE PROCEDURE SuspenderMembresiasPorDeuda(IN p_dias_atraso INT)
BEGIN
-- Se actualiza el estado de la membresia a 'SUSPENDIDA' basandose en las facturas que tienen saldo pendiente y cuya fecha de vencimiento supere el plazo permitido
-- Basandose en la formula (fecha actual - dias retraso)
	UPDATE membresia_usuario mu
	INNER JOIN usuario u ON mu.usuario_id = u.id
	INNER JOIN facturas f ON u.id = f.usuario_id
	SET mu.estado = 'SUSPENDIDA',
		mu.fecha_suspension = CURRENT_TIMESTAMP(),
		mu.motivo_suspension = CONCAT('Su membresia ha sido suspendida por deuda vencida desde hace mas de ', p_dias_atraso, ' dias.')
	WHERE mu.estado = 'ACTIVA'
	AND f.estado IN ('PENDIENTE','PARCIAL') -- No se escapa ni un moroso
	AND f.saldo_pendiente > 0
	AND f.fecha_vencimiento < DATE_SUB(CURRENT_DATE(), INTERVAL p_dias_atraso DAY);
END // 
DELIMITER ;