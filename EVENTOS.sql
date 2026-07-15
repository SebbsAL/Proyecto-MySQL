-- ============================================================================
-- SECCIÓN 2: EVENTOS PROGRAMADOS (20)
-- ============================================================================

-- MÓDULO MEMBRESÍAS
-- 1. Revisar vencidas diariamente
DELIMITER //
CREATE EVENT evt_mem_vencidas ON SCHEDULE EVERY 1 DAY DO
	UPDATE membresias SET estado = 'VENCIDA' WHERE fecha_vencimiento < CURDATE() AND estado = 'ACTIVA';
DELIMITER ;

-- 2. Recordatorio de renovación 5 días antes
DELIMITER //
CREATE EVENT evt_mem_recordatorio ON SCHEDULE EVERY 1 DAY DO
    INSERT INTO recordatorios (id_usuario, mensaje) SELECT usuario_id, 'Tu membresía vence en 5 días' FROM membresia_usuario WHERE fecha_fin = DATE_ADD(CURDATE(), INTERVAL 5 DAY);
DELIMITER ;

-- 3. Suspender inactivas 30 días sin pago
DELIMITER //
CREATE EVENT evt_mem_suspender_inactivas ON SCHEDULE EVERY 1 DAY DO
    UPDATE membresia_usuario SET estado = 'SUSPENDIDA' WHERE DATEDIFF(CURDATE(), ultimo_pago) > 30 AND estado = 'ACTIVA';
DELIMITER ;

-- 4. Reporte semanal de nuevas membresias
DELIMITER //
CREATE EVENT evt_mem_reporte_semanal ON SCHEDULE EVERY 1 WEEK DO
	INSERT INTO reportes_generados (tipo_reporte, datos, fecha) SELECT 'SEMANAL_MEMBRESIAS', COUNT(*), NOW() FROM membresia_usuario 
	WHERE fecha_inicio >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
DELIMITER ;

-- 5. Notificar suspendidas a recepcion
DELIMITER //
CREATE EVENT evt_mem_notificar_susp ON SCHEDULE EVERY 1 DAY DO
	INSERT INTO recordatorios (tipo_recordatorio, mensaje) SELECT 'OTRO', CONCAT('Membresía suspendida:', usuario_id)
FROM membresia_usuario WHERE estado = 'SUSPENDIDA' AND fecha_suspencion = CURDATE();
DELIMITER ;

-- MÓDULO RESERVAS
-- 6. Cancelar no confirmadas después de 2 horas
DELIMITER //
CREATE EVENT evt_res_cancelar_pendientes ON SCHEDULE EVERY 1 HOUR DO
	UPDATE reservas SET estado = 'CANCELADA' WHERE estado = 'PENDIENTE' AND fecha_creacion
< DATE_SUB(NOW(), INTERVAL 2 HOUR);
DELIMITER ;

-- 7. Recordatorio 1 hora antes
DELIMITER //
CREATE EVENT evt_res_recordatorio ON SCHEDULE EVERY 30 MINUTE DO
	INSERT INTO recordatorios (usuario_id, mensaje) SELECT usuario_id, 'Tu reserva es en 1 hora'
	FROM reservas WHERE fecha_reserva = CURDATE() AND hora_inicio = DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 1 HOUR), '%H:%i');
DELIMITER ;

-- 8. Eliminar pasadas no asistidas (7 días)
DELIMITER //
CREATE EVENT evt_res_limpiar_pasadas ON SCHEDULE EVERY 1 DAY DO
		DELETE FROM reservas WHERE fecha_reserva < DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND estado = 'NOSHOW';
DELIMITER ;

-- 9. Reporte semanal de ocupacion
DELIMITER //
CREATE EVENT evt_res_reporte_ocupacion ON SCHEDULE EVERY 1 WEEK DO
BEGIN
	INSERT INTO reportes_generados (tipo, datos) SELECT 'SEMANAL_OCUPACION', CONCAT(espacio_id, ': ', COUNT(*)) 
	FROM reservas WHERE fecha >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) 
	GROUP BY espacio_id;
END//
DELIMITER ;

-- 10. Liberar bloqueadas si no inician en 15 min
DELIMITER //
CREATE EVENT evt_res_liberar_bloqueadas ON SCHEDULE EVERY 15 MINUTE DO
    UPDATE reservas SET estado = 'NOSHOW' WHERE estado = 'PENDIENTE' AND hora_inicio < DATE_SUB(NOW(), INTERVAL 15 MINUTE);
DELIMITER ;

-- MÓDULO PAGOS Y FACTURACIÓN
-- 11. Recordatorio de pago pendiente cada 3 días
DELIMITER //
CREATE EVENT evt_pag_recordatorio ON SCHEDULE EVERY 3 DAY DO
    INSERT INTO recordatorios (usuario_id, mensaje) SELECT usuario_id, 'Tienes pagos pendientes' FROM facturas WHERE saldo_pendiente > 0;
DELIMITER ;

-- 12. Bloquear servicios si factura vencida > 10 días
DELIMITER //
CREATE EVENT evt_pag_bloquear_servicios ON SCHEDULE EVERY 1 DAY DO
    UPDATE usuario SET estado = 'BLOQUEADO' 
	WHERE usuario_id IN (SELECT usuario_id FROM facturas WHERE DATEDIFF(CURDATE(), fecha_vencimiento) 
	> 10 AND saldo_pendiente > 0);
DELIMITER ;

-- 13. Resumen de facturación mensual
DELIMITER //
CREATE EVENT evt_pag_resumen_mensual ON SCHEDULE EVERY 1 MONTH DO
    INSERT INTO reportes_generados (tipo, datos) SELECT 'MENSUAL_FACTURACION', SUM(total) FROM facturas WHERE MONTH(fecha_creacion) = MONTH(CURDATE());
DELIMITER ;

-- 14. Aplicar recargos a facturas vencidas > 15 días
DELIMITER //
CREATE EVENT evt_pag_recargos ON SCHEDULE EVERY 1 DAY DO
    UPDATE facturas SET total = total + (total * 0.05) WHERE DATEDIFF(CURDATE(), fecha_vencimiento) > 15 AND saldo_pendiente > 0;
DELIMITER ;

-- 15. Reporte de ingresos al contador (fin de mes)
DELIMITER //
CREATE EVENT evt_pag_reporte_contador ON SCHEDULE EVERY 1 MONTH STARTS '2024-01-31 23:59:00' DO
    INSERT INTO reportes (destinatario, datos) SELECT 'contador', SUM(monto) FROM pagos WHERE estado = 'PAGADO' AND MONTH(fecha_pago) = MONTH(CURDATE());
DELIMITER ;

-- MÓDULO ACCESOS Y ASISTENCIAS
-- 16. Eliminar accesos antiguos (> 1 año)
DELIMITER //
CREATE EVENT evt_acc_limpiar_antiguos ON SCHEDULE EVERY 1 MONTH DO
    DELETE FROM accesos WHERE fecha_hora < DATE_SUB(CURDATE(), INTERVAL 1 YEAR);
DELIMITER ;

-- 17. Reporte diario de asistencias
DELIMITER //
CREATE EVENT evt_acc_reporte_diario ON SCHEDULE EVERY 1 DAY STARTS '2024-01-01 23:00:00' DO
    INSERT INTO reportes_generados (tipo, datos) SELECT 'DIARIO_ASISTENCIAS', COUNT(*) FROM accesos WHERE DATE(fecha_hora) = CURDATE();
DELIMITER ;

-- 18. Reporte semanal de usuarios inactivos
DELIMITER //
CREATE EVENT evt_acc_inactivos ON SCHEDULE EVERY 1 WEEK DO
    INSERT INTO reportes_generados (tipo, datos) SELECT 'USUARIOS_INACTIVOS', usuario_id FROM usuario WHERE ultimo_acceso < DATE_SUB(CURDATE(), INTERVAL 30 DAY);
DELIMITER ;

-- 19. Alertar accesos fuera de horario laboral
DELIMITER //
CREATE EVENT evt_acc_fuera_horario ON SCHEDULE EVERY 1 HOUR DO
    INSERT INTO log_accesos (mensaje) SELECT CONCAT('Acceso fuera de horario: ', usuario_id) FROM accesos WHERE HOUR(fecha_hora) NOT BETWEEN 8 AND 20 AND fecha_hora > DATE_SUB(NOW(), INTERVAL 1 HOUR);
DELIMITER ;

-- 20. Top 10 usuarios más frecuentes (mensual)
DELIMITER //
CREATE EVENT evt_acc_top_usuarios ON SCHEDULE EVERY 1 MONTH DO
    INSERT INTO reportes_generados (tipo, datos) SELECT 'TOP_USUARIOS', CONCAT(usuario_id, ': ', COUNT(*)) FROM accesos WHERE MONTH(fecha_hora) = MONTH(CURDATE()) GROUP BY usuario_id ORDER BY COUNT(*) DESC LIMIT 10;
DELIMITER ;