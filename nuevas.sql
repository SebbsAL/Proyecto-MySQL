-- ============================================================================
-- PROYECTO COWORKING - NUEVAS UTILIDADES Y FUNCIONALIDADES SQL (ULTRA-COMPLETO)
-- Rol: Senior Database Architect / Developer
-- ============================================================================

USE coworking;

-- ============================================================================
-- 1. SEGURIDAD Y ROLES ADICIONALES
-- ============================================================================

-- Creación de roles de seguridad especializados
CREATE ROLE IF NOT EXISTS 'Auditor_Seguridad', 'Soporte_Tecnico';

-- Asignación de privilegios para Auditor_Seguridad
-- Permite visualizar registros de auditoría detallados e intentos fallidos
GRANT SELECT ON coworking.log_membresias TO 'Auditor_Seguridad';
GRANT SELECT ON coworking.log_reservas TO 'Auditor_Seguridad';
GRANT SELECT ON coworking.log_pagos TO 'Auditor_Seguridad';
GRANT SELECT ON coworking.intentos_acceso_rechazados TO 'Auditor_Seguridad';
GRANT SELECT ON coworking.accesos TO 'Auditor_Seguridad';

-- Asignación de privilegios para Soporte_Tecnico
-- Permite dar soporte sobre las credenciales de acceso físicas/digitales y ver accesos
GRANT SELECT, INSERT, UPDATE, DELETE ON coworking.credenciales_acceso TO 'Soporte_Tecnico';
GRANT SELECT ON coworking.accesos TO 'Soporte_Tecnico';
GRANT SELECT, UPDATE ON coworking.usuario TO 'Soporte_Tecnico';

FLUSH PRIVILEGES;

-- ============================================================================
-- 2. VISTAS OPERATIVAS Y ANALÍTICAS
-- ============================================================================

-- Vista: Facturas Vencidas con Días de Atraso e Interés Proyectado
-- Permite al equipo de contabilidad y cobranza monitorear facturas vencidas con un 2% de interés moratorio mensual simulado.
CREATE OR REPLACE VIEW coworking.vista_facturas_vencidas_detalle AS
SELECT 
    f.id AS factura_id,
    f.numero_factura,
    u.identificacion AS usuario_identificacion,
    CONCAT(u.nombre, ' ', u.apellidos) AS usuario_nombre,
    u.email AS usuario_email,
    f.tipo_factura,
    f.fecha_emision,
    f.fecha_vencimiento,
    f.total,
    f.saldo_pendiente,
    DATEDIFF(CURDATE(), f.fecha_vencimiento) AS dias_atraso,
    ROUND(f.saldo_pendiente * (0.02 / 30) * DATEDIFF(CURDATE(), f.fecha_vencimiento), 2) AS interes_mora_proyectado
FROM coworking.facturas f
INNER JOIN coworking.usuario u ON f.usuario_id = u.id
WHERE f.estado IN ('PENDIENTE', 'PARCIAL', 'VENCIDA')
  AND f.fecha_vencimiento < CURDATE();

-- Vista: Disponibilidad de Espacios para el Día de Hoy
-- Muestra de un vistazo rápido qué espacios están libres u ocupados hoy.
CREATE OR REPLACE VIEW coworking.vista_espacios_disponibilidad_hoy AS
SELECT 
    e.id AS espacio_id,
    e.codigo AS espacio_codigo,
    e.nombre AS espacio_nombre,
    te.nombre AS tipo_espacio,
    e.piso,
    e.capacidad,
    e.estado AS estado_operativo,
    (
        SELECT COUNT(*) 
        FROM coworking.reservas r 
        WHERE r.espacio_id = e.id 
          AND r.fecha_reserva = CURDATE() 
          AND r.estado IN ('CONFIRMADA', 'COMPLETADA')
    ) AS cantidad_reservas_hoy
FROM coworking.espacios e
INNER JOIN coworking.tipos_espacios te ON e.tipo_espacio_id = te.id;

-- Vista: Resumen de Consumo Corporativo por Empresa
-- Provee métricas acumuladas de compras de membresías, servicios y horas de reservas para cada empresa.
CREATE OR REPLACE VIEW coworking.vista_resumen_empresas_consumo AS
SELECT 
    emp.id AS empresa_id,
    emp.nombre AS empresa_nombre,
    emp.razon_social,
    COUNT(DISTINCT u.id) AS total_usuarios_activos,
    IFNULL(SUM(f.total), 0.00) AS total_facturado_acumulado,
    IFNULL(
        (SELECT SUM(r.duracion_horas) 
         FROM coworking.reservas r 
         INNER JOIN coworking.usuario usr ON r.usuario_id = usr.id 
         WHERE usr.empresa_id = emp.id AND r.estado = 'COMPLETADA'
        ), 0.00
    ) AS total_horas_usadas
FROM coworking.empresas emp
LEFT JOIN coworking.usuario u ON u.empresa_id = emp.id AND u.estado = 'ACTIVO'
LEFT JOIN coworking.facturas f ON f.empresa_id = emp.id AND f.estado = 'PAGADA'
GROUP BY emp.id, emp.nombre, emp.razon_social;

-- Vista: Resumen de Facturación y Comisiones por Método de Pago
-- Muestra los ingresos brutos, comisiones calculadas y neto recibido por cada canal de pago.
CREATE OR REPLACE VIEW coworking.vista_facturacion_por_metodo AS
SELECT 
    mp.codigo AS metodo_codigo,
    mp.nombre AS metodo_nombre,
    COUNT(p.id) AS transacciones_exitosas,
    IFNULL(SUM(p.monto), 0.00) AS total_bruto,
    IFNULL(SUM(p.comision), 0.00) AS comisiones_totales,
    IFNULL(SUM(p.monto_neto), 0.00) AS total_neto
FROM coworking.metodos_pago mp
LEFT JOIN coworking.pagos p ON p.metodo_pago_id = mp.id AND p.estado = 'PAGADO'
GROUP BY mp.id, mp.codigo, mp.nombre;

-- Vista: Detalle aplanado de equipamiento extra de espacios físicos
-- Extrae las especificaciones de equipamiento de tipo JSON de forma relacional.
CREATE OR REPLACE VIEW coworking.vista_detalles_equipamiento AS
SELECT 
    e.codigo AS espacio_codigo,
    e.nombre AS espacio_nombre,
    JSON_UNQUOTE(JSON_EXTRACT(e.equipamiento_extra, '$')) AS equipamiento_completo
FROM coworking.espacios e
WHERE e.equipamiento_extra IS NOT NULL;

-- Vista: Alertas de Seguridad Recientes (Últimas 48 horas)
-- Filtra accesos fallidos y sospechosos para monitoreo inmediato
CREATE OR REPLACE VIEW coworking.vista_alertas_seguridad_recientes AS
SELECT 
    iar.id AS alerta_id,
    iar.fecha_hora,
    iar.punto_acceso,
    iar.motivo_rechazo,
    iar.descripcion_detallada,
    u.identificacion AS usuario_identificacion,
    CONCAT(u.nombre, ' ', u.apellidos) AS usuario_nombre,
    iar.dispositivo,
    iar.ip_origen
FROM coworking.intentos_acceso_rechazados iar
LEFT JOIN coworking.usuario u ON iar.usuario_id = u.id
WHERE iar.estado = 'REGISTRADO' 
  AND iar.motivo_rechazo IN ('CREDENCIAL_REVOCADA', 'INTENTOS_EXCEDIDOS', 'SOSPECHA_FRAUDE', 'HORARIO_NO_PERMITIDO')
  AND iar.fecha_hora >= DATE_SUB(NOW(), INTERVAL 2 DAY);


-- ============================================================================
-- 3. PROCEDIMIENTOS ALMACENADOS (CON TRANSACCIONES ACID Y CONCURRENCIA)
-- ============================================================================

-- Procedimiento: Registrar Consumo de Servicio Adicional
-- Maneja de manera segura la contratación de un servicio adicional, validando el stock.
DROP PROCEDURE IF EXISTS RegistrarConsumoServicio;
DELIMITER //
CREATE PROCEDURE RegistrarConsumoServicio(
    IN p_usuario_id VARCHAR(36),
    IN p_servicio_id VARCHAR(36),
    IN p_reserva_id VARCHAR(36),
    IN p_cantidad DECIMAL(8,2),
    IN p_fecha_uso DATE,
    IN p_hora_inicio TIME,
    IN p_hora_fin TIME,
    IN p_notes TEXT
)
BEGIN
    DECLARE v_disponibilidad_limitada BOOLEAN;
    DECLARE v_stock INT;
    DECLARE v_precio_unitario DECIMAL(10,2);
    DECLARE v_impuesto_aplicable DECIMAL(5,2);
    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_impuesto_total DECIMAL(10,2);
    DECLARE v_total_final DECIMAL(10,2);
    DECLARE v_unidad_cobro VARCHAR(20);
    DECLARE v_servicio_contratado_id VARCHAR(36);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validaciones de Entrada
    IF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La cantidad de consumo debe ser mayor a cero.';
    END IF;
    IF p_hora_fin IS NOT NULL AND p_hora_inicio IS NOT NULL AND p_hora_fin <= p_hora_inicio THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La hora de fin debe ser posterior a la hora de inicio.';
    END IF;

    START TRANSACTION;

    -- Bloqueo de fila para evitar condiciones de carrera en stock
    SELECT disponibilidad_limitada, stock_disponible, precio_unitario, impuesto_aplicable, unidad_cobro
    INTO v_disponibilidad_limitada, v_stock, v_precio_unitario, v_impuesto_aplicable, v_unidad_cobro
    FROM coworking.servicios_adicionales
    WHERE id = p_servicio_id AND estado = 'ACTIVO'
    FOR UPDATE;

    IF v_precio_unitario IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El servicio seleccionado no existe o está inactivo.';
    END IF;

    -- Validar disponibilidad limitada
    IF v_disponibilidad_limitada = TRUE THEN
        IF v_stock < p_cantidad THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Stock insuficiente para el servicio solicitado.';
        END IF;
        
        -- Reducir el stock del servicio
        UPDATE coworking.servicios_adicionales
        SET stock_disponible = stock_disponible - CAST(p_cantidad AS SIGNED)
        WHERE id = p_servicio_id;
    END IF;

    -- Cálculos financieros
    SET v_subtotal = v_precio_unitario * p_cantidad;
    SET v_impuesto_total = v_subtotal * (IFNULL(v_impuesto_aplicable, 0.00) / 100.00);
    SET v_total_final = v_subtotal + v_impuesto_total;
    SET v_servicio_contratado_id = UUID();

    -- Inserción del consumo contratado
    INSERT INTO coworking.servicios_contratados (
        id, codigo, usuario_id, servicio_id, reserva_id, fecha_uso, hora_inicio, hora_fin,
        cantidad, unidad_cobro, precio_unitario, subtotal, impuesto, descuento, total, estado, notas
    ) VALUES (
        v_servicio_contratado_id,
        CONCAT('SC-', LEFT(v_servicio_contratado_id, 8)),
        p_usuario_id,
        p_servicio_id,
        p_reserva_id,
        p_fecha_uso,
        p_hora_inicio,
        p_hora_fin,
        p_cantidad,
        v_unidad_cobro,
        v_precio_unitario,
        v_subtotal,
        v_impuesto_total,
        0.00,
        v_total_final,
        'ACTIVO',
        p_notes
    );

    COMMIT;
    SELECT v_servicio_contratado_id AS id_servicio_contratado;
END //
DELIMITER ;

-- Procedimiento: Renovar Membresía del Usuario
-- Permite renovar la membresía de un usuario de forma limpia y transparente
DROP PROCEDURE IF EXISTS RenovarMembresiaUsuario;
DELIMITER //
CREATE PROCEDURE RenovarMembresiaUsuario(
    IN p_usuario_id VARCHAR(36),
    IN p_tipo_membresia_id VARCHAR(36)
)
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_duracion INT;
    DECLARE v_fecha_inicio DATE;
    DECLARE v_fecha_fin DATE;
    DECLARE v_ultimo_estado VARCHAR(20);
    DECLARE v_ultima_fecha_fin DATE;
    DECLARE v_membresia_id VARCHAR(36);
    DECLARE v_factura_id VARCHAR(36);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Obtener especificaciones del nuevo tipo de membresía
    SELECT duracion_dias, precio_base INTO v_duracion, v_precio
    FROM coworking.tipos_membresia
    WHERE id = p_tipo_membresia_id AND estado = 'ACTIVO'
    FOR UPDATE;

    IF v_duracion IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Tipo de membresía inválido o inactivo.';
    END IF;

    -- Obtener estado de membresías actuales
    SELECT estado, fecha_fin INTO v_ultimo_estado, v_ultima_fecha_fin
    FROM coworking.membresia_usuario
    WHERE usuario_id = p_usuario_id
    ORDER BY fecha_fin DESC, fecha_contratacion DESC
    LIMIT 1
    FOR UPDATE;

    -- Definir fecha de inicio de renovación
    IF v_ultimo_estado = 'ACTIVA' AND v_ultima_fecha_fin >= CURDATE() THEN
        SET v_fecha_inicio = DATE_ADD(v_ultima_fecha_fin, INTERVAL 1 DAY);
    ELSE
        SET v_fecha_inicio = CURDATE();
    END IF;

    SET v_fecha_fin = DATE_ADD(v_fecha_inicio, INTERVAL v_duracion DAY);
    SET v_membresia_id = UUID();
    SET v_factura_id = UUID();

    -- Registrar nueva membresía
    INSERT INTO coworking.membresia_usuario (
        id, usuario_id, tipo_membresia_id, fecha_inicio, fecha_fin, estado, precio_pagado
    ) VALUES (
        v_membresia_id, p_usuario_id, p_tipo_membresia_id, v_fecha_inicio, v_fecha_fin, 'ACTIVA', v_precio
    );

    -- Generar factura pendiente de pago para la renovación
    INSERT INTO coworking.facturas (
        id, numero_factura, usuario_id, tipo_factura, fecha_vencimiento, subtotal, impuesto, descuento, total, saldo_pendiente, estado, observaciones
    ) VALUES (
        v_factura_id,
        CONCAT('FAC-MEM-', LEFT(v_factura_id, 8)),
        p_usuario_id,
        'MEMBRESIA',
        DATE_ADD(CURDATE(), INTERVAL 5 DAY),
        v_precio,
        0.00,
        0.00,
        v_precio,
        v_precio,
        'PENDIENTE',
        CONCAT('Facturación de renovación de membresía hasta el ', v_fecha_fin)
    );

    -- Insertar el detalle de la factura
    INSERT INTO coworking.detalle_factura (
        id, factura_id, concepto, cantidad, precio_unitario, subtotal, impuesto, descuento, total, referencia_tipo, referencia_id
    ) VALUES (
        UUID(), v_factura_id, 'Renovación de Membresía Coworking', 1.00, v_precio, v_precio, 0.00, 0.00, v_precio, 'MEMBRESIA', v_membresia_id
    );

    COMMIT;
    SELECT v_membresia_id AS id_membresia_renovada, v_factura_id AS id_factura_generada;
END //
DELIMITER ;

-- Procedimiento: Reprogramar Reserva
-- Valida disponibilidad en el nuevo horario y realiza el cambio modificando importes si es necesario.
DROP PROCEDURE IF EXISTS ReprogramarReserva;
DELIMITER //
CREATE PROCEDURE ReprogramarReserva(
    IN p_reserva_id VARCHAR(36),
    IN p_nueva_fecha DATE,
    IN p_nueva_hora_inicio TIME,
    IN p_nueva_hora_fin TIME
)
BEGIN
    DECLARE v_espacio_id VARCHAR(36);
    DECLARE v_usuario_id VARCHAR(36);
    DECLARE v_duracion DECIMAL(5,2);
    DECLARE v_precio_base DECIMAL(10,2);
    DECLARE v_nuevo_precio_total DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validaciones de Entrada
    IF p_nueva_fecha < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se puede reprogramar una reserva para una fecha en el pasado.';
    END IF;
    IF p_nueva_hora_fin <= p_nueva_hora_inicio THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La nueva hora de fin debe ser posterior a la hora de inicio.';
    END IF;

    START TRANSACTION;

    -- Obtener la reserva actual
    SELECT espacio_id, usuario_id INTO v_espacio_id, v_usuario_id
    FROM coworking.reservas
    WHERE id = p_reserva_id AND estado IN ('PENDIENTE', 'CONFIRMADA')
    FOR UPDATE;

    IF v_usuario_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La reserva no existe o no se puede reprogramar en su estado actual.';
    END IF;

    -- Validar solapamiento ignorando la propia reserva que se está modificando
    IF (
        SELECT COUNT(*)
        FROM coworking.reservas
        WHERE espacio_id = v_espacio_id
          AND fecha_reserva = p_nueva_fecha
          AND id != p_reserva_id
          AND estado IN ('PENDIENTE', 'CONFIRMADA')
          AND p_nueva_hora_inicio < hora_fin
          AND p_nueva_hora_fin > hora_inicio
    ) > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El espacio ya está reservado en ese horario para la nueva fecha.';
    END IF;

    -- Calcular costos del nuevo horario
    SET v_duracion = TIMESTAMPDIFF(MINUTE, p_nueva_hora_inicio, p_nueva_hora_fin) / 60.0;
    
    SELECT COALESCE(e.precio_personalizado, te.tarifa_base_hora) INTO v_precio_base 
    FROM coworking.espacios e
    INNER JOIN coworking.tipos_espacios te ON e.tipo_espacio_id = te.id 
    WHERE e.id = v_espacio_id;

    SET v_nuevo_precio_total = v_duracion * v_precio_base;

    -- Actualizar reserva
    UPDATE coworking.reservas
    SET fecha_reserva = p_nueva_fecha,
        hora_inicio = p_nueva_hora_inicio,
        hora_fin = p_nueva_hora_fin,
        duracion_horas = v_duracion,
        precio_total = v_nuevo_precio_total,
        precio_final = v_nuevo_precio_total - descuento_aplicado,
        notes = CONCAT(IFNULL(notes, ''), ' | Reprogramada el ', NOW())
    WHERE id = p_reserva_id;

    COMMIT;
    SELECT 'Reserva reprogramada con éxito' AS mensaje, v_nuevo_precio_total AS nuevo_precio_total;
END //
DELIMITER ;

-- Procedimiento: Crear Reservas Recurrentes
-- Genera múltiples reservas secuenciales en el tiempo bajo un mismo código padre
DROP PROCEDURE IF EXISTS CrearReservasRecurrentes;
DELIMITER //
CREATE PROCEDURE CrearReservasRecurrentes(
    IN p_usuario_id VARCHAR(36),
    IN p_espacio_id VARCHAR(36),
    IN p_fecha_inicio DATE,
    IN p_hora_inicio TIME,
    IN p_hora_fin TIME,
    IN p_intervalo ENUM('DIARIO', 'SEMANAL'),
    IN p_repeticiones INT,
    IN p_asistentes INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE v_contador INT DEFAULT 0;
    DECLARE v_fecha_reserva DATE;
    DECLARE v_padre_id VARCHAR(36);
    DECLARE v_reserva_id VARCHAR(36);
    DECLARE v_precio_base DECIMAL(10,2);
    DECLARE v_duracion DECIMAL(5,2);
    DECLARE v_precio_total DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validaciones de Entrada
    IF p_fecha_inicio < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La fecha de inicio no puede ser en el pasado.';
    END IF;
    IF p_hora_fin <= p_hora_inicio THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La hora de fin debe ser posterior a la hora de inicio.';
    END IF;
    IF p_repeticiones <= 0 OR p_asistentes <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Repeticiones y asistentes deben ser mayores a cero.';
    END IF;

    START TRANSACTION;

    SET v_padre_id = UUID();
    SET v_fecha_reserva = p_fecha_inicio;
    SET v_duracion = TIMESTAMPDIFF(MINUTE, p_hora_inicio, p_hora_fin) / 60.0;

    SELECT COALESCE(e.precio_personalizado, te.tarifa_base_hora) INTO v_precio_base 
    FROM coworking.espacios e
    INNER JOIN coworking.tipos_espacios te ON e.tipo_espacio_id = te.id 
    WHERE e.id = p_espacio_id;

    SET v_precio_total = v_duracion * v_precio_base;

    WHILE v_contador < p_repeticiones DO
        -- Verificar solapamiento de la reserva individual
        IF (
            SELECT COUNT(*) 
            FROM coworking.reservas 
            WHERE espacio_id = p_espacio_id 
              AND fecha_reserva = v_fecha_reserva
              AND estado IN ('PENDIENTE','CONFIRMADA')
              AND p_hora_inicio < hora_fin 
              AND p_hora_fin > hora_inicio
        ) = 0 THEN
            SET v_reserva_id = IF(v_contador = 0, v_padre_id, UUID());
            
            INSERT INTO coworking.reservas (
                id, codigo, usuario_id, espacio_id, reserva_padre_id, fecha_reserva, hora_inicio, hora_fin,
                duracion_horas, numero_asistentes, motivo, estado, precio_total, precio_final, es_recurrente, notes
            ) VALUES (
                v_reserva_id,
                CONCAT('REC-', LEFT(v_reserva_id, 8)),
                p_usuario_id,
                p_espacio_id,
                IF(v_contador = 0, NULL, v_padre_id),
                v_fecha_reserva,
                p_hora_inicio,
                p_hora_fin,
                v_duracion,
                p_asistentes,
                p_motivo,
                'PENDIENTE',
                v_precio_total,
                v_precio_total,
                TRUE,
                CONCAT('Reserva recurrente N. ', v_contador + 1)
            );
        END IF;

        SET v_contador = v_contador + 1;
        IF p_intervalo = 'DIARIO' THEN
            SET v_fecha_reserva = DATE_ADD(v_fecha_reserva, INTERVAL 1 DAY);
        ELSE
            SET v_fecha_reserva = DATE_ADD(v_fecha_reserva, INTERVAL 1 WEEK);
        END IF;
    END WHILE;

    COMMIT;
    SELECT v_padre_id AS id_reserva_padre_creada, v_contador AS cantidad_generada;
END //
DELIMITER ;

-- Procedimiento: Generar Factura Consolidada Mensual
-- Agrupa todos los consumos pendientes de un usuario y genera una sola factura del periodo
DROP PROCEDURE IF EXISTS GenerarFacturaConsolidadaMensual;
DELIMITER //
CREATE PROCEDURE GenerarFacturaConsolidadaMensual(
    IN p_usuario_id VARCHAR(36)
)
BEGIN
    DECLARE v_empresa_id VARCHAR(36);
    DECLARE v_total_servicios DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_total_reservas DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_factura_id VARCHAR(36);
    DECLARE v_subtotal_general DECIMAL(12,2);
    DECLARE v_total_general DECIMAL(12,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT empresa_id INTO v_empresa_id FROM coworking.usuario WHERE id = p_usuario_id;

    -- Sumar total de consumos de servicios en estado 'ACTIVO' o 'PENDIENTE'
    SELECT IFNULL(SUM(total), 0.00) INTO v_total_servicios
    FROM coworking.servicios_contratados
    WHERE usuario_id = p_usuario_id AND estado = 'ACTIVO';

    -- Sumar total de reservas completadas que no estén facturadas aún
    SELECT IFNULL(SUM(precio_final), 0.00) INTO v_total_reservas
    FROM coworking.reservas
    WHERE usuario_id = p_usuario_id AND estado = 'COMPLETADA'
      AND NOT EXISTS (
          SELECT 1 FROM coworking.detalle_factura df 
          WHERE df.referencia_id = reservas.id AND df.referencia_tipo = 'RESERVA'
      );

    SET v_subtotal_general = v_total_servicios + v_total_reservas;

    IF v_subtotal_general > 0 THEN
        SET v_factura_id = UUID();
        SET v_total_general = v_subtotal_general;

        -- Crear factura consolidada
        INSERT INTO coworking.facturas (
            id, numero_factura, usuario_id, empresa_id, tipo_factura, fecha_vencimiento, subtotal, impuesto, descuento, total, saldo_pendiente, estado, observaciones
        ) VALUES (
            v_factura_id,
            CONCAT('FAC-CONS-', LEFT(v_factura_id, 8)),
            p_usuario_id,
            v_empresa_id,
            'CONSOLIDADA',
            DATE_ADD(CURDATE(), INTERVAL 10 DAY),
            v_subtotal_general,
            0.00,
            0.00,
            v_total_general,
            v_total_general,
            'PENDIENTE',
            'Facturación consolidada de consumos y reservas del mes.'
        );

        -- Insertar los detalles de servicios
        INSERT INTO coworking.detalle_factura (
            id, factura_id, concepto, cantidad, precio_unitario, subtotal, impuesto, descuento, total, referencia_tipo, referencia_id
        )
        SELECT 
            UUID(),
            v_factura_id,
            CONCAT('Servicio contratado: ', sa.nombre),
            sc.cantidad,
            sc.precio_unitario,
            sc.subtotal,
            sc.impuesto,
            sc.descuento,
            sc.total,
            'SERVICIO',
            sc.id
        FROM coworking.servicios_contratados sc
        INNER JOIN coworking.servicios_adicionales sa ON sc.servicio_id = sa.id
        WHERE sc.usuario_id = p_usuario_id AND sc.estado = 'ACTIVO';

        -- Insertar los detalles de reservas
        INSERT INTO coworking.detalle_factura (
            id, factura_id, concepto, cantidad, precio_unitario, subtotal, impuesto, descuento, total, referencia_tipo, referencia_id
        )
        SELECT 
            UUID(),
            v_factura_id,
            CONCAT('Reserva de espacio: ', e.nombre, ' (', r.fecha_reserva, ')'),
            1.00,
            r.precio_final,
            r.precio_final,
            0.00,
            r.descuento_aplicado,
            r.precio_final,
            'RESERVA',
            r.id
        FROM coworking.reservas r
        INNER JOIN coworking.espacios e ON r.espacio_id = e.id
        WHERE r.usuario_id = p_usuario_id AND r.estado = 'COMPLETADA'
          AND NOT EXISTS (
              SELECT 1 FROM coworking.detalle_factura df 
              WHERE df.referencia_id = r.id AND df.referencia_tipo = 'RESERVA'
          );

        -- Actualizar los estados de los servicios contratados facturados
        UPDATE coworking.servicios_contratados
        SET estado = 'FACTURADO'
        WHERE usuario_id = p_usuario_id AND estado = 'ACTIVO';

    END IF;

    COMMIT;
    SELECT v_factura_id AS id_factura_consolidada;
END //
DELIMITER ;

-- Procedimiento: Registrar Mantenimiento de Espacio Físico
-- Pone un espacio en mantenimiento y cancela de forma atómica todas las reservas futuras en este.
DROP PROCEDURE IF EXISTS RegistrarMantenimientoEspacio;
DELIMITER //
CREATE PROCEDURE RegistrarMantenimientoEspacio(
    IN p_espacio_id VARCHAR(36),
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Poner espacio en mantenimiento
    UPDATE coworking.espacios
    SET estado = 'MANTENIMIENTO'
    WHERE id = p_espacio_id;

    -- Insertar registros en log_reservas para todas las reservas que serán canceladas
    INSERT INTO coworking.log_reservas (
        id, reserva_id, usuario_id, espacio_anterior_id, espacio_nuevo_id, usuario_sistema_id,
        accion, estado_anterior, estado_nuevo, fecha_anterior, fecha_nueva,
        hora_inicio_anterior, hora_inicio_nueva, hora_fin_anterior, hora_fin_nueva,
        precio_anterior, precio_nuevo, motivo
    )
    SELECT 
        UUID(), r.id, r.usuario_id, r.espacio_id, r.espacio_id, 'SISTEMA',
        'CANCELADA', r.estado, 'CANCELADA', r.fecha_reserva, r.fecha_reserva,
        r.hora_inicio, r.hora_inicio, r.hora_fin, r.hora_fin,
        r.precio_final, r.precio_final, CONCAT('Cancelación automática por mantenimiento: ', p_motivo)
    FROM coworking.reservas r
    WHERE r.espacio_id = p_espacio_id 
      AND r.fecha_reserva >= CURDATE()
      AND r.estado IN ('PENDIENTE', 'CONFIRMADA');

    -- Cancelar reservas futuras asociadas al espacio
    UPDATE coworking.reservas
    SET estado = 'CANCELADA',
        fecha_cancelacion = NOW(),
        motivo_cancelacion = CONCAT('Cancelado por mantenimiento del espacio: ', p_motivo)
    WHERE espacio_id = p_espacio_id
      AND fecha_reserva >= CURDATE()
      AND estado IN ('PENDIENTE', 'CONFIRMADA');

    COMMIT;
    SELECT 'Mantenimiento registrado y reservas del espacio canceladas con éxito' AS mensaje;
END //
DELIMITER ;

-- Procedimiento: Liquidar Factura con Pago (Atomic & Secure)
-- Registra un pago y liquida la factura modificando el estado del documento fiscal
DROP PROCEDURE IF EXISTS LiquidarFacturaConPago;
DELIMITER //
CREATE PROCEDURE LiquidarFacturaConPago(
    IN p_factura_id VARCHAR(36),
    IN p_usuario_id VARCHAR(36),
    IN p_metodo_pago_id VARCHAR(36),
    IN p_monto DECIMAL(12,2),
    IN p_referencia_externa VARCHAR(100),
    IN p_notas TEXT
)
BEGIN
    DECLARE v_saldo_pendiente DECIMAL(12,2);
    DECLARE v_comision_porcentual DECIMAL(5,2);
    DECLARE v_costo_fijo DECIMAL(10,2);
    DECLARE v_comision_total DECIMAL(10,2);
    DECLARE v_monto_neto DECIMAL(12,2);
    DECLARE v_nuevo_saldo DECIMAL(12,2);
    DECLARE v_tipo_factura VARCHAR(20);
    DECLARE v_pago_id VARCHAR(36);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Bloqueo de factura para asegurar consistencia
    SELECT saldo_pendiente, tipo_factura INTO v_saldo_pendiente, v_tipo_factura
    FROM coworking.facturas
    WHERE id = p_factura_id
    FOR UPDATE;

    IF v_saldo_pendiente IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La factura especificada no existe.';
    END IF;

    IF v_saldo_pendiente <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La factura ya se encuentra liquidada.';
    END IF;

    -- Calcular comisiones del método de pago
    SELECT comision_porcentual, costo_fijo INTO v_comision_porcentual, v_costo_fijo
    FROM coworking.metodos_pago
    WHERE id = p_metodo_pago_id AND estado = 'ACTIVO'
    FOR UPDATE;

    SET v_comision_total = (p_monto * IFNULL(v_comision_porcentual, 0.00) / 100.00) + IFNULL(v_costo_fijo, 0.00);
    SET v_monto_neto = p_monto - v_comision_total;
    SET v_nuevo_saldo = v_saldo_pendiente - p_monto;
    SET v_pago_id = UUID();

    -- Registrar el pago
    INSERT INTO coworking.pagos (
        id, codigo_pago, factura_id, usuario_id, metodo_pago_id, monto, comision, monto_neto, estado, referencia_externa, notas
    ) VALUES (
        v_pago_id,
        CONCAT('PAG-', LEFT(v_pago_id, 8)),
        p_factura_id,
        p_usuario_id,
        p_metodo_pago_id,
        p_monto,
        v_comision_total,
        v_monto_neto,
        'PAGADO',
        p_referencia_externa,
        p_notas
    );

    -- Actualizar los saldos de la factura
    UPDATE coworking.facturas
    SET saldo_pendiente = IF(v_nuevo_saldo < 0, 0.00, v_nuevo_saldo),
        estado = IF(v_nuevo_saldo <= 0, 'PAGADA', 'PARCIAL')
    WHERE id = p_factura_id;

    -- Si se liquida una factura de membresía, activar membresía de usuario
    IF v_tipo_factura = 'MEMBRESIA' AND v_nuevo_saldo <= 0 THEN
        UPDATE coworking.membresia_usuario mu
        INNER JOIN coworking.detalle_factura df ON df.referencia_id = mu.id AND df.referencia_tipo = 'MEMBRESIA'
        SET mu.estado = 'ACTIVA'
        WHERE df.factura_id = p_factura_id;
    END IF;

    COMMIT;
    SELECT 'Pago procesado exitosamente' AS mensaje, IF(v_nuevo_saldo < 0, 0.00, v_nuevo_saldo) AS saldo_restante;
END //
DELIMITER ;

-- Procedimiento: Registrar Acceso Físico Manual
-- Permite dar entrada o salida a un usuario validando dinámicamente sus privilegios
DROP PROCEDURE IF EXISTS RegistrarAccesoManual;
DELIMITER //
CREATE PROCEDURE RegistrarAccesoManual(
    IN p_usuario_id VARCHAR(36),
    IN p_tipo_acceso ENUM('ENTRADA', 'SALIDA'),
    IN p_punto_acceso VARCHAR(100),
    IN p_notas TEXT
)
BEGIN
    DECLARE v_credencial_id VARCHAR(36);
    DECLARE v_permitido BOOLEAN;
    DECLARE v_membresia_estado VARCHAR(20);
    DECLARE v_reserva_estado VARCHAR(20) DEFAULT 'SIN_RESERVA';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Obtener la credencial activa del usuario
    SELECT id INTO v_credencial_id 
    FROM coworking.credenciales_acceso 
    WHERE usuario_id = p_usuario_id AND estado = 'ACTIVA' 
    LIMIT 1;

    -- Validar si tiene permitido el ingreso usando la función lógica
    SET v_permitido = fn_verificar_acceso_permitido(p_usuario_id);

    IF v_permitido = FALSE AND p_tipo_acceso = 'ENTRADA' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Acceso manual denegado. El usuario no posee membresía ni reservas activas hoy.';
    END IF;

    -- Determinar estado de membresía para auditoría
    SELECT fn_estado_membresia(p_usuario_id) INTO v_membresia_estado;

    IF EXISTS (
        SELECT 1 FROM coworking.reservas 
        WHERE usuario_id = p_usuario_id AND fecha_reserva = CURDATE() AND estado = 'CONFIRMADA'
    ) THEN
        SET v_reserva_estado = 'CON_RESERVA';
    END IF;

    -- Registrar el acceso manual
    INSERT INTO coworking.accesos (
        id, usuario_id, credencial_id, tipo_acceso, metodo_validacion, fecha_hora, punto_acceso,
        validacion_membresia, validacion_reserva, estado, notas
    ) VALUES (
        UUID(),
        p_usuario_id,
        IFNULL(v_credencial_id, 'SISTEMA'),
        p_tipo_acceso,
        'MANUAL',
        NOW(),
        p_punto_acceso,
        IF(v_membresia_estado = 'ACTIVA', 'ACTIVA', 'SIN_MEMBRESIA'),
        v_reserva_estado,
        'PERMITIDO',
        CONCAT('Acceso manual registrado en recepción. Notas: ', IFNULL(p_notas, ''))
    );

    COMMIT;
    SELECT 'Acceso manual registrado exitosamente' AS mensaje;
END //
DELIMITER ;

-- Procedimiento: Registrar Salidas Faltantes del Día
-- Ejecuta una depuración automática insertando marcas de SALIDA a las 20:00:00 para usuarios sin checkout.
DROP PROCEDURE IF EXISTS RegistrarSalidasFaltantes;
DELIMITER //
CREATE PROCEDURE RegistrarSalidasFaltantes()
BEGIN
    DECLARE v_usuario_id VARCHAR(36);
    DECLARE v_fecha_hora DATETIME;
    DECLARE v_credencial_id VARCHAR(36);
    DECLARE done INT DEFAULT FALSE;
    
    -- Cursor para seleccionar accesos de tipo ENTRADA del día de hoy que no tienen una SALIDA posterior
    DECLARE cur CURSOR FOR 
        SELECT a1.usuario_id, a1.fecha_hora, a1.credencial_id
        FROM coworking.accesos a1
        WHERE DATE(a1.fecha_hora) = CURDATE() 
          AND a1.tipo_acceso = 'ENTRADA'
          AND NOT EXISTS (
              SELECT 1 
              FROM coworking.accesos a2
              WHERE a2.usuario_id = a1.usuario_id 
                AND a2.tipo_acceso = 'SALIDA' 
                AND a2.fecha_hora > a1.fecha_hora
          );
          
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_usuario_id, v_fecha_hora, v_credencial_id;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Insertar salida automática a las 20:00:00 del día de hoy
        INSERT INTO coworking.accesos (
            id, usuario_id, credencial_id, tipo_acceso, metodo_validacion, fecha_hora, punto_acceso,
            validacion_membresia, validacion_reserva, estado, notas
        ) VALUES (
            UUID(),
            v_usuario_id,
            v_credencial_id,
            'SALIDA',
            'AUTOMATICO',
            CONCAT(CURDATE(), ' 20:00:00'),
            'SALIDA AUTOMATICA',
            'ACTIVA',
            'SIN_RESERVA',
            'PERMITIDO',
            'Salida forzada por el sistema al cierre de operaciones diario.'
        );
    END LOOP;
    CLOSE cur;

    COMMIT;
    SELECT 'Depuración de accesos sin salida finalizada' AS mensaje;
END //
DELIMITER ;


-- ============================================================================
-- 4. FUNCIONES DE NEGOCIO Y OPERATIVAS
-- ============================================================================

-- Función: Calcular tasa de ocupación de un espacio específico en un rango de fechas
DROP FUNCTION IF EXISTS fn_tasa_ocupacion_espacio;
DELIMITER //
CREATE FUNCTION fn_tasa_ocupacion_espacio(
    p_espacio_id VARCHAR(36),
    p_fecha_desde DATE,
    p_fecha_hasta DATE
) 
RETURNS DECIMAL(5,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_dias_rango INT;
    DECLARE v_horas_disponibles DECIMAL(10,2);
    DECLARE v_horas_reservadas DECIMAL(10,2);
    DECLARE v_tasa DECIMAL(5,2) DEFAULT 0.00;
    DECLARE v_hora_apertura TIME;
    DECLARE v_hora_cierre TIME;
    DECLARE v_horas_operativas_dia DECIMAL(5,2);

    -- Determinar diferencia de días
    SET v_dias_rango = DATEDIFF(p_fecha_hasta, p_fecha_desde) + 1;
    IF v_dias_rango <= 0 THEN
        RETURN 0.00;
    END IF;

    -- Obtener horario operativo del espacio
    SELECT hora_apertura, hora_cierre INTO v_hora_apertura, v_hora_cierre
    FROM coworking.espacios
    WHERE id = p_espacio_id;

    IF v_hora_apertura IS NULL OR v_hora_cierre IS NULL THEN
        SET v_horas_operativas_dia = 12.0; -- Default fallback
    ELSE
        SET v_horas_operativas_dia = TIMESTAMPDIFF(MINUTE, v_hora_apertura, v_hora_cierre) / 60.0;
    END IF;

    SET v_horas_disponibles = v_dias_rango * v_horas_operativas_dia;

    -- Sumar horas reservadas confirmadas/completadas
    SELECT IFNULL(SUM(duracion_horas), 0.00) INTO v_horas_reservadas
    FROM coworking.reservas
    WHERE espacio_id = p_espacio_id
      AND fecha_reserva BETWEEN p_fecha_desde AND p_fecha_hasta
      AND estado IN ('CONFIRMADA', 'COMPLETADA');

    IF v_horas_disponibles > 0 THEN
        SET v_tasa = (v_horas_reservadas / v_horas_disponibles) * 100.00;
    END IF;

    RETURN LEAST(v_tasa, 100.00); -- Top at 100%
END //
DELIMITER ;

-- Función: Calcular impuesto aplicable a un servicio
DROP FUNCTION IF EXISTS fn_calcular_impuesto_servicio;
DELIMITER //
CREATE FUNCTION fn_calcular_impuesto_servicio(
    p_servicio_id VARCHAR(36),
    p_cantidad DECIMAL(8,2)
)
RETURNS DECIMAL(10,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_impuesto_pct DECIMAL(5,2);
    
    SELECT precio_unitario, impuesto_aplicable INTO v_precio, v_impuesto_pct
    FROM coworking.servicios_adicionales
    WHERE id = p_servicio_id;
    
    IF v_precio IS NULL THEN
        RETURN 0.00;
    END IF;
    
    RETURN ROUND((v_precio * p_cantidad) * (IFNULL(v_impuesto_pct, 0.00) / 100.00), 2);
END //
DELIMITER ;

-- Función: Verificar si un usuario tiene acceso permitido al coworking actualmente
-- Integra controles de membresía activa, estado de bloqueos y reservas vigentes
DROP FUNCTION IF EXISTS fn_verificar_acceso_permitido;
DELIMITER //
CREATE FUNCTION fn_verificar_acceso_permitido(
    p_usuario_id VARCHAR(36)
)
RETURNS BOOLEAN
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_estado_usuario VARCHAR(20);
    DECLARE v_tiene_membresia BOOLEAN DEFAULT FALSE;
    DECLARE v_tiene_reserva_hoy BOOLEAN DEFAULT FALSE;

    -- Validar estado global de la cuenta
    SELECT estado INTO v_estado_usuario
    FROM coworking.usuario
    WHERE id = p_usuario_id;

    IF v_estado_usuario IS NULL OR v_estado_usuario IN ('INACTIVO', 'BLOQUEADO') THEN
        RETURN FALSE;
    END IF;

    -- Validar si posee membresía activa hoy
    IF EXISTS (
        SELECT 1 
        FROM coworking.membresia_usuario 
        WHERE usuario_id = p_usuario_id 
          AND estado = 'ACTIVA' 
          AND CURDATE() BETWEEN fecha_inicio AND fecha_fin
    ) THEN
        SET v_tiene_membresia = TRUE;
    END IF;

    -- Validar si posee alguna reserva confirmada para hoy
    IF EXISTS (
        SELECT 1 
        FROM coworking.reservas 
        WHERE usuario_id = p_usuario_id 
          AND estado = 'CONFIRMADA' 
          AND fecha_reserva = CURDATE()
          AND CURRENT_TIME() BETWEEN DATE_SUB(hora_inicio, INTERVAL 30 MINUTE) AND hora_fin
    ) THEN
        SET v_tiene_reserva_hoy = TRUE;
    END IF;

    -- Acceso permitido si tiene membresía o una reserva válida activa
    RETURN (v_tiene_membresia OR v_tiene_reserva_hoy);
END //
DELIMITER ;

-- Función: Calcular Descuento por Fidelidad
-- Otorga porcentajes de descuento según el volumen total pagado acumulado históricamente
DROP FUNCTION IF EXISTS fn_calcular_descuento_fidelidad;
DELIMITER //
CREATE FUNCTION fn_calcular_descuento_fidelidad(
    p_usuario_id VARCHAR(36)
)
RETURNS DECIMAL(5,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_gastado DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_descuento DECIMAL(5,2) DEFAULT 0.00;

    SELECT IFNULL(SUM(monto_neto), 0.00) INTO v_gastado
    FROM coworking.pagos
    WHERE usuario_id = p_usuario_id AND estado = 'PAGADO';

    IF v_gastado >= 5000.00 THEN
        SET v_descuento = 15.00; -- 15% de descuento por alta fidelidad
    ELSEIF v_gastado >= 2000.00 THEN
        SET v_descuento = 10.00; -- 10%
    ELSEIF v_gastado >= 500.00 THEN
        SET v_descuento = 5.00; -- 5%
    END IF;

    RETURN v_descuento;
END //
DELIMITER ;

-- Función: Convertir Moneda (Helper Financiero)
-- Convierte importes monetarios de MXN, COP, EUR a USD utilizando valores fijos actualizables
DROP FUNCTION IF EXISTS fn_convertir_moneda;
DELIMITER //
CREATE FUNCTION fn_convertir_moneda(
    p_monto DECIMAL(12,2),
    p_moneda_origen VARCHAR(3)
)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE v_monto_usd DECIMAL(12,2);
    
    SET v_monto_usd = CASE p_moneda_origen
        WHEN 'USD' THEN p_monto
        WHEN 'EUR' THEN p_monto * 1.09
        WHEN 'MXN' THEN p_monto * 0.058
        WHEN 'COP' THEN p_monto * 0.00025
        ELSE p_monto
    END;
    
    RETURN ROUND(v_monto_usd, 2);
END //
DELIMITER ;

-- Función: Proyección de Ingresos Mensuales
-- Proyecta los cobros del mes basándose en el precio de membresías que expiran este mes
DROP FUNCTION IF EXISTS fn_ingresos_proyectados_mes;
DELIMITER //
CREATE FUNCTION fn_ingresos_proyectados_mes()
RETURNS DECIMAL(14,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_proyeccion DECIMAL(14,2) DEFAULT 0.00;

    SELECT IFNULL(SUM(tm.precio_base), 0.00) INTO v_proyeccion
    FROM coworking.membresia_usuario mu
    INNER JOIN coworking.tipos_membresia tm ON mu.tipo_membresia_id = tm.id
    WHERE mu.estado = 'ACTIVA'
      AND MONTH(mu.fecha_fin) = MONTH(CURDATE())
      AND YEAR(mu.fecha_fin) = YEAR(CURDATE());

    RETURN v_proyeccion;
END //
DELIMITER ;

-- Función: Tiempo de Permanencia Promedio (En horas)
-- Mide el tiempo de estadía promedio de un usuario analizando la entrada y la salida
DROP FUNCTION IF EXISTS fn_tiempo_permanencia_promedio;
DELIMITER //
CREATE FUNCTION fn_tiempo_permanencia_promedio(
    p_usuario_id VARCHAR(36)
)
RETURNS DECIMAL(5,2)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_promedio_horas DECIMAL(5,2);

    SELECT AVG(TIMESTAMPDIFF(MINUTE, e.fecha_hora, s.fecha_hora) / 60.0) INTO v_promedio_horas
    FROM coworking.accesos e
    INNER JOIN coworking.accesos s 
        ON e.usuario_id = s.usuario_id 
       AND s.tipo_acceso = 'SALIDA' 
       AND s.fecha_hora > e.fecha_hora
       AND s.fecha_hora < DATE_ADD(e.fecha_hora, INTERVAL 1 DAY)
    WHERE e.usuario_id = p_usuario_id 
      AND e.tipo_acceso = 'ENTRADA';

    RETURN IFNULL(v_promedio_horas, 0.00);
END //
DELIMITER ;

-- Función: Obtener asistente más frecuente de una empresa
DROP FUNCTION IF EXISTS fn_obtener_asistente_mas_frecuente_empresa;
DELIMITER //
CREATE FUNCTION fn_obtener_asistente_mas_frecuente_empresa(
    p_empresa_id VARCHAR(36)
)
RETURNS VARCHAR(36)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_usuario_id VARCHAR(36);

    SELECT a.usuario_id INTO v_usuario_id
    FROM coworking.accesos a
    INNER JOIN coworking.usuario u ON a.usuario_id = u.id
    WHERE u.empresa_id = p_empresa_id 
      AND a.tipo_acceso = 'ENTRADA'
      AND MONTH(a.fecha_hora) = MONTH(CURDATE())
      AND YEAR(a.fecha_hora) = YEAR(CURDATE())
    GROUP BY a.usuario_id
    ORDER BY COUNT(*) DESC
    LIMIT 1;

    RETURN v_usuario_id;
END //
DELIMITER ;

-- Función: Verificar disponibilidad de espacio físico en rango horario
DROP FUNCTION IF EXISTS fn_espacio_disponible;
DELIMITER //
CREATE FUNCTION fn_espacio_disponible(
    p_espacio_id VARCHAR(36),
    p_fecha DATE,
    p_hora_inicio TIME,
    p_hora_fin TIME
)
RETURNS BOOLEAN
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_solapamientos INT DEFAULT 0;

    SELECT COUNT(*) INTO v_solapamientos
    FROM coworking.reservas
    WHERE espacio_id = p_espacio_id
      AND fecha_reserva = p_fecha
      AND estado IN ('PENDIENTE', 'CONFIRMADA')
      AND p_hora_inicio < hora_fin
      AND p_hora_fin > hora_inicio;

    RETURN IF(v_solapamientos = 0, TRUE, FALSE);
END //
DELIMITER ;


-- ============================================================================
-- 5. TRIGGERS ADICIONALES
-- ============================================================================

-- Trigger: Restaurar Stock de Servicio Cancelado
-- Si un servicio contratado de disponibilidad limitada es cancelado, se regresa su stock al catálogo.
DROP TRIGGER IF EXISTS trg_actualizar_stock_servicio;
DELIMITER //
CREATE TRIGGER trg_actualizar_stock_servicio 
AFTER UPDATE ON coworking.servicios_contratados
FOR EACH ROW
BEGIN
    DECLARE v_disponibilidad_limitada BOOLEAN;

    -- Si el estado cambia a CANCELADO
    IF NEW.estado = 'CANCELADO' AND OLD.estado != 'CANCELADO' THEN
        SELECT disponibilidad_limitada INTO v_disponibilidad_limitada
        FROM coworking.servicios_adicionales
        WHERE id = NEW.servicio_id;

        IF v_disponibilidad_limitada = TRUE THEN
            UPDATE coworking.servicios_adicionales
            SET stock_disponible = stock_disponible + CAST(NEW.cantidad AS SIGNED)
            WHERE id = NEW.servicio_id;
        END IF;
    END IF;
END //
DELIMITER ;

-- Trigger: Log de Alertas de Seguridad al Bloquear Usuario
-- Inserta un intento rechazado preventivo cuando un usuario es bloqueado del sistema.
DROP TRIGGER IF EXISTS trg_log_bloqueo_usuario;
DELIMITER //
CREATE TRIGGER trg_log_bloqueo_usuario
AFTER UPDATE ON coworking.usuario
FOR EACH ROW
BEGIN
    IF NEW.estado = 'BLOQUEADO' AND OLD.estado != 'BLOQUEADO' THEN
        INSERT INTO coworking.intentos_acceso_rechazados (
            id, usuario_id, credencial_id, codigo_intentado, metodo_validacion, fecha_hora, punto_acceso, motivo_rechazo, descripcion_detallada, estado
        ) VALUES (
            UUID(),
            NEW.id,
            NULL,
            'SISTEMA',
            'MANUAL',
            NOW(),
            'PANEL CONTROL',
            'INTENTOS_EXCEDIDOS',
            CONCAT('Usuario ', NEW.nombre, ' ', NEW.apellidos, ' bloqueado administrativamente en el sistema.'),
            'BLOQUEADO'
        );
    END IF;
END //
DELIMITER ;

-- Trigger: Revocación Automática de Credenciales de Acceso
-- Desactiva las credenciales físicas si el usuario principal cambia a estado BLOQUEADO o INACTIVO
DROP TRIGGER IF EXISTS trg_desactivar_credenciales_al_bloquear;
DELIMITER //
CREATE TRIGGER trg_desactivar_credenciales_al_bloquear
AFTER UPDATE ON coworking.usuario
FOR EACH ROW
BEGIN
    IF NEW.estado IN ('BLOQUEADO', 'INACTIVO') AND OLD.estado = 'ACTIVO' THEN
        UPDATE coworking.credenciales_acceso
        SET estado = 'REVOCADA',
            fecha_revocacion = NOW(),
            motivo_revocacion = 'Desactivación automática por bloqueo o inactivación del usuario.'
        WHERE usuario_id = NEW.id AND estado = 'ACTIVA';
    END IF;
END //
DELIMITER ;

-- Trigger: Validar Horas Operativas de Reservas
-- Evita registrar reservas si caen fuera de los límites de apertura/cierre de dicho espacio
DROP TRIGGER IF EXISTS trg_reserva_horario_valido;
DELIMITER //
CREATE TRIGGER trg_reserva_horario_valido
BEFORE INSERT ON coworking.reservas
FOR EACH ROW
BEGIN
    DECLARE v_apertura TIME;
    DECLARE v_cierre TIME;

    SELECT hora_apertura, hora_cierre INTO v_apertura, v_cierre
    FROM coworking.espacios
    WHERE id = NEW.espacio_id;

    IF NEW.hora_inicio < v_apertura OR NEW.hora_fin > v_cierre THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: La reserva se encuentra fuera de las horas operativas del espacio.';
    END IF;
END //
DELIMITER ;

-- Trigger: Validar Capacidad de Reserva
-- Evita reservas que excedan la capacidad física del espacio
DROP TRIGGER IF EXISTS trg_reserva_capacidad_maxima;
DELIMITER //
CREATE TRIGGER trg_reserva_capacidad_maxima
BEFORE INSERT ON coworking.reservas
FOR EACH ROW
BEGIN
    DECLARE v_capacidad_max INT;

    SELECT capacidad INTO v_capacidad_max
    FROM coworking.espacios
    WHERE id = NEW.espacio_id;

    IF NEW.numero_asistentes > v_capacidad_max THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El número de asistentes excede la capacidad máxima del espacio.';
    END IF;
END //
DELIMITER ;

-- Trigger: Evitar borrado de usuario con deudas pendientes
DROP TRIGGER IF EXISTS trg_evitar_borrado_usuario_con_deuda;
DELIMITER //
CREATE TRIGGER trg_evitar_borrado_usuario_con_deuda
BEFORE DELETE ON coworking.usuario
FOR EACH ROW
BEGIN
    IF (
        SELECT COUNT(*) 
        FROM coworking.facturas 
        WHERE usuario_id = OLD.id AND saldo_pendiente > 0 AND estado IN ('PENDIENTE', 'PARCIAL', 'VENCIDA')
    ) > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se puede eliminar un usuario que posea facturas con saldo pendiente.';
    END IF;
END //
DELIMITER ;

-- Trigger: Prevenir Reservas Solapadas del Mismo Usuario
-- Impide a un mismo usuario registrar dos reservas que coincidan en fecha y horario.
DROP TRIGGER IF EXISTS trg_reserva_usuario_solapada;
DELIMITER //
CREATE TRIGGER trg_reserva_usuario_solapada
BEFORE INSERT ON coworking.reservas
FOR EACH ROW
BEGIN
    IF (
        SELECT COUNT(*)
        FROM coworking.reservas
        WHERE usuario_id = NEW.usuario_id
          AND fecha_reserva = NEW.fecha_reserva
          AND estado IN ('PENDIENTE', 'CONFIRMADA')
          AND NEW.hora_inicio < hora_fin
          AND NEW.hora_fin > hora_inicio
    ) > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El usuario ya posee otra reserva confirmada en este mismo rango horario.';
    END IF;
END //
DELIMITER ;

-- Trigger: Evitar anulación de factura pagada
-- Impide anular facturas que ya tengan estado PAGADA
DROP TRIGGER IF EXISTS trg_evitar_anulacion_factura_pagada;
DELIMITER //
CREATE TRIGGER trg_evitar_anulacion_factura_pagada
BEFORE UPDATE ON coworking.facturas
FOR EACH ROW
BEGIN
    IF OLD.estado = 'PAGADA' AND NEW.estado = 'ANULADA' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se puede anular una factura que ya ha sido totalmente pagada.';
    END IF;
END //
DELIMITER ;

-- Trigger: Prevenir pago excedente al saldo pendiente
-- Evita registrar pagos mayores al saldo restante de la factura
DROP TRIGGER IF EXISTS trg_evitar_pago_excedente;
DELIMITER //
CREATE TRIGGER trg_evitar_pago_excedente
BEFORE INSERT ON coworking.pagos
FOR EACH ROW
BEGIN
    DECLARE v_saldo DECIMAL(12,2);
    
    SELECT saldo_pendiente INTO v_saldo
    FROM coworking.facturas
    WHERE id = NEW.factura_id;
    
    IF NEW.monto > v_saldo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El monto del pago excede el saldo pendiente de la factura.';
    END IF;
END //
DELIMITER ;


-- ============================================================================
-- 6. EVENTOS PROGRAMADOS ADICIONALES
-- ============================================================================

-- Asegurar que el planificador de eventos de MySQL esté encendido
SET GLOBAL event_scheduler = ON;

-- Evento: Cancelar Reservas Pendientes sin Confirmar Pago (Modo Estricto)
-- Libera reservas pendientes del día de hoy de forma automática si ya pasó su hora de inicio.
DROP EVENT IF EXISTS evt_cancelar_reservas_sin_pago_nuevas;
CREATE EVENT coworking.evt_cancelar_reservas_sin_pago_nuevas
ON SCHEDULE EVERY 15 MINUTE
DO
    UPDATE coworking.reservas 
    SET estado = 'CANCELADA', 
        motivo_cancelacion = 'Reserva pendiente cancelada automáticamente al expirar el tiempo de pago.'
    WHERE estado = 'PENDIENTE' 
      AND (
          fecha_reserva < CURDATE() 
          OR (fecha_reserva = CURDATE() AND hora_inicio < CURRENT_TIME())
      );

-- Evento: Notificar Vencimiento Próximo de Credenciales
-- Registra alertas para credenciales inactivas o próximas a vencer en 7 días en la bitácora de intentos
DROP EVENT IF EXISTS evt_notificar_vencimiento_credencial_nuevas;
CREATE EVENT coworking.evt_notificar_vencimiento_credencial_nuevas
ON SCHEDULE EVERY 1 DAY
STARTS '2026-07-21 02:00:00'
DO
    INSERT INTO coworking.intentos_acceso_rechazados (
        id, usuario_id, credencial_id, codigo_intentado, metodo_validacion, fecha_hora, punto_acceso, motivo_rechazo, descripcion_detallada, estado
    )
    SELECT 
        UUID(),
        ca.usuario_id,
        ca.id,
        ca.codigo,
        ca.tipo_credencial,
        NOW(),
        'SISTEMA NOTIFICACIONES',
        'CREDENCIAL_VENCIDA',
        CONCAT('ALERTA: La credencial ', ca.codigo, ' vence el ', ca.fecha_vencimiento),
        'REGISTRADO'
    FROM coworking.credenciales_acceso ca
    WHERE ca.fecha_vencimiento BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY)
      AND ca.estado = 'ACTIVA';

-- Evento: Desactivación diaria de credenciales cuya fecha de vencimiento haya expirado
DROP EVENT IF EXISTS evt_desactivar_credenciales_vencidas;
CREATE EVENT coworking.evt_desactivar_credenciales_vencidas
ON SCHEDULE EVERY 1 DAY
STARTS '2026-07-21 01:00:00'
DO
    UPDATE coworking.credenciales_acceso
    SET estado = 'VENCIDA'
    WHERE fecha_vencimiento < NOW() AND estado = 'ACTIVA';

-- Evento: Registrar Salidas Olvidadas Automáticamente al Cierre de Día
-- Depura la bitácora diariamente a las 23:59:00 insertando salidas por defecto.
DROP EVENT IF EXISTS evt_registrar_salidas_olvidadas;
CREATE EVENT coworking.evt_registrar_salidas_olvidadas
ON SCHEDULE EVERY 1 DAY
STARTS '2026-07-20 23:59:00'
DO
    CALL coworking.RegistrarSalidasFaltantes();


-- ============================================================================
-- 7. CONSULTAS ANALÍTICAS Y REPORTES DE NEGOCIO
-- ============================================================================

-- Consulta A: Distribución horaria de accesos (Horas pico)
-- Permite saber qué horas del día tienen mayor tráfico de entradas para ajustar recepcionistas.
-- SELECT 
--     HOUR(fecha_hora) AS hora_dia,
--     COUNT(*) AS total_accesos,
--     SUM(CASE WHEN tipo_acceso = 'ENTRADA' THEN 1 ELSE 0 END) AS total_entradas,
--     SUM(CASE WHEN tipo_acceso = 'SALIDA' THEN 1 ELSE 0 END) AS total_salidas
-- FROM coworking.accesos
-- WHERE estado = 'PERMITIDO'
-- GROUP BY HOUR(fecha_hora)
-- ORDER BY total_accesos DESC;

-- Consulta B: Customer Lifetime Value (LTV) acumulado
-- Clasifica a los usuarios individuales y empresas por el total acumulado neto que han pagado.
SELECT 
    u.id AS usuario_id,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre_usuario,
    e.nombre AS empresa,
    SUM(p.monto_neto) AS total_pagado_neto,
    COUNT(DISTINCT p.id) AS numero_pagos_realizados
FROM coworking.pagos p
INNER JOIN coworking.usuario u ON p.usuario_id = u.id
LEFT JOIN coworking.empresas e ON u.empresa_id = e.id
WHERE p.estado = 'PAGADO'
GROUP BY u.id, u.nombre, u.apellidos, e.nombre
ORDER BY total_pagado_neto DESC;

-- Consulta C: Rentabilidad de Categorías de Servicios Adicionales
-- Obtiene el total de ingresos y cantidad vendida agrupada por categorías de servicios.
-- SELECT 
--     sa.categorias AS categoria_servicio,
--     COUNT(sc.id) AS total_contrataciones,
--     SUM(sc.cantidad) AS cantidad_total_unidades,
--     SUM(sc.subtotal) AS ingresos_subtotal,
--     SUM(sc.total) AS ingresos_totales_con_impuesto
-- FROM coworking.servicios_contratados sc
-- INNER JOIN coworking.servicios_adicionales sa ON sc.servicio_id = sa.id
-- WHERE sc.estado IN ('USADO', 'FACTURADO', 'ACTIVO')
-- GROUP BY sa.categorias
-- ORDER BY ingresos_totales_con_impuesto DESC;

-- Consulta D: Ghost Members (Usuarios inactivos con membresías activas)
-- Lista a los usuarios con membresía vigente pero sin accesos registrados en los últimos 30 días.
-- SELECT 
--     u.id AS usuario_id,
--     CONCAT(u.nombre, ' ', u.apellidos) AS nombre,
--     u.email,
--     mu.fecha_fin AS vencimiento_membresia
-- FROM coworking.usuario u
-- INNER JOIN coworking.membresia_usuario mu ON mu.usuario_id = u.id
-- LEFT JOIN coworking.accesos ac ON ac.usuario_id = u.id AND ac.fecha_hora >= DATE_SUB(NOW(), INTERVAL 30 DAY)
-- WHERE mu.estado = 'ACTIVA'
--   AND ac.id IS NULL
-- GROUP BY u.id, u.nombre, u.apellidos, u.email, mu.fecha_fin;

-- Consulta E: Eficiencia de Ocupación por Piso
-- Muestra el porcentaje de reservas realizadas en los espacios agrupados por planta física (piso).
-- SELECT 
--     e.piso,
--     COUNT(r.id) AS total_reservas_piso,
--     SUM(r.duracion_horas) AS horas_totales_reservadas,
--     ROUND(AVG(r.numero_asistentes), 1) AS promedio_asistentes
-- FROM coworking.reservas r
-- INNER JOIN coworking.espacios e ON r.espacio_id = e.id
-- WHERE r.estado IN ('CONFIRMADA', 'COMPLETADA')
-- GROUP BY e.piso
-- ORDER BY horas_totales_reservadas DESC;

-- Consulta F: Días y Franjas de Mayor Ocupación del Espacio
-- SELECT 
--     DAYNAME(fecha_hora) AS dia_semana,
--     CASE 
--         WHEN HOUR(fecha_hora) BETWEEN 8 AND 11 THEN 'MAÑANA (8-12)'
--         WHEN HOUR(fecha_hora) BETWEEN 12 AND 16 THEN 'TARDE (12-17)'
--         ELSE 'NOCHE (17-20)'
--     END AS franja_horaria,
--     COUNT(*) AS total_visitas
-- FROM coworking.accesos
-- WHERE tipo_acceso = 'ENTRADA' AND estado = 'PERMITIDO'
-- GROUP BY DAYNAME(fecha_hora), franja_horaria
-- ORDER BY total_visitas DESC;
