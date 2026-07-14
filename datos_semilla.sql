-- 1. Empresas
INSERT INTO empresas (id, nombre, razon_social, rfc_nit, email_contacto, telefono, direccion, persona_contacto, estado) VALUES
('e1d51a66-72cb-4560-a299-fb82939e0f31', 'Tech Solutions S.A.', 'Tech Solutions Sociedad Anónima', '123456789-0', 'contacto@techsolutions.com', '555-0101', 'Calle Falsa 123', 'Juan Pérez', 'ACTIVA'),
('e2d51a66-72cb-4560-a299-fb82939e0f32', 'Creative Design Studio', 'Creative Design Studio S.A.S.', '987654321-1', 'info@creativedesign.com', '555-0102', 'Av. Siempreviva 742', 'María Gómez', 'ACTIVA'),
('e3d51a66-72cb-4560-a299-fb82939e0f33', 'Finance Group', 'Finance & Consulting Group', '456789123-2', 'admin@financegroup.com', '555-0103', 'Paseo de la Reforma 456', 'Carlos Ruiz', 'ACTIVA');

-- 2. Usuarios
INSERT INTO usuario (id, identificacion, nombre, apellidos, fecha_nacimiento, email, telefono, direccion, empresa_id, estado) VALUES
('u1d51a66-72cb-4560-a299-fb82939e0f01', 'ID-1001', 'Juan', 'Perez', '1985-04-12', 'juan.perez@techsolutions.com', '555-1111', 'Calle A 1', 'e1d51a66-72cb-4560-a299-fb82939e0f31', 'ACTIVO'),
('u2d51a66-72cb-4560-a299-fb82939e0f02', 'ID-1002', 'Maria', 'Gomez', '1990-08-22', 'maria.gomez@creativedesign.com', '555-2222', 'Calle B 2', 'e2d51a66-72cb-4560-a299-fb82939e0f32', 'ACTIVO'),
('u3d51a66-72cb-4560-a299-fb82939e0f03', 'ID-1003', 'Carlos', 'Ruiz', '1978-12-05', 'carlos.ruiz@gmail.com', '555-3333', 'Calle C 3', NULL, 'ACTIVO'),
('u4d51a66-72cb-4560-a299-fb82939e0f04', 'ID-1004', 'Ana', 'Martinez', '1993-01-15', 'ana.martinez@techsolutions.com', '555-4444', 'Calle D 4', 'e1d51a66-72cb-4560-a299-fb82939e0f31', 'ACTIVO'),
('u5d51a66-72cb-4560-a299-fb82939e0f05', 'ID-1005', 'Luis', 'Hernandez', '1988-06-30', 'luis.hernandez@financegroup.com', '555-5555', 'Calle E 5', 'e3d51a66-72cb-4560-a299-fb82939e0f33', 'ACTIVO'),
('u6d51a66-72cb-4560-a299-fb82939e0f06', 'ID-1006', 'Sofia', 'Diaz', '1995-10-10', 'sofia.diaz@gmail.com', '555-6666', 'Calle F 6', NULL, 'ACTIVO'),
('u7d51a66-72cb-4560-a299-fb82939e0f07', 'ID-1007', 'Pedro', 'Lopez', '1982-11-25', 'pedro.lopez@gmail.com', '555-7777', 'Calle G 7', NULL, 'ACTIVO'),
('u8d51a66-72cb-4560-a299-fb82939e0f08', 'ID-1008', 'Admin', 'Coworking', '1980-01-01', 'admin@cowork.com', '555-8888', 'Coworking Central', NULL, 'ACTIVO'),
('u9d51a66-72cb-4560-a299-fb82939e0f09', 'ID-1009', 'Laura', 'Recepcionista', '1992-05-18', 'laura.recepcion@cowork.com', '555-9999', 'Recepcion Desk', NULL, 'ACTIVO'),
('u1051a66-72cb-4560-a299-fb82939e0f10', 'ID-1010', 'Diego', 'Torres', '1989-03-14', 'diego.torres@gmail.com', '555-1010', 'Calle H 8', NULL, 'ACTIVO'),
('u1151a66-72cb-4560-a299-fb82939e0f11', 'ID-1011', 'Elena', 'Castro', '1991-07-21', 'elena.castro@techsolutions.com', '555-1112', 'Calle I 9', 'e1d51a66-72cb-4560-a299-fb82939e0f31', 'ACTIVO'),
('u1251a66-72cb-4560-a299-fb82939e0f12', 'ID-1012', 'Ricardo', 'Silva', '1984-09-09', 'ricardo.silva@financegroup.com', '555-1212', 'Calle J 10', 'e3d51a66-72cb-4560-a299-fb82939e0f33', 'ACTIVO'),
('u1351a66-72cb-4560-a299-fb82939e0f13', 'ID-1013', 'Carmen', 'Vega', '1994-12-02', 'carmen.vega@creativedesign.com', '555-1313', 'Calle K 11', 'e2d51a66-72cb-4560-a299-fb82939e0f32', 'ACTIVO'),
('u1451a66-72cb-4560-a299-fb82939e0f14', 'ID-1014', 'Fernando', 'Rios', '1987-11-11', 'fernando.rios@gmail.com', '555-1414', 'Calle L 12', NULL, 'ACTIVO'),
('u1551a66-72cb-4560-a299-fb82939e0f15', 'ID-1015', 'Gabriela', 'Sanz', '1996-02-28', 'gabriela.sanz@gmail.com', '555-1515', 'Calle M 13', NULL, 'ACTIVO');

-- 3. Tipos de Membresía
INSERT INTO tipos_membresia (id, nombre, descripcion, duracion_dias, precio_base, limite_horas_mes, acceso_sala_evento, acceso_sala_reuniones, servicio_incluidos, estado) VALUES
('m1d51a66-72cb-4560-a299-fb82939e0f21', 'Diaria', 'Acceso por un día a escritorios flexibles', 1, 15.00, 12, FALSE, FALSE, '{"cafe": "limitado", "internet": "basico"}', 'ACTIVO'),
('m2d51a66-72cb-4560-a299-fb82939e0f22', 'Mensual', 'Acceso mensual individual a escritorios flexibles', 30, 120.00, 160, FALSE, TRUE, '{"cafe": "ilimitado", "internet": "alta_velocidad", "impresiones": 50}', 'ACTIVO'),
('m3d51a66-72cb-4560-a299-fb82939e0f23', 'Corporativa', 'Membresía para equipos corporativos', 30, 100.00, 160, TRUE, TRUE, '{"cafe": "ilimitado", "internet": "alta_velocidad", "impresiones": 100, "salas_reuniones": 10}', 'ACTIVO'),
('m4d51a66-72cb-4560-a299-fb82939e0f24', 'Premium', 'Acceso ilimitado 24/7 y beneficios premium', 30, 250.00, 999, TRUE, TRUE, '{"cafe": "ilimitado", "internet": "premium", "impresiones": "ilimitadas", "locker": true}', 'ACTIVO');

-- 4. Membresía Usuario
INSERT INTO membresia_usuario (id, usuario_id, tipo_membresia_id, fecha_inicio, fecha_fin, fecha_contratacion, estado, renovaciones, precio_pagado) VALUES
('mu-1001', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'm4d51a66-72cb-4560-a299-fb82939e0f24', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 'ACTIVA', 5, 250.00),
('mu-1002', 'u2d51a66-72cb-4560-a299-fb82939e0f02', 'm2d51a66-72cb-4560-a299-fb82939e0f22', '2026-07-01', '2026-07-31', '2026-07-01 09:15:00', 'ACTIVA', 2, 120.00),
('mu-1003', 'u6d51a66-72cb-4560-a299-fb82939e0f06', 'm4d51a66-72cb-4560-a299-fb82939e0f24', '2026-06-01', '2026-06-30', '2026-06-01 10:00:00', 'SUSPENDIDA', 1, 250.00),
('mu-1004', 'u7d51a66-72cb-4560-a299-fb82939e0f07', 'm1d51a66-72cb-4560-a299-fb82939e0f21', '2026-06-15', '2026-06-16', '2026-06-15 08:30:00', 'VENCIDA', 11, 15.00),
('mu-1005', 'u4d51a66-72cb-4560-a299-fb82939e0f04', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:30:00', 'ACTIVA', 3, 100.00),
('mu-1006', 'u5d51a66-72cb-4560-a299-fb82939e0f05', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:45:00', 'ACTIVA', 4, 100.00),
('mu-1007', 'u1151a66-72cb-4560-a299-fb82939e0f11', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 'ACTIVA', 0, 100.00),
('mu-1008', 'u1251a66-72cb-4560-a299-fb82939e0f12', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 'ACTIVA', 0, 100.00),
('mu-1009', 'u1351a66-72cb-4560-a299-fb82939e0f13', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 'ACTIVA', 0, 100.00),
('mu-1010', 'u1451a66-72cb-4560-a299-fb82939e0f14', 'm2d51a66-72cb-4560-a299-fb82939e0f22', '2026-07-05', '2026-08-04', '2026-07-05 10:00:00', 'ACTIVA', 0, 120.00),
('mu-1011', 'u1551a66-72cb-4560-a299-fb82939e0f15', 'm1d51a66-72cb-4560-a299-fb82939e0f21', '2026-07-10', '2026-07-11', '2026-07-10 11:00:00', 'ACTIVA', 0, 15.00);

-- 5. Tipos de Espacio
INSERT INTO tipos_espacios (id, nombre, descripcion, tarifa_base_hora, tarifa_base_dia, capacidad_minima, capacidad_maxima, estado) VALUES
('te-1', 'Escritorio Flexible', 'Escritorio de uso libre en zona compartida', 5.00, 20.00, 1, 1, 'ACTIVO'),
('te-2', 'Oficina Privada', 'Oficina privada para equipos pequeños o individuales', 25.00, 150.00, 1, 4, 'ACTIVO'),
('te-3', 'Sala de Reuniones', 'Sala con proyector y pizarra para reuniones de grupo', 15.00, 80.00, 2, 10, 'ACTIVO'),
('te-4', 'Sala de Eventos', 'Espacio amplio para presentaciones, conferencias o talleres', 50.00, 300.00, 10, 50, 'ACTIVO');

-- 6. Espacios
INSERT INTO espacios (id, codigo, nombre, tipo_espacio_id, piso, ubicacion, capacidad, tamano_m2, hora_apertura, hora_cierre, dias_disponibles, tiene_vista_exterior, precio_personalizado, estado) VALUES
('esp-1', 'ESC-01', 'Escritorio Flexible A1', 'te-1', 1, 'Zona Abierta Ala Norte', 1, 2.00, '08:00:00', '20:00:00', 127, FALSE, 20.00, 'DISPONIBLE'),
('esp-2', 'ESC-02', 'Escritorio Flexible A2', 'te-1', 1, 'Zona Abierta Ala Norte', 1, 2.00, '08:00:00', '20:00:00', 127, FALSE, 20.00, 'DISPONIBLE'),
('esp-3', 'OFI-01', 'Oficina Privada Ejecutiva 1', 'te-2', 2, 'Piso 2 Ala Oeste', 4, 15.00, '08:00:00', '22:00:00', 127, TRUE, 150.00, 'DISPONIBLE'),
('esp-4', 'REU-01', 'Sala de Reuniones Creativa', 'te-3', 1, 'Piso 1 Centro', 8, 20.00, '08:00:00', '20:00:00', 127, FALSE, 80.00, 'DISPONIBLE'),
('esp-5', 'EVE-01', 'Gran Auditorio Cowork', 'te-4', 1, 'Piso 1 Sur', 40, 80.00, '09:00:00', '22:00:00', 127, TRUE, 300.00, 'DISPONIBLE'),
('esp-6', 'OFI-02', 'Oficina Privada 2', 'te-2', 2, 'Piso 2 Ala Oeste', 2, 10.00, '08:00:00', '20:00:00', 127, FALSE, 120.00, 'DISPONIBLE');

-- 7. Reservas
INSERT INTO reservas (id, codigo, usuario_id, espacio_id, fecha_reserva, hora_inicio, hora_fin, duracion_horas, numero_asistentes, motivo, estado, precio_total, descuento_aplicado, precio_final, fecha_creacion, fecha_confirmacion) VALUES
('res-1001', 'RES-260710-01', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'esp-3', '2026-07-10', '09:00:00', '18:00:00', 9.00, 3, 'Reunión de desarrollo', 'CONFIRMADA', 150.00, 0.00, 150.00, '2026-07-09 10:00:00', '2026-07-09 10:05:00'),
('res-1002', 'RES-260710-02', 'u2d51a66-72cb-4560-a299-fb82939e0f02', 'esp-4', '2026-07-10', '09:30:00', '11:00:00', 1.50, 6, 'Sprint Planning', 'CONFIRMADA', 22.50, 0.00, 22.50, '2026-07-09 11:00:00', '2026-07-09 11:10:00'),
('res-1003', 'RES-260615-01', 'u3d51a66-72cb-4560-a299-fb82939e0f03', 'esp-1', '2026-06-15', '09:00:00', '17:00:00', 8.00, 1, 'Trabajo diario', 'CANCELADA', 20.00, 0.00, 20.00, '2026-06-14 15:00:00', NULL),
('res-1004', 'RES-260701-01', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'esp-1', '2026-07-01', '08:00:00', '12:00:00', 4.00, 1, 'Trabajo', 'COMPLETADA', 20.00, 0.00, 20.00, '2026-06-30 09:00:00', '2026-06-30 09:10:00'),
('res-1005', 'RES-260702-01', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'esp-1', '2026-07-02', '08:00:00', '12:00:00', 4.00, 1, 'Trabajo', 'COMPLETADA', 20.00, 0.00, 20.00, '2026-06-30 09:00:00', '2026-06-30 09:10:00'),
('res-1006', 'RES-260703-01', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'esp-1', '2026-07-03', '08:00:00', '12:00:00', 4.00, 1, 'Trabajo', 'COMPLETADA', 20.00, 0.00, 20.00, '2026-06-30 09:00:00', '2026-06-30 09:10:00'),
('res-1007', 'RES-260706-01', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'esp-1', '2026-07-06', '08:00:00', '12:00:00', 4.00, 1, 'Trabajo', 'COMPLETADA', 20.00, 0.00, 20.00, '2026-06-30 09:00:00', '2026-06-30 09:10:00'),
('res-1008', 'RES-260707-01', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'esp-1', '2026-07-07', '08:00:00', '12:00:00', 4.00, 1, 'Trabajo', 'COMPLETADA', 20.00, 0.00, 20.00, '2026-06-30 09:00:00', '2026-06-30 09:10:00'),
('res-1009', 'RES-260708-01', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'esp-1', '2026-07-08', '08:00:00', '12:00:00', 4.00, 1, 'Trabajo', 'COMPLETADA', 20.00, 0.00, 20.00, '2026-06-30 09:00:00', '2026-06-30 09:10:00'),
('res-1010', 'RES-260704-01', 'u3d51a66-72cb-4560-a299-fb82939e0f03', 'esp-4', '2026-07-04', '10:00:00', '15:00:00', 5.00, 5, 'Taller sábado', 'COMPLETADA', 75.00, 0.00, 75.00, '2026-07-02 12:00:00', '2026-07-02 12:05:00'),
('res-1011', 'RES-260715-01', 'u5d51a66-72cb-4560-a299-fb82939e0f05', 'esp-5', '2026-07-15', '09:00:00', '19:00:00', 10.00, 35, 'Conferencia Financiera Anual', 'CONFIRMADA', 1200.00, 100.00, 1100.00, '2026-07-05 10:00:00', '2026-07-05 10:30:00'),
('res-1012', 'RES-260710-03', 'u3d51a66-72cb-4560-a299-fb82939e0f03', 'esp-4', '2026-07-10', '10:00:00', '12:00:00', 2.00, 4, 'Reunión Solapada', 'PENDIENTE', 30.00, 0.00, 30.00, '2026-07-10 09:00:00', NULL),
('res-1013', 'RES-260510-01', 'u2d51a66-72cb-4560-a299-fb82939e0f02', 'esp-5', '2026-05-10', '10:00:00', '15:00:00', 5.00, 20, 'Showcase de Diseño', 'COMPLETADA', 250.00, 0.00, 250.00, '2026-05-01 10:00:00', '2026-05-01 10:05:00');

-- 8. Reservas Clientes
INSERT INTO reservas_clientes (id, reserva_id, usuario_id, asistio) VALUES
('rc-1', 'res-1001', 'u1d51a66-72cb-4560-a299-fb82939e0f01', TRUE),
('rc-2', 'res-1002', 'u2d51a66-72cb-4560-a299-fb82939e0f02', TRUE),
('rc-3', 'res-1004', 'u1d51a66-72cb-4560-a299-fb82939e0f01', TRUE),
('rc-4', 'res-1005', 'u1d51a66-72cb-4560-a299-fb82939e0f01', TRUE),
('rc-5', 'res-1006', 'u1d51a66-72cb-4560-a299-fb82939e0f01', TRUE),
('rc-6', 'res-1007', 'u1d51a66-72cb-4560-a299-fb82939e0f01', TRUE),
('rc-7', 'res-1008', 'u1d51a66-72cb-4560-a299-fb82939e0f01', TRUE),
('rc-8', 'res-1009', 'u1d51a66-72cb-4560-a299-fb82939e0f01', TRUE),
('rc-9', 'res-1010', 'u3d51a66-72cb-4560-a299-fb82939e0f03', TRUE),
('rc-10', 'res-1013', 'u2d51a66-72cb-4560-a299-fb82939e0f02', TRUE);

-- 9. Servicios Adicionales
INSERT INTO servicios_adicionales (id, codigo, nombre, descripcion, categorias, unidad_cobro, precio_unitario, impuesto_aplicable, disponibilidad_limitada, stock_disponible, estado) VALUES
('sa-1', 'INT-PREM', 'Internet Premium Simétrico', 'Conexión de fibra simétrica 500mbps', 'CONECTIVIDAD', 'POR MES', 20.00, 0.16, FALSE, NULL, 'ACTIVO'),
('sa-2', 'LCK-01', 'Locker Grande', 'Casillero metálico con cerradura digital', 'ALMACENAMIENTO', 'POR MES', 15.00, 0.16, TRUE, 20, 'ACTIVO'),
('sa-3', 'CAF-ILIM', 'Café Ilmitado', 'Acceso ilimitado a barra de bebidas calientes', 'ALIMENTOS', 'POR DIA', 5.00, 0.08, FALSE, NULL, 'ACTIVO'),
('sa-4', 'IMP-BN', 'Impresiones B/N', 'Servicio de impresión monocromática por página', 'IMPRESION', 'POR USO', 0.10, 0.16, FALSE, NULL, 'ACTIVO'),
('sa-5', 'PROJ-HD', 'Uso de Proyector HD', 'Renta de proyector de alta definición', 'EQUIPAMIENTO', 'POR HORA', 10.00, 0.16, TRUE, 5, 'ACTIVO');

-- 10. Servicios Contratados
INSERT INTO servicios_contratados (id, codigo, usuario_id, servicio_id, reserva_id, fecha_uso, cantidad, unidad_cobro, precio_unitario, subtotal, total, estado) VALUES
('sc-1', 'SC-1001', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'sa-1', NULL, '2026-07-01', 1.00, 'POR MES', 20.00, 20.00, 23.20, 'FACTURADO'),
('sc-2', 'SC-1002', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'sa-2', NULL, '2026-07-01', 1.00, 'POR MES', 15.00, 15.00, 17.40, 'FACTURADO'),
('sc-3', 'SC-1003', 'u2d51a66-72cb-4560-a299-fb82939e0f02', 'sa-3', 'res-1002', '2026-07-10', 1.00, 'POR DIA', 5.00, 5.00, 5.40, 'USADO'),
('sc-4', 'SC-1004', 'u3d51a66-72cb-4560-a299-fb82939e0f03', 'sa-5', 'res-1010', '2026-07-04', 5.00, 'POR HORA', 10.00, 50.00, 58.00, 'USADO');

-- 11. Métodos de Pago
INSERT INTO metodos_pago (id, codigo, nombre, descripcion, estado) VALUES
('mp-1', 'EFECTIVO', 'Efectivo', 'Pago presencial en caja', 'ACTIVO'),
('mp-2', 'TARJETA', 'Tarjeta de Crédito / Débito', 'Terminal bancaria o pago en línea', 'ACTIVO'),
('mp-3', 'TRANSFERENCIA', 'Transferencia Bancaria', 'SPEI / Wire Transfer', 'ACTIVO'),
('mp-4', 'PAYPAL', 'PayPal', 'Pago digital internacional', 'ACTIVO');

-- 12. Facturas
INSERT INTO facturas (id, numero_factura, usuario_id, empresa_id, tipo_factura, fecha_vencimiento, subtotal, impuesto, descuento, total, saldo_pendiente, estado) VALUES
('fac-1001', 'FAC-MEM-01', 'u1d51a66-72cb-4560-a299-fb82939e0f01', NULL, 'MEMBRESIA', '2026-07-05', 250.00, 40.00, 0.00, 290.00, 0.00, 'PAGADA'),
('fac-1002', 'FAC-RES-01', 'u1d51a66-72cb-4560-a299-fb82939e0f01', NULL, 'RESERVA', '2026-07-15', 150.00, 24.00, 0.00, 174.00, 0.00, 'PAGADA'),
('fac-1003', 'FAC-RES-02', 'u5d51a66-72cb-4560-a299-fb82939e0f05', 'e3d51a66-72cb-4560-a299-fb82939e0f33', 'RESERVA', '2026-07-20', 1100.00, 176.00, 0.00, 1276.00, 1276.00, 'PENDIENTE'),
('fac-1004', 'FAC-MEM-02', 'u2d51a66-72cb-4560-a299-fb82939e0f02', NULL, 'MEMBRESIA', '2026-07-05', 120.00, 19.20, 0.00, 139.20, 139.20, 'PENDIENTE'),
('fac-1005', 'FAC-RES-03', 'u3d51a66-72cb-4560-a299-fb82939e0f03', NULL, 'RESERVA', '2026-06-20', 20.00, 3.20, 0.00, 23.20, 0.00, 'ANULADA'),
('fac-1006', 'FAC-MEM-03', 'u3d51a66-72cb-4560-a299-fb82939e0f03', NULL, 'MEMBRESIA', '2026-07-15', 15.00, 2.40, 0.00, 17.40, 7.40, 'PARCIAL'),
('fac-1007', 'FAC-CORP-01', 'u4d51a66-72cb-4560-a299-fb82939e0f04', 'e1d51a66-72cb-4560-a299-fb82939e0f31', 'CONSOLIDADA', '2026-07-15', 300.00, 48.00, 0.00, 348.00, 0.00, 'PAGADA');

-- 13. Detalle Factura
INSERT INTO detalle_factura (id, factura_id, concepto, cantidad, precio_unitario, subtotal, total, referencia_tipo, referencia_id) VALUES
('df-1', 'fac-1001', 'Membresía Premium - Julio 2026', 1.00, 250.00, 250.00, 290.00, 'MEMBRESIA', 'mu-1001'),
('df-2', 'fac-1002', 'Reserva Oficina OFI-01 (RES-260710-01)', 1.00, 150.00, 150.00, 174.00, 'RESERVA', 'res-1001'),
('df-3', 'fac-1003', 'Reserva Gran Auditorio EVE-01 (RES-260715-01)', 1.00, 1100.00, 1100.00, 1276.00, 'RESERVA', 'res-1011'),
('df-4', 'fac-1004', 'Membresía Mensual - Julio 2026', 1.00, 120.00, 120.00, 139.20, 'MEMBRESIA', 'mu-1002'),
('df-5', 'fac-1005', 'Reserva Escritorio ESC-01 Cancelada', 1.00, 20.00, 20.00, 23.20, 'RESERVA', 'res-1003'),
('df-6', 'fac-1006', 'Membresía Diaria - Julio 2026', 1.00, 15.00, 15.00, 17.40, 'MEMBRESIA', 'mu-1004'),
('df-7', 'fac-1007', 'Consolidado Empleados Tech Solutions - Julio', 3.00, 100.00, 300.00, 348.00, 'MEMBRESIA', 'mu-1005');

-- 14. Pagos
INSERT INTO pagos (id, codigo_pago, factura_id, usuario_id, metodo_pago_id, monto, comision, monto_neto, estado, referencia_externa) VALUES
('pag-1', 'PAG-0001', 'fac-1001', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'mp-2', 290.00, 0.00, 290.00, 'PAGADO', 'TXN-12345'),
('pag-2', 'PAG-0002', 'fac-1002', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'mp-2', 174.00, 0.00, 174.00, 'PAGADO', 'TXN-12346'),
('pag-3', 'PAG-0003', 'fac-1006', 'u3d51a66-72cb-4560-a299-fb82939e0f03', 'mp-1', 10.00, 0.00, 10.00, 'PAGADO', NULL),
('pag-4', 'PAG-0004', 'fac-1007', 'u4d51a66-72cb-4560-a299-fb82939e0f04', 'mp-3', 348.00, 0.00, 348.00, 'PAGADO', 'TRANSF-999'),
('pag-5', 'PAG-0005', 'fac-1005', 'u3d51a66-72cb-4560-a299-fb82939e0f03', 'mp-4', 23.20, 0.69, 22.51, 'CANCELADO', 'PAYPAL-REF');

-- 15. Credenciales de Acceso
INSERT INTO credenciales_acceso (id, usuario_id, tipo_credencial, codigo, estado) VALUES
('cr-1', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'RFID', 'RFID-11111', 'ACTIVA'),
('cr-2', 'u2d51a66-72cb-4560-a299-fb82939e0f02', 'QR', 'QR-22222', 'ACTIVA'),
('cr-3', 'u3d51a66-72cb-4560-a299-fb82939e0f03', 'RFID', 'RFID-33333', 'ACTIVA'),
('cr-4', 'u4d51a66-72cb-4560-a299-fb82939e0f04', 'RFID', 'RFID-44444', 'ACTIVA'),
('cr-5', 'u5d51a66-72cb-4560-a299-fb82939e0f05', 'QR', 'QR-55555', 'ACTIVA'),
('cr-6', 'u6d51a66-72cb-4560-a299-fb82939e0f06', 'RFID', 'RFID-66666', 'REVOCADA'),
('cr-7', 'u7d51a66-72cb-4560-a299-fb82939e0f07', 'RFID', 'RFID-77777', 'VENCIDA');

-- 16. Accesos
INSERT INTO accesos (id, usuario_id, credencial_id, tipo_acceso, metodo_validacion, fecha_hora, punto_acceso, validacion_membresia, validacion_reserva, estado) VALUES
('acc-1', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'cr-1', 'ENTRADA', 'RFID', '2026-07-10 08:30:00', 'Entrada Principal', 'ACTIVA', 'CON_RESERVA', 'PERMITIDO'),
('acc-2', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'cr-1', 'SALIDA', 'RFID', '2026-07-10 13:00:00', 'Salida Principal', 'ACTIVA', 'CON_RESERVA', 'PERMITIDO'),
('acc-3', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'cr-1', 'ENTRADA', 'RFID', '2026-07-10 14:00:00', 'Entrada Principal', 'ACTIVA', 'CON_RESERVA', 'PERMITIDO'),
('acc-4', 'u2d51a66-72cb-4560-a299-fb82939e0f02', 'cr-2', 'ENTRADA', 'QR', '2026-07-10 09:15:00', 'Entrada Principal', 'ACTIVA', 'CON_RESERVA', 'PERMITIDO'),
('acc-5', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'cr-1', 'ENTRADA', 'RFID', '2026-07-10 05:00:00', 'Entrada Principal', 'ACTIVA', 'CON_RESERVA', 'PERMITIDO'),
('acc-6', 'u3d51a66-72cb-4560-a299-fb82939e0f03', 'cr-3', 'ENTRADA', 'RFID', '2026-07-04 09:45:00', 'Entrada Principal', 'ACTIVA', 'CON_RESERVA', 'PERMITIDO'),
('acc-7', 'u3d51a66-72cb-4560-a299-fb82939e0f03', 'cr-3', 'SALIDA', 'RFID', '2026-07-04 15:15:00', 'Salida Principal', 'ACTIVA', 'CON_RESERVA', 'PERMITIDO');

-- 17. Intentos de Acceso Rechazados
INSERT INTO intentos_acceso_rechazados (id, usuario_id, credencial_id, codigo_intentado, metodo_validacion, fecha_hora, punto_acceso, motivo_rechazo, descripcion_detallada) VALUES
('iar-1', 'u6d51a66-72cb-4560-a299-fb82939e0f06', 'cr-6', 'RFID-66666', 'RFID', '2026-07-10 09:00:00', 'Entrada Principal', 'MEMBRESIA_SUSPENDIDA', 'Intento de acceso con credencial revocada por suspensión'),
('iar-2', 'u7d51a66-72cb-4560-a299-fb82939e0f07', 'cr-7', 'RFID-77777', 'RFID', '2026-07-10 09:10:00', 'Entrada Principal', 'MEMBRESIA_VENCIDA', 'Intento de acceso con credencial vencida'),
('iar-3', NULL, NULL, 'QR-INVALID-999', 'QR', '2026-07-10 09:20:00', 'Entrada Principal', 'CREDENCIAL_INVALIDA', 'Código QR no reconocido en la base de datos');

-- 18. Roles del Sistema
INSERT INTO roles (id, codigo, nombre, descripcion, nivel_acceso, es_sistema) VALUES
('r-1', 'ADMINISTRADOR', 'Administrador del Coworking', 'Acceso total al sistema', 10, TRUE),
('r-2', 'RECEPCIONISTA', 'Recepcionista', 'Registro de usuarios, membresías y gestión de reservas', 5, TRUE),
('r-3', 'USUARIO', 'Usuario', 'Miembro del coworking con acceso básico a reservas y facturas', 1, TRUE),
('r-4', 'GERENTE_CORP', 'Gerente Corporativo', 'Administración de empleados y facturación de la empresa', 3, TRUE),
('r-5', 'CONTADOR', 'Contador', 'Gestión de ingresos, facturas y reportes financieros', 4, TRUE);

-- 19. Permisos Básicos
INSERT INTO permisos (id, codigo, nombre, descripcion, modulo, accion, es_sistema) VALUES
('p-1', 'USUARIOS_CREAR', 'Crear Usuarios', 'Creación de cuentas de clientes', 'USUARIOS', 'CREAR', TRUE),
('p-2', 'RESERVAS_CREAR', 'Crear Reservas', 'Realizar reservas de espacios', 'RESERVAS', 'CREAR', TRUE),
('p-3', 'FACTURAS_VER', 'Ver Facturas', 'Consultar comprobantes de pago', 'FACTURAS', 'VER', TRUE),
('p-4', 'REPORTES_FINANCIEROS', 'Ver Reportes Financieros', 'Acceso a balances de ingresos', 'REPORTES', 'EJECUTAR', TRUE);

-- 20. Roles y Permisos
INSERT INTO roles_permisos (rol_id, permiso_id, estado) VALUES
('r-1', 'p-1', 'ACTIVO'),
('r-1', 'p-2', 'ACTIVO'),
('r-1', 'p-3', 'ACTIVO'),
('r-1', 'p-4', 'ACTIVO'),
('r-2', 'p-1', 'ACTIVO'),
('r-2', 'p-2', 'ACTIVO'),
('r-2', 'p-3', 'ACTIVO'),
('r-3', 'p-2', 'ACTIVO'),
('r-3', 'p-3', 'ACTIVO');

-- 21. Usuarios y sus Roles
INSERT INTO usuarios_roles (usuario_id, rol_id, estado) VALUES
('u8d51a66-72cb-4560-a299-fb82939e0f08', 'r-1', 'ACTIVO'),
('u9d51a66-72cb-4560-a299-fb82939e0f09', 'r-2', 'ACTIVO'),
('u1d51a66-72cb-4560-a299-fb82939e0f01', 'r-3', 'ACTIVO'),
('u4d51a66-72cb-4560-a299-fb82939e0f04', 'r-4', 'ACTIVO'),
('u5d51a66-72cb-4560-a299-fb82939e0f05', 'r-5', 'ACTIVO');

-- Insertar datos de prueba para el historial de cambios de membresía de Juan Pérez (usuario: u1d51a66-72cb-4560-a299-fb82939e0f01)
INSERT INTO historial_cambio_membresia (id, membresia_usuario_id, usuario_id, tipo_anterior_id, tipo_nuevo_id, usuario_modifico, fecha_cambio, motivo) VALUES
('hcm-1001', 'mu-1001', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'm1d51a66-72cb-4560-a299-fb82939e0f21', 'm2d51a66-72cb-4560-a299-fb82939e0f22', 'u8d51a66-72cb-4560-a299-fb82939e0f08', '2026-02-01 10:00:00', 'Upgrade a Mensual'),
('hcm-1002', 'mu-1001', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'm2d51a66-72cb-4560-a299-fb82939e0f22', 'm3d51a66-72cb-4560-a299-fb82939e0f23', 'u8d51a66-72cb-4560-a299-fb82939e0f08', '2026-04-15 11:30:00', 'Cambio a Corporativo'),
('hcm-1003', 'mu-1001', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'm3d51a66-72cb-4560-a299-fb82939e0f23', 'm4d51a66-72cb-4560-a299-fb82939e0f24', 'u8d51a66-72cb-4560-a299-fb82939e0f08', '2026-07-01 09:00:00', 'Upgrade a Premium');

4. Membresía Usuario
INSERT INTO membresia_usuario (id, usuario_id, tipo_membresia_id, fecha_inicio, fecha_fin, fecha_contratacion, estado, renovaciones, precio_pagado) VALUES
('mu-1001', 'u1d51a66-72cb-4560-a299-fb82939e0f01', 'm4d51a66-72cb-4560-a299-fb82939e0f24', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 'ACTIVA', 5, 250.00),
('mu-1002', 'u2d51a66-72cb-4560-a299-fb82939e0f02', 'm2d51a66-72cb-4560-a299-fb82939e0f22', '2026-07-01', '2026-07-31', '2026-07-01 09:15:00', 'ACTIVA', 2, 120.00),
('mu-1003', 'u6d51a66-72cb-4560-a299-fb82939e0f06', 'm4d51a66-72cb-4560-a299-fb82939e0f24', '2026-06-01', '2026-06-30', '2026-06-01 10:00:00', 'SUSPENDIDA', 1, 250.00),
('mu-1004', 'u7d51a66-72cb-4560-a299-fb82939e0f07', 'm1d51a66-72cb-4560-a299-fb82939e0f21', '2026-06-15', '2026-06-16', '2026-06-15 08:30:00', 'VENCIDA', 11, 15.00),
('mu-1005', 'u4d51a66-72cb-4560-a299-fb82939e0f04', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:30:00', 'ACTIVA', 3, 100.00),
('mu-1006', 'u5d51a66-72cb-4560-a299-fb82939e0f05', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:45:00', 'ACTIVA', 4, 100.00),
('mu-1007', 'u1151a66-72cb-4560-a299-fb82939e0f11', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 'ACTIVA', 0, 100.00),
('mu-1008', 'u1251a66-72cb-4560-a299-fb82939e0f12', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 'ACTIVA', 0, 100.00),
('mu-1009', 'u1351a66-72cb-4560-a299-fb82939e0f13', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 'ACTIVA', 0, 100.00),
('mu-1010', 'u1451a66-72cb-4560-a299-fb82939e0f14', 'm2d51a66-72cb-4560-a299-fb82939e0f22', '2026-07-05', '2026-08-04', '2026-07-05 10:00:00', 'ACTIVA', 0, 120.00),
('mu-1011', 'u1551a66-72cb-4560-a299-fb82939e0f15', 'm1d51a66-72cb-4560-a299-fb82939e0f21', '2026-07-15', '2026-07-16', '2026-07-15 11:00:00', 'ACTIVA', 0, 15.00);

-- =========================================================================
-- DATOS ADICIONALES PARA PRUEBAS (Vencimiento de membresía en próximos 7 días)
-- =========================================================================

INSERT INTO usuario (id, identificacion, nombre, apellidos, fecha_nacimiento, email, telefono, direccion, empresa_id, estado) VALUES
('u1651a66-72cb-4560-a299-fb82939e0f16', 'ID-1016', 'Pedro', 'Velasquez', '1990-01-01', 'pedro.velasquez@gmail.com', '555-1616', 'Calle N 14', NULL, 'ACTIVO');

INSERT INTO membresia_usuario (id, usuario_id, tipo_membresia_id, fecha_inicio, fecha_fin, fecha_contratacion, estado, renovaciones, precio_pagado) VALUES
('mu-1012', 'u1651a66-72cb-4560-a299-fb82939e0f16', 'm2d51a66-72cb-4560-a299-fb82939e0f22', '2026-06-18', '2026-07-18', '2026-06-18 10:00:00', 'ACTIVA', 0, 120.00);


-- =========================================================================
-- NUEVOS DATOS ADICIONALES PARA SATISFACER TODAS LAS CONSULTAS (1 - 100)
-- =========================================================================

-- 1. Nueva Empresa Corporativa (Para cumplir con Query 33 y Query 97 de más de 10 empleados)
INSERT INTO empresas (id, nombre, razon_social, rfc_nit, email_contacto, telefono, direccion, persona_contacto, estado) VALUES
('e-new-1', 'Mega Corp', 'Mega Corp S.A. de C.V.', '999888777-6', 'contacto@megacorp.com', '555-9000', 'Av. de la Reforma 100', 'Carlos Ramos', 'ACTIVA');

-- 2. 11 Nuevos Usuarios bajo la Empresa 'Mega Corp'
INSERT INTO usuario (id, identificacion, nombre, apellidos, fecha_nacimiento, email, telefono, direccion, empresa_id, estado) VALUES
('u1651a66-72cb-4560-a299-fb82939e0f31', 'ID-1031', 'Carlos', 'Ramos', '1985-01-10', 'carlos.ramos@megacorp.com', '555-9031', 'Calle Reforma 101', 'e-new-1', 'ACTIVO'),
('u1651a66-72cb-4560-a299-fb82939e0f32', 'ID-1032', 'Luisa', 'Fernandez', '1990-02-15', 'luisa.fernandez@megacorp.com', '555-9032', 'Calle Reforma 102', 'e-new-1', 'ACTIVO'),
('u1651a66-72cb-4560-a299-fb82939e0f33', 'ID-1033', 'Miguel', 'Angel', '1988-03-20', 'miguel.angel@megacorp.com', '555-9033', 'Calle Reforma 103', 'e-new-1', 'ACTIVO'),
('u1651a66-72cb-4560-a299-fb82939e0f34', 'ID-1034', 'Sofia', 'Castro', '1992-04-25', 'sofia.castro@megacorp.com', '555-9034', 'Calle Reforma 104', 'e-new-1', 'ACTIVO'),
('u1651a66-72cb-4560-a299-fb82939e0f35', 'ID-1035', 'Elena', 'Ruiz', '1987-05-30', 'elena.ruiz@megacorp.com', '555-9035', 'Calle Reforma 105', 'e-new-1', 'ACTIVO'),
('u1651a66-72cb-4560-a299-fb82939e0f36', 'ID-1036', 'Diego', 'Perez', '1991-06-05', 'diego.perez@megacorp.com', '555-9036', 'Calle Reforma 106', 'e-new-1', 'ACTIVO'),
('u1651a66-72cb-4560-a299-fb82939e0f37', 'ID-1037', 'Laura', 'Gomez', '1993-07-10', 'laura.gomez@megacorp.com', '555-9037', 'Calle Reforma 107', 'e-new-1', 'ACTIVO'),
('u1651a66-72cb-4560-a299-fb82939e0f38', 'ID-1038', 'Felipe', 'Diaz', '1986-08-15', 'felipe.diaz@megacorp.com', '555-9038', 'Calle Reforma 108', 'e-new-1', 'ACTIVO'),
('u1651a66-72cb-4560-a299-fb82939e0f39', 'ID-1039', 'Andres', 'Torres', '1989-09-20', 'andres.torres@megacorp.com', '555-9039', 'Calle Reforma 109', 'e-new-1', 'ACTIVO'),
('u1651a66-72cb-4560-a299-fb82939e0f40', 'ID-1040', 'Monica', 'Vega', '1994-10-25', 'monica.vega@megacorp.com', '555-9040', 'Calle Reforma 110', 'e-new-1', 'ACTIVO'),
('u1651a66-72cb-4560-a299-fb82939e0f41', 'ID-1041', 'Gabriel', 'Rios', '1995-11-30', 'gabriel.rios@megacorp.com', '555-9041', 'Calle Reforma 111', 'e-new-1', 'ACTIVO');

-- 3. Membresías Activas para los 11 Nuevos Usuarios
INSERT INTO membresia_usuario (id, usuario_id, tipo_membresia_id, fecha_inicio, fecha_fin, fecha_contratacion, renovaciones, precio_pagado, estado) VALUES
('mu-new-1', 'u1651a66-72cb-4560-a299-fb82939e0f31', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA'),
('mu-new-2', 'u1651a66-72cb-4560-a299-fb82939e0f32', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA'),
('mu-new-3', 'u1651a66-72cb-4560-a299-fb82939e0f33', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA'),
('mu-new-4', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA'),
('mu-new-5', 'u1651a66-72cb-4560-a299-fb82939e0f35', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA'),
('mu-new-6', 'u1651a66-72cb-4560-a299-fb82939e0f36', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA'),
('mu-new-7', 'u1651a66-72cb-4560-a299-fb82939e0f37', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA'),
('mu-new-8', 'u1651a66-72cb-4560-a299-fb82939e0f38', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA'),
('mu-new-9', 'u1651a66-72cb-4560-a299-fb82939e0f39', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA'),
('mu-new-10', 'u1651a66-72cb-4560-a299-fb82939e0f40', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA'),
('mu-new-11', 'u1651a66-72cb-4560-a299-fb82939e0f41', 'm3d51a66-72cb-4560-a299-fb82939e0f23', '2026-07-01', '2026-07-31', '2026-07-01 09:00:00', 0, 100.00, 'ACTIVA');

-- 4. Historial de Cambios de Membresía (Para cumplir con Query 12 de cambiar membresía > 2 veces)
INSERT INTO historial_cambio_membresia (id, membresia_usuario_id, usuario_id, tipo_anterior_id, tipo_nuevo_id, usuario_modifico, fecha_cambio, motivo) VALUES
('hcm-new-1', 'mu-new-1', 'u1651a66-72cb-4560-a299-fb82939e0f31', 'm1d51a66-72cb-4560-a299-fb82939e0f21', 'm2d51a66-72cb-4560-a299-fb82939e0f22', NULL, '2026-07-02 10:00:00', 'Cambio a mensual'),
('hcm-new-2', 'mu-new-1', 'u1651a66-72cb-4560-a299-fb82939e0f31', 'm2d51a66-72cb-4560-a299-fb82939e0f22', 'm3d51a66-72cb-4560-a299-fb82939e0f23', NULL, '2026-07-03 10:00:00', 'Cambio a corporativo'),
('hcm-new-3', 'mu-new-1', 'u1651a66-72cb-4560-a299-fb82939e0f31', 'm3d51a66-72cb-4560-a299-fb82939e0f23', 'm4d51a66-72cb-4560-a299-fb82939e0f24', NULL, '2026-07-04 10:00:00', 'Cambio a premium');

-- 6. Facturas, Detalles y Pagos
-- 6.1 Factura de Membresía PAGADA de $600 para Carlos Ramos (u-new-1) -> Para Query 100
INSERT INTO facturas (id, numero_factura, usuario_id, empresa_id, tipo_factura, fecha_vencimiento, subtotal, impuesto, descuento, total, saldo_pendiente, estado) VALUES
('fac-new-101', 'FAC-NEW-101', 'u1651a66-72cb-4560-a299-fb82939e0f31', NULL, 'MEMBRESIA', '2026-07-20', 517.24, 82.76, 0.00, 600.00, 0.00, 'PAGADA');

INSERT INTO detalle_factura (id, factura_id, concepto, cantidad, precio_unitario, subtotal, total, referencia_tipo, referencia_id) VALUES
('df-new-101', 'fac-new-101', 'Membresía Corporativa Especial', 1.00, 517.24, 517.24, 600.00, 'MEMBRESIA', 'mu-new-1');

INSERT INTO pagos (id, codigo_pago, factura_id, usuario_id, metodo_pago_id, monto, comision, monto_neto, estado, notas, fecha_pago) VALUES
('pag-new-101', 'PAG-NEW-101', 'fac-new-101', 'u1651a66-72cb-4560-a299-fb82939e0f31', 'mp-1', 600.00, 0.00, 600.00, 'PAGADO', 'Pago completo', '2026-07-02 09:00:00');

-- 6.2 Factura PENDIENTE mayor a $200 para Monica Vega (u-new-10) -> Para Query 56 y Query 84 (factura pendiente > $200 y reserva activa)
INSERT INTO facturas (id, numero_factura, usuario_id, empresa_id, tipo_factura, fecha_vencimiento, subtotal, impuesto, descuento, total, saldo_pendiente, estado) VALUES
('fac-new-1001', 'FAC-NEW-1001', 'u1651a66-72cb-4560-a299-fb82939e0f40', NULL, 'MEMBRESIA', '2026-07-20', 258.62, 41.38, 0.00, 300.00, 300.00, 'PENDIENTE');

INSERT INTO detalle_factura (id, factura_id, concepto, cantidad, precio_unitario, subtotal, total, referencia_tipo, referencia_id) VALUES
('df-new-1001', 'fac-new-1001', 'Membresía Mensual Monica', 1.00, 258.62, 258.62, 300.00, 'MEMBRESIA', 'mu-new-10');

-- 6.3 Factura ANULADA para Luisa Fernandez (u-new-2) -> Para satisfacer Query 55 (facturas anuladas)
INSERT INTO facturas (id, numero_factura, usuario_id, empresa_id, tipo_factura, fecha_vencimiento, subtotal, impuesto, descuento, total, saldo_pendiente, estado, motivo_anulacion, fecha_anulacion) VALUES
('fac-new-203', 'FAC-NEW-203', 'u1651a66-72cb-4560-a299-fb82939e0f32', NULL, 'SERVICIO', '2026-07-10', 86.21, 13.79, 0.00, 100.00, 0.00, 'ANULADA', 'Error en facturación', '2026-07-11 11:00:00');

-- 6.4 Factura Vencida con Pago Tardío para Andres Torres (u-new-9) -> Para satisfacer Query 53 (pagos tardíos)
INSERT INTO facturas (id, numero_factura, usuario_id, empresa_id, tipo_factura, fecha_vencimiento, subtotal, impuesto, descuento, total, saldo_pendiente, estado) VALUES
('fac-new-901', 'FAC-NEW-901', 'u1651a66-72cb-4560-a299-fb82939e0f39', NULL, 'MEMBRESIA', '2026-07-10', 86.21, 13.79, 0.00, 100.00, 0.00, 'PAGADA');

INSERT INTO detalle_factura (id, factura_id, concepto, cantidad, precio_unitario, subtotal, total, referencia_tipo, referencia_id) VALUES
('df-new-901', 'fac-new-901', 'Membresía Andres', 1.00, 86.21, 86.21, 100.00, 'MEMBRESIA', 'mu-new-9');

-- Pago el 12-Jul para factura que venció el 10-Jul
INSERT INTO pagos (id, codigo_pago, factura_id, usuario_id, metodo_pago_id, monto, comision, monto_neto, estado, notas, fecha_pago) VALUES
('pag-new-901', 'PAG-NEW-901', 'fac-new-901', 'u1651a66-72cb-4560-a299-fb82939e0f39', 'mp-1', 100.00, 0.00, 100.00, 'PAGADO', 'Pago tardío', '2026-07-12 10:00:00');

-- 6.5 Pago CANCELADO en los últimos 3 meses para Luisa Fernandez (u-new-2) -> Para satisfacer Query 43 (pagos cancelados)
INSERT INTO facturas (id, numero_factura, usuario_id, empresa_id, tipo_factura, fecha_vencimiento, subtotal, impuesto, descuento, total, saldo_pendiente, estado) VALUES
('fac-new-202', 'FAC-NEW-202', 'u1651a66-72cb-4560-a299-fb82939e0f32', NULL, 'SERVICIO', '2026-06-20', 43.10, 6.90, 0.00, 50.00, 50.00, 'PENDIENTE');

INSERT INTO pagos (id, codigo_pago, factura_id, usuario_id, metodo_pago_id, monto, comision, monto_neto, estado, notas, fecha_pago) VALUES
('pag-new-202', 'PAG-NEW-202', 'fac-new-202', 'u1651a66-72cb-4560-a299-fb82939e0f32', 'mp-1', 50.00, 0.00, 50.00, 'CANCELADO', 'Pago anulado por fondos', '2026-06-15 12:00:00');

-- 7. Servicios Contratados Múltiples veces para Carlos Ramos (u-new-1) -> Para satisfacer Query 57 (pagar > 1 vez el mismo servicio)
INSERT INTO servicios_contratados (id, codigo, usuario_id, servicio_id, reserva_id, fecha_uso, cantidad, unidad_cobro, precio_unitario, subtotal, total, estado) VALUES
('sc-new-901', 'SC-NEW-901', 'u1651a66-72cb-4560-a299-fb82939e0f31', 'sa-3', NULL, '2026-07-02', 1.00, 'POR DIA', 5.00, 5.00, 5.40, 'FACTURADO');

-- Factura y pago por primera contratación de sc-new-901
INSERT INTO facturas (id, numero_factura, usuario_id, empresa_id, tipo_factura, fecha_vencimiento, subtotal, impuesto, descuento, total, saldo_pendiente, estado) VALUES
('fac-new-902', 'FAC-NEW-902', 'u1651a66-72cb-4560-a299-fb82939e0f31', NULL, 'SERVICIO', '2026-07-15', 5.00, 0.40, 0.00, 5.40, 0.00, 'PAGADA');

INSERT INTO detalle_factura (id, factura_id, concepto, cantidad, precio_unitario, subtotal, total, referencia_tipo, referencia_id) VALUES
('df-new-902', 'fac-new-902', 'Cafe Ilimitado Dia 1', 1.00, 5.00, 5.00, 5.40, 'SERVICIO', 'sc-new-901');

INSERT INTO pagos (id, codigo_pago, factura_id, usuario_id, metodo_pago_id, monto, comision, monto_neto, estado, notas, fecha_pago) VALUES
('pag-new-902', 'PAG-NEW-902', 'fac-new-902', 'u1651a66-72cb-4560-a299-fb82939e0f31', 'mp-1', 5.40, 0.00, 5.40, 'PAGADO', 'Primer pago servicio', '2026-07-02 18:00:00');

-- Factura y pago por segunda contratación del mismo servicio sc-new-901
INSERT INTO facturas (id, numero_factura, usuario_id, empresa_id, tipo_factura, fecha_vencimiento, subtotal, impuesto, descuento, total, saldo_pendiente, estado) VALUES
('fac-new-903', 'FAC-NEW-903', 'u1651a66-72cb-4560-a299-fb82939e0f31', NULL, 'SERVICIO', '2026-07-16', 5.00, 0.40, 0.00, 5.40, 0.00, 'PAGADA');

INSERT INTO detalle_factura (id, factura_id, concepto, cantidad, precio_unitario, subtotal, total, referencia_tipo, referencia_id) VALUES
('df-new-903', 'fac-new-903', 'Cafe Ilimitado Dia 1 - Copia', 1.00, 5.00, 5.00, 5.40, 'SERVICIO', 'sc-new-901');

INSERT INTO pagos (id, codigo_pago, factura_id, usuario_id, metodo_pago_id, monto, comision, monto_neto, estado, notas, fecha_pago) VALUES
('pag-new-903', 'PAG-NEW-903', 'fac-new-903', 'u1651a66-72cb-4560-a299-fb82939e0f31', 'mp-1', 5.40, 0.00, 5.40, 'PAGADO', 'Segundo pago servicio', '2026-07-03 18:00:00');

-- 8. Credenciales de Acceso
INSERT INTO credenciales_acceso (id, usuario_id, tipo_credencial, codigo, estado) VALUES
('cr-new-4', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'RFID', 'RFID-NEW4', 'ACTIVA'),
('cr-new-5', 'u1651a66-72cb-4560-a299-fb82939e0f35', 'RFID', 'RFID-NEW5', 'ACTIVA'),
('cr-new-6', 'u1651a66-72cb-4560-a299-fb82939e0f36', 'RFID', 'RFID-NEW6', 'ACTIVA'),
('cr-new-8', 'u1651a66-72cb-4560-a299-fb82939e0f38', 'RFID', 'RFID-NEW8', 'ACTIVA');

-- 9. Accesos
-- 9.1 21 Accesos (Entrada/Salida) en Julio 2026 para Sofia Castro (u-new-4) -> Para Query 62 (> 20 asistencias) y Query 71 (acceso pero sin reservas)
INSERT INTO accesos (id, usuario_id, credencial_id, tipo_acceso, metodo_validacion, fecha_hora, punto_acceso, validacion_membresia, validacion_reserva, estado) VALUES
('acc-new-401', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-01 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-402', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-02 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-403', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-03 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-404', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-04 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-405', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-05 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-406', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-06 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-407', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-07 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-408', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-08 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-409', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-09 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-410', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-10 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-411', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-11 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-412', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-12 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-413', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-13 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-414', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-14 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-415', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-15 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-416', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-16 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-417', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-17 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-418', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-18 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-419', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-19 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-420', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-20 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-421', 'u1651a66-72cb-4560-a299-fb82939e0f34', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-21 09:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO');

-- 9.2 Accesos de fin de semana únicamente para Elena Ruiz (u-new-5) -> Para Query 68
INSERT INTO accesos (id, usuario_id, credencial_id, tipo_acceso, metodo_validacion, fecha_hora, punto_acceso, validacion_membresia, validacion_reserva, estado) VALUES
('acc-new-501', 'u1651a66-72cb-4560-a299-fb82939e0f35', 'cr-new-5', 'ENTRADA', 'RFID', '2026-07-11 10:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO'),
('acc-new-502', 'u1651a66-72cb-4560-a299-fb82939e0f35', 'cr-new-5', 'ENTRADA', 'RFID', '2026-07-12 11:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO');

-- 9.3 Acceso de entrada sin salida para Diego Perez (u-new-6) -> Para Query 73
INSERT INTO accesos (id, usuario_id, credencial_id, tipo_acceso, metodo_validacion, fecha_hora, punto_acceso, validacion_membresia, validacion_reserva, estado) VALUES
('acc-new-601', 'u1651a66-72cb-4560-a299-fb82939e0f36', 'cr-new-6', 'ENTRADA', 'RFID', '2026-07-13 14:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO');

-- 9.4 Acceso fuera de horario para Felipe Diaz (u-new-8) -> Para Query 66 (accesos fuera de 8am-8pm)
INSERT INTO accesos (id, usuario_id, credencial_id, tipo_acceso, metodo_validacion, fecha_hora, punto_acceso, validacion_membresia, validacion_reserva, estado) VALUES
('acc-new-801', 'u1651a66-72cb-4560-a299-fb82939e0f38', 'cr-new-8', 'ENTRADA', 'RFID', '2026-07-13 07:30:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO');

-- 9.5 Acceso de entrada hoy para cumplir con Query 61 (accesos hoy)
INSERT INTO accesos (id, usuario_id, credencial_id, tipo_acceso, metodo_validacion, fecha_hora, punto_acceso, validacion_membresia, validacion_reserva, estado) VALUES
('acc-new-today-1', 'u1651a66-72cb-4560-a299-fb82939e0f31', 'cr-new-4', 'ENTRADA', 'RFID', '2026-07-13 10:00:00', 'Entrada Principal', 'ACTIVA', 'SIN_RESERVA', 'PERMITIDO');

-- 10. Intentos de acceso rechazados con código QR inválido (Para cumplir con Query 77)
INSERT INTO intentos_acceso_rechazados (id, usuario_id, credencial_id, codigo_intentado, metodo_validacion, fecha_hora, punto_acceso, motivo_rechazo, descripcion_detallada, estado) VALUES
('iar-new-1', NULL, NULL, 'QR-INVALID-999', 'QR', '2026-07-10 09:20:00', 'Entrada Principal', 'CREDENCIAL_INVALIDA', 'Código QR no reconocido en la base de datos', 'REGISTRADO');
