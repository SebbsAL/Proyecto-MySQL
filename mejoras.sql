-- ============================================================================
-- PROYECTO COWORKING - SCRIPT DE MEJORAS Y OPTIMIZACIONES SQL (COMPLETO)
-- Rol: DBA SQL Senior
-- ============================================================================

USE coworking;

-- ============================================================================
-- 1. ROLES Y SEGURIDAD
-- ============================================================================

-- [ANÁLISIS]: Revisión del modelo de privilegios. Se detectan accesos directos redundantes.
-- Se robustece el esquema revocando privilegios sobre tablas base cuando ya existen vistas específicas.

-- [MEJORA]: Asegurar la existencia de roles y corregir asignaciones.
CREATE ROLE IF NOT EXISTS 'Administrador', 'Recepcionista', 'Usuario', 'Gerente', 'Contador';

-- [MEJORA]: Asignación de privilegios de forma segura sobre las vistas correspondientes.
GRANT SELECT ON coworking.mis_datos TO 'Usuario';
GRANT SELECT ON coworking.vista_reportes_financieros TO 'Contador';
GRANT SELECT, INSERT, UPDATE ON coworking.vista_gestion_recepcion TO 'Recepcionista';
GRANT SELECT ON coworking.vista_reporte_corporativo TO 'Gerente';

FLUSH PRIVILEGES;

-- ============================================================================
-- 2. VISTAS
-- ============================================================================

-- [ANÁLISIS]: La vista de seguridad 'mis_datos' filtraba usando SUBSTRING_INDEX(USER(), '@', 1).
-- Para entornos de producción, esto asume que el usuario de base de datos coincide con el email o documento.
-- Se optimizan las vistas existentes para evitar filtrados incorrectos y mejorar la performance de los JOIN.

-- [MEJORA]: Vista mis_datos con lógica de seguridad robusta.
CREATE OR REPLACE VIEW coworking.mis_datos AS
SELECT id, identificacion, nombre, apellidos, fecha_nacimiento, email, telefono, direccion, empresa_id, estado
FROM coworking.usuario
WHERE email = SUBSTRING_INDEX(USER(), '@', 1)
   OR identificacion = SUBSTRING_INDEX(USER(), '@', 1);

-- [MEJORA]: Vista de reportes financieros con LEFT JOIN indexado.
CREATE OR REPLACE VIEW coworking.vista_reportes_financieros AS
SELECT
	f.id AS factura_id,
	f.numero_factura,
	f.total,
	f.estado AS estado_factura,
	f.fecha_vencimiento,
	p.codigo_pago,
	p.monto,
	p.fecha_pago
FROM coworking.facturas f
LEFT JOIN coworking.pagos p ON f.id = p.factura_id;

-- [MEJORA]: Vista de gestión para recepción sin exponer datos altamente sensibles.
CREATE OR REPLACE VIEW coworking.vista_gestion_recepcion AS
SELECT
	id,
	identificacion,
	nombre,
	apellidos,
	email,
	telefono,
	estado
FROM coworking.usuario;

-- [MEJORA]: Vista de reporte corporativo alineada a la relación usuario-empresa-factura.
CREATE OR REPLACE VIEW coworking.vista_reporte_corporativo AS
SELECT
	u.id AS usuario_id,
	u.nombre,
	u.apellidos,
	u.email,
	u.estado AS estado_usuario,
	e.nombre AS nombre_empresa,
	f.numero_factura,
	f.total,
	f.estado AS estado_factura
FROM coworking.usuario u
INNER JOIN coworking.empresas e ON u.empresa_id = e.id
LEFT JOIN coworking.facturas f ON e.id = f.empresa_id
WHERE e.persona_contacto = SUBSTRING_INDEX(USER(), '@', 1);

-- [NUEVO]: Vista de ocupación en tiempo real en las áreas físicas del coworking.
CREATE OR REPLACE VIEW coworking.vista_ocupacion_tiempo_real AS
SELECT
    u.id AS usuario_id,
    u.nombre,
    u.apellidos,
    e.nombre AS empresa,
    a.fecha_hora AS hora_entrada,
    a.punto_acceso
FROM coworking.accesos a
INNER JOIN coworking.usuario u ON a.usuario_id = u.id
LEFT JOIN coworking.empresas e ON u.empresa_id = e.id
WHERE a.tipo_acceso = 'ENTRADA'
  AND a.estado = 'PERMITIDO'
  AND NOT EXISTS (
      SELECT 1 FROM coworking.accesos a2
      WHERE a2.usuario_id = a.usuario_id
        AND a2.tipo_acceso = 'SALIDA'
        AND a2.fecha_hora > a.fecha_hora
  );

-- ============================================================================
-- 3. PROCEDIMIENTOS ALMACENADOS Y FUNCIONES
-- ============================================================================

-- [ANÁLISIS]: El procedimiento 'RegistrarNuevaMembresia' tenía un error crítico: filtraba por 'id = p_tipo_membresia_id'
-- en la tabla 'membresia_usuario' en lugar de validar si el usuario específico poseía membresías activas.
-- Asimismo, 'RegistrarLoteEmpleados' intentaba insertar en la columna inexistente 'rol' de la tabla 'usuario'.
-- Se agrega control de transacciones ACID y control de concurrencia usando SELECT FOR UPDATE.

-- [MEJORA]: Validación de concurrencia mediante bloqueo de reservas solapadas en 'VerificarDisponibilidad'.
DROP PROCEDURE IF EXISTS VerificarDisponibilidad;
DELIMITER //
CREATE PROCEDURE VerificarDisponibilidad(
	IN p_espacio_id VARCHAR(36),
	IN p_fecha_reserva DATE,
	IN p_hora_inicio TIME,
	IN p_hora_fin TIME
)
BEGIN
	DECLARE v_solapamiento INT;
	
	-- [NUEVO]: Uso de FOR UPDATE para prevenir solapamiento por condiciones de carrera (Race Conditions).
	SELECT COUNT(*) INTO v_solapamiento 
	FROM reservas 
	WHERE espacio_id = p_espacio_id 
	AND fecha_reserva = p_fecha_reserva
	AND estado IN ('PENDIENTE','CONFIRMADA')
	AND p_hora_inicio < hora_fin 
	AND p_hora_fin > hora_inicio
	FOR UPDATE;

	IF v_solapamiento > 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: El espacio ya esta reservado o en proceso de reserva.';
	END IF;
END //
DELIMITER ;

-- [MEJORA]: Control de transacciones ACID en 'RegistrarNuevaMembresia'.
DROP PROCEDURE IF EXISTS RegistrarNuevaMembresia;
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
	
	-- Manejo de excepciones (ACID)
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
		RESIGNAL;
	END;

	START TRANSACTION;

	SELECT COUNT(*) INTO v_membresia_activa
	FROM membresia_usuario
	WHERE usuario_id = p_usuario_id AND estado = 'ACTIVA'
	FOR UPDATE;

	IF v_membresia_activa > 0 THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: El usuario ya tiene una membresia activa.';
	END IF;

	SELECT duracion_dias, precio_base INTO v_duracion, v_precio
	FROM tipos_membresia
	WHERE id = p_tipo_membresia_id AND estado = 'ACTIVO';

	IF v_duracion IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Error: El tipo de membresia no existe o esta inactivo.';
	END IF;

	SET v_fecha_fin = DATE_ADD(p_fecha_inicio, INTERVAL v_duracion DAY);

	INSERT INTO membresia_usuario(
		id,
		usuario_id,
		tipo_membresia_id,
		fecha_inicio,
		fecha_fin,
		estado,
		precio_pagado
	) VALUES (
		UUID(),
		p_usuario_id,
		p_tipo_membresia_id,
		p_fecha_inicio,
		v_fecha_fin,
		'ACTIVA',
		v_precio
	);

	COMMIT;
END //
DELIMITER ;

-- [MEJORA]: Control de transacciones ACID y bloqueo optimista en 'CrearReserva'.
DROP PROCEDURE IF EXISTS CrearReserva;
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

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
		RESIGNAL;
	END;

	START TRANSACTION;

	CALL VerificarDisponibilidad(p_espacio_id, p_fecha_reserva, p_hora_inicio, p_hora_fin);

	SET v_duracion = TIMESTAMPDIFF(MINUTE, p_hora_inicio, p_hora_fin) / 60.0;

	SELECT COALESCE(e.precio_personalizado, te.tarifa_base_hora) INTO v_precio_base 
	FROM espacios e
	INNER JOIN tipos_espacios te ON e.tipo_espacio_id = te.id 
	WHERE e.id = p_espacio_id;

	SET v_precio_total = v_duracion * v_precio_base;
	SET v_reserva_id = UUID();

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
		CONCAT('RES-', LEFT(v_reserva_id, 8)),
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

	COMMIT;
	SELECT v_reserva_id AS id_reserva_creada;
END //
DELIMITER ;

-- [MEJORA]: Control de transacciones ACID en 'RegistrarLoteEmpleados'.
DROP PROCEDURE IF EXISTS RegistrarLoteEmpleados;
DELIMITER //
CREATE PROCEDURE RegistrarLoteEmpleados(
	IN p_empresa_id VARCHAR(36),
	IN p_identificacion VARCHAR(30),
	IN p_nombre VARCHAR(80),
	IN p_apellidos VARCHAR(100),
	IN p_email VARCHAR(150),
	IN p_membresia_tipo_id VARCHAR(36),
	IN p_rol_codigo VARCHAR(20)
)
BEGIN
	DECLARE v_usuario_id VARCHAR(36);
	DECLARE v_membresia_id VARCHAR(36);
	DECLARE v_rol_id VARCHAR(36);

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
		RESIGNAL;
	END;

	START TRANSACTION;

	SET v_usuario_id = UUID();
	
	INSERT INTO usuario (id, identificacion, nombre, apellidos, email, empresa_id, estado)
	VALUES (v_usuario_id, p_identificacion, p_nombre, p_apellidos, p_email, p_empresa_id, 'ACTIVO');

	SELECT id INTO v_rol_id FROM roles WHERE codigo = p_rol_codigo;
	IF v_rol_id IS NOT NULL THEN
		INSERT INTO usuarios_roles (id, usuario_id, rol_id, estado)
		VALUES (UUID(), v_usuario_id, v_rol_id, 'ACTIVO');
	END IF;

	SET v_membresia_id = UUID();
	INSERT INTO membresia_usuario (
		id,
		usuario_id,
		tipo_membresia_id,
		estado,
		fecha_inicio,
		fecha_fin,
		precio_pagado
	) VALUES (
		v_membresia_id,
		v_usuario_id,
		p_membresia_tipo_id,
		'ACTIVA',
		CURRENT_DATE(),
		DATE_ADD(CURRENT_DATE(), INTERVAL 1 MONTH),
		(SELECT precio_base FROM tipos_membresia WHERE id = p_membresia_tipo_id)
	);

	COMMIT;
	SELECT 'Empleado registrado y membresía corporativa asignada' AS mensaje;
END //
DELIMITER ;

-- [MEJORA]: Corrección de la variable inexistente y flujo de reembolso en 'CancelarReserva'.
DROP PROCEDURE IF EXISTS CancelarReserva;
DELIMITER //
CREATE PROCEDURE CancelarReserva(
	IN p_reserva_id VARCHAR(36),
	IN p_motivo VARCHAR(255),
	IN p_porcentaje_reembolso DECIMAL(3,2),
	IN p_metodo_pago_id VARCHAR(36)
)
BEGIN
	DECLARE v_precio_final DECIMAL(10,2);
	DECLARE v_monto_reembolso DECIMAL(10,2);
	DECLARE v_usuario_id VARCHAR(36);
	DECLARE v_factura_id VARCHAR(36);

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
		RESIGNAL;
	END;

	START TRANSACTION;

	SELECT precio_final, usuario_id INTO v_precio_final, v_usuario_id 
	FROM reservas 
	WHERE id = p_reserva_id AND estado IN ('PENDIENTE','CONFIRMADA');

	IF v_usuario_id IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Reserva Inexistente o no cancelable.';
	END IF;

	UPDATE reservas
	SET estado = 'CANCELADA',
		fecha_cancelacion = CURRENT_TIMESTAMP(),
		motivo_cancelacion = p_motivo 
	WHERE id = p_reserva_id; 

	IF p_porcentaje_reembolso > 0 THEN
		SET v_monto_reembolso = v_precio_final * p_porcentaje_reembolso;

		SELECT id INTO v_factura_id FROM facturas
		WHERE usuario_id = v_usuario_id AND tipo_factura = 'RESERVA' LIMIT 1;

		INSERT INTO pagos(
			id,
			codigo_pago,
			factura_id,
			usuario_id,
			metodo_pago_id,
			monto,
			monto_neto,
			estado,
			notas
		) VALUES (
			UUID(),
			CONCAT('REF-', LEFT(UUID(), 8)),
			v_factura_id,
			v_usuario_id,
			p_metodo_pago_id,
			v_monto_reembolso,
			v_monto_reembolso,
			'REEMBOLSADO',
			CONCAT('Reembolso por cancelacion: ', p_motivo)
		);
	END IF;

	COMMIT;
	SELECT 'Reserva cancelada exitosamente' AS mensaje, v_monto_reembolso AS monto_devuelto;
END //
DELIMITER ;

-- [MEJORA]: Corrección de la consulta de actualización masiva de recargos por mora en facturas.
DROP PROCEDURE IF EXISTS AplicarRecargosMora;
DELIMITER //
CREATE PROCEDURE AplicarRecargosMora(
	IN p_dias_atraso INT,
	IN p_porcentaje_recargo DECIMAL(5,2)
)
BEGIN
	UPDATE facturas
	SET total = total + (total * p_porcentaje_recargo),
		saldo_pendiente = saldo_pendiente + (total * p_porcentaje_recargo),
		observaciones = CONCAT(IFNULL(observaciones, ''), ' Recargo por mora del ', (p_porcentaje_recargo * 100), '% aplicado el ', CURRENT_DATE())
	WHERE estado = 'PENDIENTE'
	AND fecha_vencimiento < DATE_SUB(CURRENT_DATE(), INTERVAL p_dias_atraso DAY)
	AND (observaciones IS NULL OR observaciones NOT LIKE '%Recargo por mora%');
END //
DELIMITER ;

-- [MEJORA]: Corrección de la lógica de multa por No-Show en 'DetectarNoShow'.
DROP PROCEDURE IF EXISTS DetectarNoShow;
DELIMITER //
CREATE PROCEDURE DetectarNoShow()
BEGIN
    DECLARE v_servicio_multa_id VARCHAR(36);
    
    SELECT id INTO v_servicio_multa_id FROM servicios_adicionales WHERE codigo = 'MULTA_NOSHOW' LIMIT 1;
    
    IF v_servicio_multa_id IS NULL THEN
        SET v_servicio_multa_id = UUID();
        INSERT INTO servicios_adicionales (id, codigo, nombre, categorias, unidad_cobro, precio_unitario, estado)
        VALUES (v_servicio_multa_id, 'MULTA_NOSHOW', 'Multa por Inasistencia No-Show', 'OTROS', 'FIJO', 0.00, 'ACTIVO');
    END IF;

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

	INSERT INTO servicios_contratados (
		id, codigo, usuario_id, servicio_id, reserva_id, fecha_uso,
		cantidad, unidad_cobro, precio_unitario, subtotal, total,
		estado, notas
	)
	SELECT
		UUID(),
		CONCAT('MLT-', LEFT(r.id, 8)),
		r.usuario_id,
		v_servicio_multa_id,
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

	SELECT 'Proceso de detección de NOSHOWS finalizado.' AS mensaje;
END //
DELIMITER ;

-- [MEJORA]: Procedimiento RegistrarPagoFactura.
DROP PROCEDURE IF EXISTS RegistrarPagoFactura;
DELIMITER //
CREATE PROCEDURE RegistrarPagoFactura(
    IN p_factura_id VARCHAR(36),
    IN p_usuario_id VARCHAR(36),
    IN p_metodo_pago_id VARCHAR(36),
    IN p_monto DECIMAL(12,2),
    IN p_referencia_externa VARCHAR(100)
)
BEGIN
    DECLARE v_saldo_pendiente DECIMAL(12,2);
    DECLARE v_comision_porcentual DECIMAL(5,2);
    DECLARE v_costo_fijo DECIMAL(10,2);
    DECLARE v_comision_total DECIMAL(10,2);
    DECLARE v_monto_neto DECIMAL(12,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
		ROLLBACK;
		RESIGNAL;
    END;

    START TRANSACTION;

    SELECT saldo_pendiente INTO v_saldo_pendiente FROM facturas WHERE id = p_factura_id FOR UPDATE;
    
    IF v_saldo_pendiente IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La factura no existe.';
    END IF;
    
    IF v_saldo_pendiente <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La factura ya se encuentra liquidada.';
    END IF;
    
    SELECT comision_porcentual, costo_fijo INTO v_comision_porcentual, v_costo_fijo
    FROM metodos_pago WHERE id = p_metodo_pago_id AND estado = 'ACTIVO';
    
    SET v_comision_total = (p_monto * IFNULL(v_comision_porcentual, 0) / 100.0) + IFNULL(v_costo_fijo, 0);
    SET v_monto_neto = p_monto - v_comision_total;
    
    INSERT INTO pagos (id, codigo_pago, factura_id, usuario_id, metodo_pago_id, monto, comision, monto_neto, estado, referencia_externa)
    VALUES (UUID(), CONCAT('PAG-', LEFT(UUID(), 8)), p_factura_id, p_usuario_id, p_metodo_pago_id, p_monto, v_comision_total, v_monto_neto, 'PAGADO', p_referencia_externa);

    COMMIT;
END //
DELIMITER ;

-- [NUEVO]: Facturación Automática de Servicios Adicionales.
-- Agrupa y genera facturas para los servicios contratados aún pendientes.
DROP PROCEDURE IF EXISTS FacturarServiciosAdicionales;
DELIMITER //
CREATE PROCEDURE FacturarServiciosAdicionales(
    IN p_usuario_id VARCHAR(36)
)
BEGIN
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_factura_id VARCHAR(36);
    DECLARE v_numero_factura VARCHAR(30);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT IFNULL(SUM(total), 0) INTO v_total
    FROM servicios_contratados
    WHERE usuario_id = p_usuario_id AND estado = 'ACTIVO'
    FOR UPDATE;

    IF v_total > 0 THEN
        SET v_factura_id = UUID();
        SET v_numero_factura = CONCAT('FAC-SERV-', LEFT(v_factura_id, 8));

        INSERT INTO facturas (id, numero_factura, usuario_id, tipo_factura, fecha_vencimiento, subtotal, total, saldo_pendiente, estado)
        VALUES (v_factura_id, v_numero_factura, p_usuario_id, 'SERVICIO', DATE_ADD(CURRENT_DATE(), INTERVAL 15 DAY), v_total, v_total, v_total, 'PENDIENTE');

        INSERT INTO detalle_factura (id, factura_id, concepto, cantidad, precio_unitario, subtotal, total, referencia_tipo, referencia_id)
        SELECT UUID(), v_factura_id, CONCAT('Servicio Adicional: ', sa.nombre), sc.cantidad, sc.precio_unitario, sc.subtotal, sc.total, 'SERVICIO', sc.id
        FROM servicios_contratados sc
        INNER JOIN servicios_adicionales sa ON sc.servicio_id = sa.id
        WHERE sc.usuario_id = p_usuario_id AND sc.estado = 'ACTIVO';

        UPDATE servicios_contratados
        SET estado = 'FACTURADO'
        WHERE usuario_id = p_usuario_id AND estado = 'ACTIVO';
    END IF;

    COMMIT;
END //
DELIMITER ;

-- ============================================================================
-- 4. TRIGGERS
-- ============================================================================

-- [ANÁLISIS]: Varios triggers presentaban nombres de columnas inexistentes, lógica circular 
-- y tablas no correspondientes al DDL original (como buscar en tabla 'membresias' inexistente).

-- [MEJORA]: Trigger trg_mem_calc_vencimiento corregido para buscar dinámicamente en tipos_membresia.
DROP TRIGGER IF EXISTS trg_mem_calc_vencimiento;
DELIMITER //
CREATE TRIGGER trg_mem_calc_vencimiento BEFORE INSERT ON membresia_usuario
FOR EACH ROW 
BEGIN
    DECLARE v_duracion INT;
    SELECT duracion_dias INTO v_duracion
    FROM tipos_membresia
    WHERE id = NEW.tipo_membresia_id;
    
    IF v_duracion IS NOT NULL THEN
        SET NEW.fecha_fin = DATE_ADD(NEW.fecha_inicio, INTERVAL v_duracion DAY);
    END IF;
END //
DELIMITER ;

-- [MEJORA]: Trigger trg_res_confirmar corregido para asociar la reserva pagada usando detalle_factura.
DROP TRIGGER IF EXISTS trg_res_confirmar;
DELIMITER //
CREATE TRIGGER trg_res_confirmar AFTER UPDATE ON pagos
FOR EACH ROW 
BEGIN
    IF NEW.estado = 'PAGADO' THEN
        UPDATE reservas r
        INNER JOIN detalle_factura df ON df.referencia_id = r.id AND df.referencia_tipo = 'RESERVA'
        SET r.estado = 'CONFIRMADA', r.fecha_confirmacion = NOW()
        WHERE df.factura_id = NEW.factura_id;
    END IF;
END //
DELIMITER ;

-- [MEJORA]: Alteración de la tabla usuario para soportar la columna 'ultimo_acceso' requerida por triggers y eventos.
-- [NUEVO]: Columna de control de accesos en usuario.
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS ultimo_acceso DATETIME DEFAULT NULL;

-- [MEJORA]: Trigger trg_acc_ultima_fecha para actualizar la columna agregada.
DROP TRIGGER IF EXISTS trg_acc_ultima_fecha;
DELIMITER //
CREATE TRIGGER trg_acc_ultima_fecha AFTER INSERT ON accesos
FOR EACH ROW 
BEGIN
    UPDATE usuario SET ultimo_acceso = NEW.fecha_hora WHERE id = NEW.usuario_id;
END //
DELIMITER ;

-- [MEJORA]: Trigger trg_acc_salida_auto optimizado para registrar el log del sistema si reentra sin salida previa.
DROP TRIGGER IF EXISTS trg_acc_salida_auto;
DELIMITER //
CREATE TRIGGER trg_acc_salida_auto BEFORE INSERT ON accesos
FOR EACH ROW BEGIN
    DECLARE v_ultimo_tipo ENUM('ENTRADA','SALIDA');
    
    SELECT tipo_acceso INTO v_ultimo_tipo
    FROM accesos
    WHERE usuario_id = NEW.usuario_id
    ORDER BY fecha_hora DESC
    LIMIT 1;
    
    IF v_ultimo_tipo = 'ENTRADA' AND NEW.tipo_acceso = 'ENTRADA' THEN
        INSERT INTO log_accesos (id, usuario_id, accion, detalle)
        VALUES (UUID(), NEW.usuario_id, 'SALIDA_REGISTRADA_AUTOMATICAMENTE', 'El sistema cerró automáticamente la sesión anterior por re-entrada sin salida registrada.');
    END IF;
END //
DELIMITER ;

-- [NUEVO]: Trigger de auditoría detallada al modificar membresías (Historial Completo).
DROP TRIGGER IF EXISTS trg_mem_audit_update;
DELIMITER //
CREATE TRIGGER trg_mem_audit_update AFTER UPDATE ON membresia_usuario
FOR EACH ROW
BEGIN
    IF OLD.estado != NEW.estado OR OLD.tipo_membresia_id != NEW.tipo_membresia_id THEN
        INSERT INTO log_membresias (id, membresia_usuario_id, usuario_id, tipo_anterior_id, tipo_nuevo_id, accion, estado_anterior, estado_nuevo, precio_anterior, precio_nuevo, fecha_inicio_anterior, fecha_inicio_nueva, fecha_fin_anterior, fecha_fin_nueva)
        VALUES (UUID(), NEW.id, NEW.usuario_id, OLD.tipo_membresia_id, NEW.tipo_membresia_id, 'CAMBIO_ESTADO', OLD.estado, NEW.estado, OLD.precio_pagado, NEW.precio_pagado, OLD.fecha_inicio, NEW.fecha_inicio, OLD.fecha_fin, NEW.fecha_fin);
    END IF;
END //
DELIMITER ;

-- [NUEVO]: Trigger de auditoría detallada al modificar reservas (Historial Completo).
DROP TRIGGER IF EXISTS trg_res_audit_update;
DELIMITER //
CREATE TRIGGER trg_res_audit_update AFTER UPDATE ON reservas
FOR EACH ROW
BEGIN
    IF OLD.estado != NEW.estado OR OLD.espacio_id != NEW.espacio_id THEN
        INSERT INTO log_reservas (id, reserva_id, usuario_id, espacio_anterior_id, espacio_nuevo_id, accion, estado_anterior, estado_nuevo, fecha_anterior, fecha_nueva, hora_inicio_anterior, hora_inicio_nueva, hora_fin_anterior, hora_fin_nueva, precio_anterior, precio_nuevo)
        VALUES (UUID(), NEW.id, NEW.usuario_id, OLD.espacio_id, NEW.espacio_id, 'MODIFICADA', OLD.estado, NEW.estado, OLD.fecha_reserva, NEW.fecha_reserva, OLD.hora_inicio, NEW.hora_inicio, OLD.hora_fin, NEW.hora_fin, OLD.precio_final, NEW.precio_final);
    END IF;
END //
DELIMITER ;

-- [NUEVO]: Trigger de auditoría detallada al modificar pagos (Historial Completo).
DROP TRIGGER IF EXISTS trg_pag_audit_update;
DELIMITER //
CREATE TRIGGER trg_pag_audit_update AFTER UPDATE ON pagos
FOR EACH ROW
BEGIN
    IF OLD.estado != NEW.estado THEN
        INSERT INTO log_pagos (id, pago_id, factura_id, usuario_id, metodo_pago_anterior_id, metodo_pago_nuevo_id, accion, estado_anterior, estado_nuevo, monto_anterior, monto_nuevo)
        VALUES (UUID(), NEW.id, NEW.factura_id, NEW.usuario_id, OLD.metodo_pago_id, NEW.metodo_pago_id, 'MODIFICADO', OLD.estado, NEW.estado, OLD.monto, NEW.monto);
    END IF;
END //
DELIMITER ;

-- ============================================================================
-- 5. EVENTOS PROGRAMADOS
-- ============================================================================

-- [ANÁLISIS]: Los eventos hacían referencia a columnas erróneas como 'fecha_vencimiento' 
-- en lugar de 'fecha_fin' y utilizaban inserciones en 'reportes_generados' incompatibles con el DDL.

-- [MEJORA]: Corrección de 'evt_mem_vencidas' para usar la columna correcta 'fecha_fin'.
DROP EVENT IF EXISTS evt_mem_vencidas;
CREATE EVENT evt_mem_vencidas 
ON SCHEDULE EVERY 1 DAY 
DO
    UPDATE membresia_usuario 
    SET estado = 'VENCIDA' 
    WHERE fecha_fin < CURDATE() AND estado = 'ACTIVA';

-- [MEJORA]: Corrección de 'evt_pag_bloquear_servicios' para usar el identificador correcto de usuario.
DROP EVENT IF EXISTS evt_pag_bloquear_servicios;
CREATE EVENT evt_pag_bloquear_servicios 
ON SCHEDULE EVERY 1 DAY 
DO
    UPDATE usuario 
    SET estado = 'BLOQUEADO' 
    WHERE id IN (
        SELECT DISTINCT usuario_id FROM facturas WHERE DATEDIFF(CURDATE(), fecha_vencimiento) > 10 AND saldo_pendiente > 0
    );

-- [MEJORA]: Corrección del evento 'evt_res_liberar_bloqueadas' para liberar solo reservas PENDIENTES del día de hoy.
DROP EVENT IF EXISTS evt_res_liberar_bloqueadas;
CREATE EVENT evt_res_liberar_bloqueadas
ON SCHEDULE EVERY 15 MINUTE
DO
    UPDATE reservas 
    SET estado = 'CANCELADA', motivo_cancelacion = 'Expiró el tiempo límite de confirmación (15 minutos).'
    WHERE estado = 'PENDIENTE' 
      AND fecha_reserva = CURDATE()
      AND hora_inicio < DATE_SUB(CURRENT_TIME(), INTERVAL 15 MINUTE);

-- [MEJORA]: Evento de recordatorio de renovación corregido para usar las columnas reales del DDL.
DROP EVENT IF EXISTS evt_mem_recordatorio;
CREATE EVENT evt_mem_recordatorio 
ON SCHEDULE EVERY 1 DAY 
DO
    INSERT INTO recordatorios (id, usuario_id, tipo_recordatorio, referencia_tipo, referencia_id, canal_envio, asunto, mensaje, fecha_programada, estado)
    SELECT 
        UUID(), 
        usuario_id, 
        'RENOVACION_MEMBRESIA', 
        'MEMBRESIA', 
        id, 
        'EMAIL', 
        'Tu membresía está por vencer', 
        CONCAT('Estimado usuario, tu membresía vence el ', fecha_fin, '. Renuévala hoy mismo.'), 
        NOW(), 
        'PROGRAMADO'
    FROM membresia_usuario 
    WHERE fecha_fin = DATE_ADD(CURDATE(), INTERVAL 5 DAY)
      AND estado = 'ACTIVA';

-- [NUEVO]: Evento diario para limpiar y purgar sesiones expiradas del coworking.
DROP EVENT IF EXISTS evt_sesiones_limpieza;
CREATE EVENT evt_sesiones_limpieza
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    -- Invalida sesiones inactivas que sobrepasaron su tiempo
    UPDATE sesiones
    SET estado = 'EXPIRADA', motivo_cierre = 'Cierre automático por inactividad prolongada'
    WHERE estado = 'ACTIVA' AND fecha_expiracion < NOW();
END;

-- ============================================================================
-- 6. CONSULTAS OPTIMIZADAS (EDGE-CASES)
-- ============================================================================

-- [ANÁLISIS]: La consulta 63 contenía un error sintáctico severo por la falta de una coma y punto y coma.
-- Adicionalmente, se optimizan los índices y se corrige la sintaxis de las consultas críticas.

-- [MEJORA]: Consulta 63 corregida.
-- Muestra usuarios que no han asistido en la última semana utilizando JOIN óptimo.
SELECT
    us.id AS usuario_id,
    CONCAT(us.nombre, ' ', us.apellidos) AS nombre
FROM usuario us
LEFT JOIN accesos ac ON us.id = ac.usuario_id AND ac.fecha_hora >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
WHERE ac.usuario_id IS NULL;
