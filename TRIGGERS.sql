-- ============================================================================
-- SECCIÓN 1: TRIGGERS (20)
-- ============================================================================
USE coworking;
-- MÓDULO MEMBRESÍAS
-- 1. Insertar fecha de vencimiento automáticamente
DELIMITER //
CREATE TRIGGER trg_mem_calc_vencimiento BEFORE INSERT ON membresia_usuario
FOR EACH ROW BEGIN
    DECLARE v_nombre_tipo VARCHAR(30);
    -- Buscamos el nombre del tipo de membresía según el id que viene en NEW
    SELECT nombre INTO v_nombre_tipo
    FROM membresia_usuario mu
    WHERE tipo_membresia_id = NEW.tipo_membresia_id;
    -- Según el tipo, calculamos la fecha_fin
    IF v_nombre_tipo = 'Diaria' THEN
        SET NEW.fecha_fin = NEW.fecha_inicio;
    ELSEIF v_nombre_tipo = 'Mensual' THEN
        SET NEW.fecha_fin = DATE_ADD(NEW.fecha_inicio, INTERVAL 1 MONTH);
    ELSEIF v_nombre_tipo = 'Anual' THEN
        SET NEW.fecha_fin = DATE_ADD(NEW.fecha_inicio, INTERVAL 1 YEAR);
    END IF;
END //
DELIMITER ;

-- 2. Actualizar estado a "Activa" al realizar pago exitoso
DELIMITER //
CREATE TRIGGER trg_mem_activar_pago 
AFTER UPDATE ON pagos
FOR EACH ROW 
BEGIN
    IF NEW.estado = 'PAGADO' THEN
        UPDATE membresia_usuario 
        SET estado = 'ACTIVA' 
        WHERE usuario_id = NEW.usuario_id; -- ¡CRUCIAL! Ajusta 'id_usuario' si tu columna se llama diferente (ej. id_cliente)
    END IF;
END //
DELIMITER ;

-- 3. Actualizar estado a "Suspendida" si no se paga antes del límite
DELIMITER //
CREATE TRIGGER trg_mem_suspender BEFORE UPDATE ON membresia_usuario
FOR EACH ROW BEGIN
    IF NEW.fecha_fin < CURDATE() AND NEW.estado = 'ACTIVA' THEN
        SET NEW.estado = 'SUSPENDIDA';
    END IF;
END //
DELIMITER ;

-- 4. Log al actualizar tipo de membresía
DELIMITER //
CREATE TRIGGER trg_mem_log_tipo AFTER UPDATE ON membresia_usuario
FOR EACH ROW BEGIN
    IF OLD.tipo_membresia_id != NEW.tipo_membresia_id THEN
        INSERT INTO log_membresias (usuario_id, cambio, fecha) VALUES (NEW.usuario_id, CONCAT(tipo_anterior_id, ' a ', tipo_nuevo_id), NOW());
    END IF;
END //
DELIMITER ;

-- 5. Bloquear eliminación si tiene reservas activas
DELIMITER //
CREATE TRIGGER trg_bloquear_del_activo BEFORE DELETE ON membresia_usuario
FOR EACH ROW BEGIN
    IF (SELECT COUNT(*) FROM reservas WHERE usuario_id = OLD.usuario_id AND estado IN ('PENDIENTE', 'CONFIRMADO')) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: tiene reservas activas';
    END IF;
END //
DELIMITER ;

-- MÓDULO RESERVAS
-- 6. Validar reservas duplicadas
DELIMITER //
CREATE TRIGGER trg_res_duplicado BEFORE INSERT ON reservas
FOR EACH ROW BEGIN
    IF (SELECT COUNT(*) FROM reservas WHERE espacio_id = NEW.espacio_id AND fecha_reserva = NEW.fecha_reserva ) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El espacio ya está reservado en ese horario';
    END IF;
END //
DELIMITER ;

-- 7. Estado "Pendiente de Confirmación" al crear
DELIMITER //
CREATE TRIGGER trg_res_pendiente BEFORE INSERT ON reservas
FOR EACH ROW SET NEW.estado = 'Pendiente de Confirmación';
DELIMITER ;

-- 8. Cambiar a "Confirmada" al registrar pago
DELIMITER //
CREATE TRIGGER trg_res_confirmar AFTER UPDATE ON pagos
FOR EACH ROW BEGIN
    IF NEW.estado = 'PAGADO' THEN
        UPDATE reservas SET estado = 'CONFIRMADA' WHERE codigo_pago = NEW.codigo_pago;
    END IF;
END //
DELIMITER ;

-- 9. Cancelar reserva si elimina membresía
DELIMITER //
CREATE TRIGGER trg_res_cancelar_mem AFTER DELETE ON membresia_usuario
FOR EACH ROW UPDATE reservas SET estado = 'CANCELADA' WHERE usuario_id = OLD.usuario_id AND estado != 'COMPLETADA';
DELIMITER ;

-- 10. Log de reservas canceladas
DELIMITER //
CREATE TRIGGER trg_res_log_cancel AFTER UPDATE ON reservas
FOR EACH ROW BEGIN
    IF NEW.estado = 'CANCELADA' AND OLD.estado != 'CANCELADA' THEN
        INSERT INTO log_reservas (reserva_id, motivo, fecha) VALUES (reserva_id, 'Cancelada por usuario', NOW());
    END IF;
END //
DELIMITER ;

-- MÓDULO PAGOS Y FACTURACIÓN
-- 11. Crear factura al registrar pago
DELIMITER // 
CREATE TRIGGER trg_pag_crear_factura AFTER INSERT ON pagos
FOR EACH ROW INSERT INTO facturas (codigo_pago, usuario_id, total, estado) VALUES (NEW.codigo_pago, NEW.usuario_id, NEW.monto, 'Emitida');
DELIMITER ;

-- 12. Actualizar factura a "Pagada"
DELIMITER //
CREATE TRIGGER trg_pag_factura_pagada AFTER UPDATE ON pagos
FOR EACH ROW BEGIN
    IF NEW.estado = 'PAGADO' THEN
        UPDATE facturas SET estado = 'PAGADA' WHERE factura_id = NEW.factura_id;
    END IF;
END //
DELIMITER ;

-- 13. Bloquear eliminación de pago con factura
DELIMITER //
CREATE TRIGGER trg_pag_bloquear_del BEFORE DELETE ON pagos
FOR EACH ROW BEGIN
    IF (SELECT COUNT(*) FROM facturas WHERE factura_id = OLD.factura_id) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar: existe factura asociada';
    END IF;
END //
DELIMITER ;

-- 14. Actualizar saldo pendiente en pagos parciales
DELIMITER //
CREATE TRIGGER trg_pag_saldo AFTER INSERT ON pagos
FOR EACH ROW UPDATE facturas SET saldo_pendiente = saldo_pendiente - NEW.monto WHERE factura_id = NEW.factura_id;
DELIMITER ;

-- 15. Log de pagos anulados
DELIMITER //
CREATE TRIGGER trg_pag_log_anulado AFTER UPDATE ON pagos
FOR EACH ROW BEGIN
    IF NEW.estado = 'RECHAZADO' AND OLD.estado != 'RECHAZADO' THEN
        INSERT INTO log_pagos (id_pago, accion, fecha) VALUES (NEW.codigo_pago, 'RECHAZADO', NOW());
    END IF;
END //
DELIMITER ;

-- MÓDULO ACCESOS
-- 16. Registrar asistencia al validar acceso
DELIMITER //
CREATE TRIGGER trg_acc_asistencia AFTER INSERT ON accesos
FOR EACH ROW INSERT INTO log_accesos (usuario_id, fecha_creacion) VALUES (NEW.usuario_id, NEW.fecha_creacion);
DELIMITER ;

-- 17. Bloquear acceso sin membresía activa
DELIMITER //
CREATE TRIGGER trg_acc_bloquear BEFORE INSERT ON accesos
FOR EACH ROW BEGIN
    IF (SELECT estado FROM membresias WHERE usuario_id = NEW.usuario_id ORDER BY tipo_membresia_id DESC LIMIT 1) != 'ACTIVA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Acceso denegado: membresía inactiva';
    END IF;
END //
DELIMITER ;

-- 18. Actualizar última fecha de acceso
DELIMITER //
CREATE TRIGGER trg_acc_ultima_fecha AFTER INSERT ON accesos
FOR EACH ROW UPDATE usuario SET ultimo_acceso = NEW.fecha_hora WHERE usuario_id = NEW.usuario_id;
DELIMITER ;

-- 19. Registrar salida automática si reentra sin salir
DELIMITER //
CREATE TRIGGER trg_acc_salida_auto BEFORE INSERT ON accesos
FOR EACH ROW BEGIN
    IF (SELECT tipo_acceso FROM accesos WHERE usuario_id = NEW.usuario_id ORDER BY credencial_id DESC LIMIT 1) = 'ENTRADA' THEN
        SET NEW.tipo_acceso = 'SALIDA';
    END IF;
END //
DELIMITER ;

-- 20. Log de intentos de acceso rechazado
DELIMITER //
CREATE TRIGGER trg_acc_log_rechazado AFTER INSERT ON intentos_acceso_rechazados
FOR EACH ROW INSERT INTO log_acceso (evento, detalle, fecha) VALUES ('Acceso Rechazado', NEW.motivo_rechazo, NOW());
DELIMITER ;

