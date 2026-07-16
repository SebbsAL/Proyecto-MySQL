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
	WHERE id = p_tipo_membresia_id AND estado = 'ACTIVO';
	IF v_membresia_activa > 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: El usuario ya tiene una membresia activa.';
	END IF;
-- Obtener los datos del tipo de membresia (Su duracion y su precio)
	SELECT duracion_dias, precio_base INTO v_duracion, v_precio
	FROM tipos_membresia
	WHERE id = p_tipo_membresia_id AND estado = 'ACTIVO';
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
-- Reservas y Espacios
-- 1. Verificar disponibilidad de un espacio antes de crear reserva
-- Comprueba que no haya solapamiento de horarios en el mismo espacio
DELIMITER //
CREATE PROCEDURE VerificarDisponibilidad(
	IN p_espacio_id VARCHAR(36),
	IN p_fecha_reserva DATE,
	IN p_hora_inicio TIME,
	IN p_hora_fin TIME
)
BEGIN
	DECLARE v_solapamiento INT;
-- Se busca si existe alguna reserva ya existente en el mismo tiempo de la nueva reservacion
	SELECT COUNT(*) INTO v_solapamiento 
	FROM reservas 
	WHERE espacio_id = p_espacio_id 
	AND fecha_reserva = p_fecha_reserva
	AND estado IN ('PENDIENTE','CONFIRMADA')
	AND p_hora_inicio < hora_fin 
	AND p_hora_fin > hora_inicio;
-- Si el conteo es mayor a 0, significa que el espacio ya esta reservado
	IF v_solapamiento > 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: El espacio ya esta reservado, por favor, seleccione otro horario';
	ELSE
		SELECT 'Disponible' AS resultado;
	END IF;
END // 
DELIMITER ;
-- 2. Crear una nueva reserva de espacio
-- Inserta una reserva en estado "Pendiente" y la vincula a un usuario y espacio
DELIMITER //
CREATE PROCEDURE CrearReserva(
	IN p_usuario_id VARCHAR(36),
	IN p_espacio_id VARCHAR(36),
	IN p_fecha_reserva DATE,
	IN p_hora_inicio TIME,
	IN p_hora_fin TIME,
	IN p_numero_asistentes INT,
	IN p_motivo VARCHAR(255)
)
BEGIN
	DECLARE v_precio_base DECIMAL(10,2);
	DECLARE v_duracion DECIMAL(5,2);
	DECLARE v_precio_total DECIMAL(10,2);
	DECLARE v_reserva_id VARCHAR(36);
-- Llamamos al procedimiento de VerificarDisponibilidad antes de proseguir
-- En caso de que este ocupado, lanzara un error y se detendra el procedimiento
	CALL VerificarDisponibilidad(p_espacio_id, p_fecha_reserva, p_hora_inicio, p_hora_fin);
-- Calculamos la duracion en horas
	SET v_duracion = TIMESTAMPDIFF(MINUTE, p_hora_inicio, p_hora_fin) / 60.0;
-- Se divide por 60.0 permite que el resultado sea en decimal, facilitando el calculo matematico al momento del cobro
-- Ademas, se divide por 60 para convertir la unidad de tiempo de minutos a horas, evitando sobrecargos al cliente
-- Obtenemos el precio del espacio
	SELECT tarifa_base_hora INTO v_precio_base 
	FROM espacios e
	INNER JOIN tipos_espacios te ON e.tipo_espacio_id = te.id 
	WHERE e.id = p_espacio_id;
	SET v_precio_total = v_duracion * v_precio_base;
	SET v_reserva_id = UUID(); -- Se genera el ID manualmente para poder insertarlo despues
-- Ahora insertamos la nueva reservacion
	INSERT INTO reservas (
		id,
		codigo,
		usuario_id,
		espacio_id,
		fecha_reserva,
		hora_inicio,
		hora_fin,
		duracion_horas,
		numero_asistentes,
		motivo,
		estado,
		precio_total,
		precio_final
	) VALUES (
		v_reserva_id,
		CONCAT('RESERVACION-', LEFT(v_reserva_id, 8)), -- Codigo de referencia de la reservacion 
		-- LEFT(8) Toma los primeros 8 caracteres del String UUID para la generacion de la Reservacion haciendolo amigable para el usuario y sea mas sencillo de leer
		p_usuario_id,
		p_espacio_id,
		p_fecha_reserva,
		p_hora_inicio,
		p_hora_fin,
		v_duracion,
		p_numero_asistentes,
		p_motivo,
		'PENDIENTE',
		v_precio_total,
		v_precio_total
	);
-- Retornamos el ID generado por si llega a necesitarse
	SELECT v_reserva_id AS id_reserva_creada;
END // 
DELIMITER ;
-- 3. Confirmar reserva con pago
-- Cambia estado de reserva a "Confirmada" al registrar el pago
DELIMITER //
CREATE PROCEDURE ConfirmarReserva(
	IN p_reserva_id VARCHAR(36),
	IN p_pago_id VARCHAR(36)
)
BEGIN
	DECLARE v_estado_reserva ENUM('PENDIENTE','CONFIRMADA','CANCELADA','NOSHOW','COMPLETADA');
-- Verificamos que la reserva exista y este en estado PENDIENTE
	SELECT estado INTO v_estado_reserva 
	FROM reservas
	WHERE id = p_reserva_id;
	IF v_estado_reserva IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La reserva a confirmar no existe';
	ELSEIF v_estado_reserva != 'PENDIENTE' THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Solo se pueden confirmar reservas que esten en estado PENDIENTE.';
	END IF;
-- Se actualiza el estado de la reserva y registramos la fecha de confirmacion
	UPDATE reservas 
	SET estado = 'CONFIRMADA',
		fecha_confirmacion = CURRENT_TIMESTAMP()
	WHERE id = p_reserva_id;
	SELECT 'Reserva confirmada exitosamente' AS mensaje;
END // 
DELIMITER ;
-- 4. Cancelar reserva con opcion de reembolso parcial
-- Marca reserva como "Cancelada" y genera un registro de reembolso si aplica
DELIMITER //
CREATE PROCEDURE CancelarReserva(
	IN p_reserva_id VARCHAR(36),
	IN p_motivo VARCHAR(255),
	IN p_porcentaje_reembolso DECIMAL(3,2) -- 0.50 para un 50% por ejemplo
	-- Este porcentaje es flexible y puede variar segun el tiempo de anticipacion a la reserva
)
BEGIN
	DECLARE v_precio_final DECIMAL(10,2);
	DECLARE v_monto_reembolso DECIMAL(10,2);
	DECLARE v_usuario_id VARCHAR(36);
	DECLARE v_factura_id VARCHAR(36);
-- Verificamos la existencia y el estado de la reserva
	SELECT precio_final, usuario_id INTO v_precio_final, v_usuario_id 
	FROM reservas 
	WHERE id = p_reserva_id AND estado IN ('PENDIENTE','CONFIRMADA');
	IF v_usuario_id IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Reserva Inexistente';
	END IF;
-- Marcamos la reserva como CANCELADA
	UPDATE reservas
	SET estado = 'CANCELADA',
		fecha_cancelacion = CURRENT_TIMESTAMP(),
		motivo_cancelacion = p_motivo 
	WHERE id = p_reserva_id; 
-- Si aplica reembolso, generamos su respectivo registro
	IF p_porcentaje_reembolso > 0 THEN
		SET v_monto_reembolso = v_precio_final * p_porcentaje_reembolso;
-- Buscamos una factura asociada para registrar el reembolso
		SELECT id INTO v_factura_id FROM facturas
		WHERE usuario_id = v_usuario_id AND tipo_factura = 'RESERVA' LIMIT 1;
-- Registramos el reembolso como un nuevo pago con el estado de 'REEMBOLSADO'
		INSERT INTO pagos(
			codigo_pago,
			factura_id,
			usuario_id,
			metodo_pago_id,
			monto,
			monto_neto,
			estado,
			notas
		) VALUES (
			CONCAT('REEMBOLSO-', LEFT(UUID(), 8)),
			v_factura_id,
			v_usuario_id,
			metodo_pago_id, -- ID del metodo de reembolso
			v_monto_reembolso,
			v_monto_reembolso,
			'REEMBOLSADO',
			CONCAT('Reembolso por cancelacion: ', p_motivo)
		);
	END IF;
	SELECT 'Reserva cancelada exitosamente' AS mensaje, v_monto_reembolso AS monto_devuelto;
END // 
DELIMITER ;
-- 5. Liberar reservas no confirmadas despues de X horas
-- Automatiza la cancelacion de reservas en estado "Pendiente".
DELIMITER //
CREATE PROCEDURE LiberarReservasPendientes(IN p_horas_limite INT)
BEGIN
-- Actualizamos el estado a 'CANCELADA' a todas las reservas que cumplan las siguientes condiciones:
-- Siguen en estado 'PENDIENTE'
-- Fueron creadas hace mas tiempo que las horas limite permitidas
	UPDATE reservas
	SET estado = 'CANCELADA',
		fecha_cancelacion = CURRENT_TIMESTAMP(),
		motivo_cancelacion = CONCAT('Auto-cancelacion: Reserva no confirmada en mas de ', p_horas_limite, ' horas.')
	WHERE estado = 'PENDIENTE'
	AND fecha_creacion < DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL p_horas_limite HOUR);
-- Compara la fecha de creacion de la reserva con el tiempo actual menos las horas que uno defina para que automaticamente se cancele si cumple la condicion
-- Se usa CURRENT_TIMESTAMP ppara que tome las hora exacta, haciendo el calculo mas preciso para el calculo automatico
END // 
DELIMITER ;
-- Pagos y Facturacion
-- 1. Generar factura por membresia
-- Crea factura al activar o renovar una membresia
DELIMITER //
CREATE PROCEDURE GenerarFacturaMembresia(
    IN p_membresia_usuario_id VARCHAR(36)
)
BEGIN
    DECLARE v_usuario_id VARCHAR(36);
    DECLARE v_empresa_id VARCHAR(36);
    DECLARE v_monto DECIMAL(12,2);
    DECLARE v_factura_id VARCHAR(36);
    DECLARE v_numero_factura VARCHAR(30);
-- Obtenemos los datos de la membresia y del usuario
    SELECT mu.usuario_id, u.empresa_id, mu.precio_pagado
    INTO v_usuario_id, v_empresa_id, v_monto 
    FROM membresia_usuario mu
    INNER JOIN usuario u ON mu.usuario_id = u.id 
    WHERE mu.id = p_membresia_usuario_id;
-- Generamos un numero de factura unico
    SET v_numero_factura = CONCAT('FACTURA-', LEFT(UUID(), 8));
    SET v_factura_id = UUID();
-- Generamos la cabecera de la factura
    INSERT INTO facturas (
        id,
        numero_factura,
        usuario_id,
        empresa_id,
        tipo_factura,
        fecha_vencimiento,
        subtotal,
        total,
        saldo_pendiente,
        estado
    ) VALUES (
        v_factura_id,
        v_numero_factura,
        v_usuario_id,
        v_empresa_id,
        'MEMBRESIA',
        DATE_ADD(CURRENT_DATE(), INTERVAL 15 DAY), -- Se vence a los 15 dias
        v_monto,
        v_monto,
        v_monto,
        'PENDIENTE'
    );
-- Generamos el detalle de la factura vinculando la membresia
    INSERT INTO detalle_factura (
        id,
        factura_id,
        concepto,
        cantidad,
        precio_unitario,
        subtotal,
        total,
        referencia_tipo,
        referencia_id
    ) VALUES (
        UUID(),
        v_factura_id,
        'Pago de Membresia Coworking',
        1,
        v_monto,
        v_monto,
        v_monto,
        'MEMBRESIA',
        p_membresia_usuario_id 
    );
    SELECT v_numero_factura AS factura_generada;
END // 
DELIMITER ;
-- 2. Generar factura consolidada para empresa
-- Agrupa cargos de empleados corporativos en una sola factura
DELIMITER //
CREATE PROCEDURE GenerarFacturaConsolidadaCorporativa(
	IN p_empresa_id VARCHAR(36)
)
BEGIN
	DECLARE v_factura_id VARCHAR(36);
	DECLARE v_numero_factura VARCHAR(30);
	DECLARE v_total_empresa DECIMAL(12,2);
-- Calculamos el total de cargos pendientes de todos los empleados de la misma empresa
-- Sumamos membresias, reservas y servicios contratados que no hayan sido facturados todavia
	SELECT IFNULL(SUM(total), 0) INTO v_total_empresa 
	FROM (
		SELECT precio_pagado
		FROM membresia_usuario
		WHERE usuario_id
		IN (SELECT id
			FROM usuario
			WHERE empresa_id = p_empresa_id)
			AND estado = 'ACTIVA'
		UNION ALL -- Se unen todos los datos para generar una factura consolidada
		SELECT precio_final
		FROM reservas
		WHERE usuario_id
		IN (SELECT id
			FROM usuario
			WHERE empresa_id = p_empresa_id)
			AND estado = 'COMPLETADA'
		UNION ALL
		SELECT total
		FROM servicios_contratados 
		WHERE usuario_id 
		IN (SELECT id
			FROM usuario
			WHERE empresa_id = p_empresa_id)
		AND estado = 'ACTIVO'
		) AS cargos_pendientes;
	IF v_total_empresa = 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No hay cargos pendientes para esta empresa';
	END IF;
-- Creamos la factura consolidada
	SET v_factura_id = UUID();
	SET v_numero_factura = CONCAT('FACTURA-CORPORATIVA-', LEFT(v_factura_id, 8));
	INSERT INTO facturas (
		id,
		numero_factura,
		usuario_id,
		empresa_id,
		tipo_factura,
		fecha_vencimiento,
		subtotal,
		total,
		saldo_pendiente,
		estado
	) VALUES (
		v_factura_id,
		v_numero_factura,
		NULL, -- El usuario es NULL al ser una factura corporativa
		p_empresa_id,
		'CONSOLIDADA',
		DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY),
		v_total_empresa,
		v_total_empresa,
		v_total_empresa,
		'PENDIENTE'
	);
	SELECT v_numero_factura AS factura_consolidada_generada, v_total_empresa AS monto_total;
END //
DELIMITER ;
-- 3. Aplicar recargos a facturas vencidas
-- Incrementa el monto de facturas con mas de X dias de atraso
DELIMITER //
CREATE PROCEDURE AplicarRecargosMora(
	IN p_dias_atraso INT,
	IN p_porcentaje_recargo DECIMAL(5,2)
)
BEGIN
-- Actualizamos todas las facturas que cumplen con la condicion de mora
-- Para evitar que el recargo se haga mas de una vez, primero se verifica que el saldo no haya sido alterado previamente por recargos de mora
	UPDATE facturas
	SET total = total + (total * p_porcentaje_recargo),
		saldo_pendiente = saldo_pendiente + (total * p_porcentaje_recargo),
		observaciones = CONCAT(IFNULL(observacione, ''), 'Recargo por mora del ', (p_porcentaje_recargo * 100), '% aplicado el ', CURRENT_DATE())
	WHERE estado = 'PENDIENTE'
	AND fecha_vencimiento < DATE_SUB(CURRENT_DATE(), INTERVAL p_dias_atraso DAY)
-- Evitamos aplicar el recargo por mora multiples veces al verificar si ya tiene la palabra 'Recargo'
	AND notas NOT LIKE '%Recargo por mora%';
END // 
DELIMITER ;
-- 4. Bloquear servicios adicionales por falta de pago
-- Restringe acceso a servicios premium si existen facturas pendientes
DELIMITER //
CREATE PROCEDURE BloquearServiciosPorDeuda()
BEGIN 
-- Bloqueamos los servicios de usuarios que tienen facturas vencidas y que tengan un saldo pendiente mayor a cero
	UPDATE servicios_contratados sc
	INNER JOIN usuario u ON sc.usuario_id = u.id
	INNER JOIN facturas f ON u.id = f.usuario_id
	SET sc.estado = 'BLOQUEADO',
		sc.fecha_bloqueo = CURRENT_TIMESTAMP(),
		sc.motivo_bloqueo = 'Bloqueo Moroso: Facturas pendientes por pagar'
	WHERE sc.estado = 'ACTIVO'
	AND f.estado = 'PENDIENTE'
	AND f.saldo_pendiente > 0
	AND f.fecha_vencimiento < CURRENT_DATE();
END // 
DELIMITER ;
-- Accesos y Asistencias
-- 1. Registrar acceso de usuario (Entrada)
-- Valida membresia o reserva activa y registra entrada en logs
DROP PROCEDURE IF EXISTS RegistrarAccesoEntrada;
DELIMITER //
CREATE PROCEDURE RegistrarAccesoEntrada(
	IN p_usuario_id VARCHAR(36),
	IN p_credencial_id VARCHAR(36),
	IN p_espacio_id VARCHAR(36),
	IN p_punto_acceso VARCHAR(100)
)
BEGIN
	DECLARE v_tipo_credencial ENUM('RFID','QR','BIOMETRICO','TEMPORAL');
	DECLARE v_metodo_validacion ENUM('RFID','QR','BIOMETRICO','MANUAL','AUTOMATICO');
	DECLARE v_validacion_membresia ENUM('ACTIVA','VENCIDA','SUSPENDIDA','SIN_MEMBRESIA');
	DECLARE v_validacion_reserva ENUM('CON_RESERVA','SIN_RESERVA','RESERVA_VENCIDA') DEFAULT 'SIN_RESERVA';
	DECLARE v_tiene_reserva INT DEFAULT 0;
	DECLARE v_motivo_rechazo ENUM('CREDENCIAL_INVALIDA','CREDENCIAL_REVOCADA','CREDENCIAL_VENCIDA','MEMBRESIA_VENCIDA','MEMBRESIA_SUSPENDIDA','SIN_MEMBRESIA','SIN_RESERVA','HORARIO_NO_PERMITIDO','ESPACIO_NO_DISPONIBLE','INTENTOS_EXCEDIDOS','SOSPECHA_FRAUDE','OTRO');

-- 1) La credencial debe existir, pertenecer al usuario y estar ACTIVA
	SELECT tipo_credencial INTO v_tipo_credencial
	FROM credenciales_acceso
	WHERE id = p_credencial_id
	AND usuario_id = p_usuario_id
	AND estado = 'ACTIVA';

	IF v_tipo_credencial IS NULL THEN
		INSERT INTO intentos_acceso_rechazados (
			usuario_id, credencial_id, metodo_validacion, punto_acceso,
			motivo_rechazo, descripcion_detallada
		) VALUES (
			p_usuario_id, p_credencial_id, 'MANUAL', p_punto_acceso,
			'CREDENCIAL_INVALIDA', 'Credencial inexistente, de otro usuario o inactiva.'
		);
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Acceso Denegado: Credencial invalida o inactiva.';
	END IF;

-- 2) Metodo de validacion segun el tipo de credencial (TEMPORAL se trata como MANUAL)
	SET v_metodo_validacion = CASE WHEN v_tipo_credencial IN ('RFID','QR','BIOMETRICO') THEN v_tipo_credencial ELSE 'MANUAL' END;

-- 3) Estado de la membresia mas reciente del usuario
	SELECT estado INTO v_validacion_membresia
	FROM membresia_usuario
	WHERE usuario_id = p_usuario_id
	ORDER BY fecha_inicio DESC
	LIMIT 1;

	IF v_validacion_membresia IS NULL THEN
		SET v_validacion_membresia = 'SIN_MEMBRESIA';
	END IF;

-- 4) Si no hay membresia activa, buscamos una reserva confirmada para hoy, en ese espacio y a esta hora
	IF v_validacion_membresia != 'ACTIVA' THEN
		SELECT COUNT(*) INTO v_tiene_reserva
		FROM reservas
		WHERE usuario_id = p_usuario_id
		AND espacio_id = p_espacio_id
		AND fecha_reserva = CURRENT_DATE()
		AND CURRENT_TIME() BETWEEN hora_inicio AND hora_fin
		AND estado = 'CONFIRMADA';

		IF v_tiene_reserva > 0 THEN
			SET v_validacion_reserva = 'CON_RESERVA';
		END IF;
	END IF;

-- 5) Sin membresia activa ni reserva confirmada -> se rechaza y se registra el intento
	IF v_validacion_membresia != 'ACTIVA' AND v_tiene_reserva = 0 THEN

		IF v_validacion_membresia = 'VENCIDA' THEN
			SET v_motivo_rechazo = 'MEMBRESIA_VENCIDA';
		ELSEIF v_validacion_membresia = 'SUSPENDIDA' THEN
			SET v_motivo_rechazo = 'MEMBRESIA_SUSPENDIDA';
		ELSE
			SET v_motivo_rechazo = 'SIN_MEMBRESIA';
		END IF;

		INSERT INTO intentos_acceso_rechazados (
			usuario_id, credencial_id, metodo_validacion, punto_acceso,
			motivo_rechazo, descripcion_detallada
		) VALUES (
			p_usuario_id, p_credencial_id, v_metodo_validacion, p_punto_acceso,
			v_motivo_rechazo, 'Usuario sin membresia activa ni reserva confirmada.'
		);

		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Acceso Denegado: Usuario sin membresia ni reserva confirmada.';
	ELSE
-- 6) Acceso valido: se registra la entrada
		INSERT INTO accesos (
			usuario_id, credencial_id, tipo_acceso, metodo_validacion,
			punto_acceso, validacion_membresia, validacion_reserva, estado
		) VALUES (
			p_usuario_id, p_credencial_id, 'ENTRADA', v_metodo_validacion,
			p_punto_acceso, v_validacion_membresia, v_validacion_reserva, 'PERMITIDO'
		);

		SELECT 'Acceso Permitido' AS mensaje;
	END IF;
END //
DELIMITER ;
-- 2. Registrar salida de usuario
-- Completa la asistencia del usuario y marca hora de salida
DROP PROCEDURE IF EXISTS RegistrarAccesoSalida;
DELIMITER //
CREATE PROCEDURE RegistrarAccesoSalida(
	IN p_usuario_id VARCHAR(36),
	IN p_credencial_id VARCHAR(36),
	IN p_punto_acceso VARCHAR(100)
)
BEGIN
	DECLARE v_tipo_credencial ENUM('RFID','QR','BIOMETRICO','TEMPORAL');
	DECLARE v_metodo_validacion ENUM('RFID','QR','BIOMETRICO','MANUAL','AUTOMATICO');
	DECLARE v_validacion_membresia ENUM('ACTIVA','VENCIDA','SUSPENDIDA','SIN_MEMBRESIA');
	DECLARE v_ultimo_id VARCHAR(36);
	DECLARE v_ultimo_tipo ENUM('ENTRADA','SALIDA');

-- 1) La credencial debe existir, pertenecer al usuario y estar ACTIVA
	SELECT tipo_credencial INTO v_tipo_credencial
	FROM credenciales_acceso
	WHERE id = p_credencial_id
	AND usuario_id = p_usuario_id
	AND estado = 'ACTIVA';

	IF v_tipo_credencial IS NULL THEN
		INSERT INTO intentos_acceso_rechazados (
			usuario_id, credencial_id, metodo_validacion, punto_acceso,
			motivo_rechazo, descripcion_detallada
		) VALUES (
			p_usuario_id, p_credencial_id, 'MANUAL', p_punto_acceso,
			'CREDENCIAL_INVALIDA', 'Credencial inexistente, de otro usuario o inactiva (intento de salida).'
		);
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: Credencial invalida o inactiva.';
	END IF;

	SET v_metodo_validacion = CASE WHEN v_tipo_credencial IN ('RFID','QR','BIOMETRICO') THEN v_tipo_credencial ELSE 'MANUAL' END;

-- 2) Buscamos el ultimo registro de acceso del usuario (entrada o salida)
	SELECT id, tipo_acceso INTO v_ultimo_id, v_ultimo_tipo
	FROM accesos
	WHERE usuario_id = p_usuario_id
	ORDER BY fecha_hora DESC
	LIMIT 1;

-- 3) Si no hay una entrada abierta, no hay nada que cerrar
	IF v_ultimo_id IS NULL OR v_ultimo_tipo = 'SALIDA' THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: No se encontro ningun registro de entrada abierto para este usuario.';
	END IF;

-- 4) Dejamos constancia del estado de membresia al momento de la salida (no bloquea la salida)
	SELECT estado INTO v_validacion_membresia
	FROM membresia_usuario
	WHERE usuario_id = p_usuario_id
	ORDER BY fecha_inicio DESC
	LIMIT 1;

	IF v_validacion_membresia IS NULL THEN
		SET v_validacion_membresia = 'SIN_MEMBRESIA';
	END IF;

-- 5) Registramos la salida como una fila nueva (accesos es un log; no se "actualiza" la entrada)
	INSERT INTO accesos (
		usuario_id, credencial_id, tipo_acceso, metodo_validacion,
		punto_acceso, validacion_membresia, validacion_reserva, estado
	) VALUES (
		p_usuario_id, p_credencial_id, 'SALIDA', v_metodo_validacion,
		p_punto_acceso, v_validacion_membresia, 'SIN_RESERVA', 'PERMITIDO'
	);

	SELECT 'Salida registrada correctamente' AS mensaje;
END //
DELIMITER ;
-- 3. Generar reporte diario de asistencias
-- Resume cantidad de ingresos, usuarios unicos y horarios pico
DROP PROCEDURE IF EXISTS GenerarReporteDiarioAsistencia;
DELIMITER //
CREATE PROCEDURE GenerarReporteDiarioAsistencia(
	IN p_fecha DATE
)
BEGIN
	SELECT
		COUNT(*) AS total_ingresos,
		COUNT(DISTINCT usuario_id) AS usuarios_unicos,
		(SELECT HOUR(fecha_hora)
		 FROM accesos
		 WHERE DATE(fecha_hora) = p_fecha
		 AND tipo_acceso = 'ENTRADA'
		 AND estado = 'PERMITIDO'
		 GROUP BY HOUR(fecha_hora)
		 ORDER BY COUNT(*) DESC
		 LIMIT 1) AS hora_pico
	FROM accesos
	WHERE DATE(fecha_hora) = p_fecha
	AND tipo_acceso = 'ENTRADA'
	AND estado = 'PERMITIDO';
END //
DELIMITER ;
-- 4. Marcar reservas como "No Show" y generar penalizacion
-- Detecta reservas confirmadas sin asistencia y aplica cargo automatico
DROP PROCEDURE IF EXISTS DetectarNoShow;
DELIMITER //
CREATE PROCEDURE DetectarNoShow()
BEGIN
-- 1) Marcamos como NOSHOW las reservas confirmadas y pasadas sin entrada real registrada en accesos
	UPDATE reservas r
	LEFT JOIN accesos ac
		ON r.usuario_id = ac.usuario_id
		AND DATE(ac.fecha_hora) = r.fecha_reserva
		AND ac.tipo_acceso = 'ENTRADA'
		AND ac.estado = 'PERMITIDO'
	SET r.estado = 'NOSHOW',
		r.fecha_cancelacion = CURRENT_TIMESTAMP(),
		r.motivo_cancelacion = 'NOSHOW detectado por el sistema.'
	WHERE r.estado = 'CONFIRMADA'
	AND r.fecha_reserva < CURRENT_DATE()
	AND ac.id IS NULL;

-- 2) Multa del 20% solo para los NOSHOW que aun no tienen una multa registrada
	INSERT INTO servicios_contratados (
		codigo, usuario_id, reserva_id, fecha_uso,
		cantidad, unidad_cobro, precio_unitario, subtotal, total,
		estado, notas
	)
	SELECT
		CONCAT('MULTA-NOSHOW-', LEFT(r.id, 8)),
		r.usuario_id,
		r.id,
		CURRENT_DATE(),
		1.00,
		'FIJO',
		(r.precio_final * 0.20),
		(r.precio_final * 0.20),
		(r.precio_final * 0.20),
		'ACTIVO',
		CONCAT('Multa por NOSHOW - Reserva: ', r.id)
	FROM reservas r
	WHERE r.estado = 'NOSHOW'
	AND r.motivo_cancelacion = 'NOSHOW detectado por el sistema.'
	AND NOT EXISTS (
		SELECT 1 FROM servicios_contratados sc
		WHERE sc.reserva_id = r.id
		AND sc.notas LIKE 'Multa por NOSHOW%'
	);

	SELECT 'Proceso de deteccion de NOSHOWS finalizado.' AS mensaje;
END //
DELIMITER ;
-- Corporativos y Administracion
-- 1. Registrar lote de empleados de una empresa con membresia corporativa
-- Insertar varios usuarios vinculados a una empresa y les asigna membresia
DELIMITER //
CREATE PROCEDURE RegistrarLoteEmpleados(
	IN p_empresa_id VARCHAR(36),
	IN p_nombre_empleado VARCHAR(100),
	IN p_email_empleado VARCHAR(100),
	IN p_membresia_tipo_id VARCHAR(36)
)
BEGIN
	DECLARE v_usuario_id VARCHAR(36);
	DECLARE v_membresia_id VARCHAR(36);
-- Primero, creamos el usuario
	SET v_usuario_id = UUID();
	INSERT INTO usuario (id, nombre, email, empresa_id, rol)
	VALUES (v_usuario_id, p_nombre_empleado, p_email_empleado, p_empresa_id, 'EMPLEADO');
-- Ahora asignamos la membresia corporativa al nuevo usuario
	SET v_membresia_id = UUID();
	INSERT INTO membresia_usuario (
		id,
		usuario_id,
		membresia_tipo_id,
		estado,
		fecha_inicio,
		fecha_fin
	) VALUES (
		v_membresia_id,
		v_usuario_id,
		p_membresia_tipo_id,
		'ACTIVA',
		CURRENT_DATE(),
		DATE_ADD(CURRENT_DATE(), INTERVAL 1 MONTH) -- Membresia mensual por defecto
	);
	SELECT 'Empleado y membresia registrados exitosamente' AS mensaje;
END // 
DELIMITER ;
-- 2. Cancelar reservas futuras al eliminar membresia de usuario
-- Recorre reservas pendientes/confirmadas y las cancela automaticamente
DELIMITER //
CREATE PROCEDURE CancelarReservasFuturasUsuario(
	IN p_usuario_id VARCHAR(36),
	IN p_motivo VARCHAR(255)
)
BEGIN
-- Marcamos como CANCELADA toda reserva futura para el usuario en especifico
	UPDATE reservas
	SET estado = 'CANCELADA',
		fecha_cancelacion = CURRENT_TIMESTAMP(),
		motivo_cancelacion = CONCAT('Cancelacion por membresia expirada o eliminada: ', p_motivo)
	WHERE usuario_id = p_usuario_id
	AND estado IN ('PENDIENTE','CONFIRMADA')
	AND fecha_reserva >= CURRENT_DATE();
-- Verificamos si hubo reservas futuras que se cancelaron automaticamente
	IF ROW_COUNT() > 0 THEN
		SELECT CONCAT(ROW_COUNT(), 'Las reservas fueron canceladas satisfactoriamente') AS mensaje;
	ELSE 
		SELECT 'No habian reservas para cancelar' AS mensaje;
	END IF;
END // 
DELIMITER ;
-- 3. Generar reporte de ingresos mensuales acumulados
-- Calcula ingresos por mes e ingresos acumulados en el año
DELIMITER //
CREATE PROCEDURE GenerarReporteIngresosAnuales(IN p_anio INT)
BEGIN
-- Generaremos un reporte mensual que muestra:
-- 1. El mes
-- 2. Los ingresos brutos de ese mes
-- 3. El acumulado anual hasta de ese mes
	SELECT
		MONTH(fecha_pago) AS mes,
		SUM(monto) AS ingresos_mes,
		(SELECT SUM(monto)
		FROM pagos
		WHERE YEAR(fecha_pago) = p_anio
		AND MONTH(fecha_pago) <= MONTH(p.fecha_pago)) AS acumulado_anual
	FROM pagos p
	WHERE YEAR(fecha_pago) = p_anio
	GROUP BY MONTH(fecha_pago)
	ORDER BY mes ASC;
END // 
DELIMITER ;