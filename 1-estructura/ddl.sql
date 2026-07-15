-- ============================================================================
-- BASE DE DATOS: COWORKING
-- Descripción: Sistema de gestión para espacios de coworking
-- ============================================================================

DROP DATABASE IF EXISTS coworking; -- Elimina la BD si ya existe para evitar conflictos
CREATE DATABASE coworking -- Crea la base de datos principal del sistema
  CHARACTER SET utf8mb4 -- Codificación que soporta caracteres especiales y emojis
  COLLATE utf8mb4_unicode_ci; -- Collation para ordenamiento correcto en múltiples idiomas
USE coworking; -- Selecciona la base de datos para ejecutar las siguientes sentencias

-- ============================================================================
-- Tabla: empresas --
-- Descripción: Almacena información de las empresas clientas del coworking
-- ============================================================================
CREATE TABLE IF NOT EXISTS empresas( -- Tabla: empresas --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único generado automáticamente con UUID
	nombre VARCHAR(150) NOT NULL, -- Nombre comercial de la empresa
	razon_social VARCHAR(200) NOT NULL, -- Razón social legal de la empresa
	rfc_nit VARCHAR(20) UNIQUE NOT NULL, -- RFC (México) o NIT (Colombia) - Identificación fiscal única
	email_contacto VARCHAR(150), -- Correo electrónico de contacto principal
	telefono VARCHAR(15), -- Número telefónico de contacto
	direccion VARCHAR(255), -- Dirección física de la empresa
	persona_contacto VARCHAR(150), -- Nombre de la persona de contacto en la empresa
	fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP, -- Fecha y hora de registro en el sistema
	estado ENUM('ACTIVA','INACTIVA') DEFAULT 'ACTIVA' -- Estado actual de la empresa en el sistema
);

-- ============================================================================
-- Tabla: usuario --
-- Descripción: Almacena información de los usuarios del sistema (miembros, empleados, etc.)
-- ============================================================================
CREATE TABLE IF NOT EXISTS usuario( -- Tabla: usuario --
	id VARCHAR (36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del usuario
	identificacion VARCHAR(30) UNIQUE NOT NULL, -- Documento de identidad (DNI, CC, INE, etc.)
	nombre VARCHAR(80) NOT NULL, -- Nombre(s) del usuario
	apellidos VARCHAR(100) NOT NULL, -- Apellidos del usuario
	fecha_nacimiento DATE, -- Fecha de nacimiento para control de edad y cumpleaños
	email VARCHAR(150) UNIQUE NOT NULL, -- Correo electrónico único para login y notificaciones
	telefono VARCHAR(15), -- Número telefónico para contacto y notificaciones
	direccion VARCHAR(255), -- Dirección física del usuario
	empresa_id VARCHAR(36), -- FOREIGN KEY - Empresa a la que pertenece el usuario (si aplica)
	estado ENUM('ACTIVO','INACTIVO','BLOQUEADO') DEFAULT 'ACTIVO', -- Estado actual de la cuenta del usuario
	FOREIGN KEY (empresa_id) REFERENCES empresas(id) -- Relación con la tabla de empresas
);

-- ============================================================================
-- Tabla: tipos_membresia --
-- Descripción: Define los diferentes planes de membresía disponibles en el coworking
-- ============================================================================
CREATE TABLE IF NOT EXISTS tipos_membresia( -- Tabla: tipos_membresia --
	id VARCHAR (36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del tipo de membresía
	nombre VARCHAR(50) UNIQUE NOT NULL, -- Nombre del plan (ej: Básico, Premium, Enterprise)
	descripcion TEXT, -- Descripción detallada de los beneficios del plan
	duracion_dias INT NOT NULL, -- Duración del plan en días (30, 90, 365, etc.)
	precio_base DECIMAL (10,2) NOT NULL, -- Precio base del plan en moneda local
	limite_horas_mes INT, -- Horas mensuales de uso de espacios incluidas en el plan
	acceso_sala_evento BOOLEAN DEFAULT FALSE, -- Indica si incluye acceso a salas de eventos
	acceso_sala_reuniones BOOLEAN DEFAULT FALSE, -- Indica si incluye acceso a salas de reuniones
	servicio_incluidos JSON, -- Lista de servicios incluidos en formato JSON flexible
	estado ENUM('ACTIVO','INACTIVO') DEFAULT 'ACTIVO' -- Estado del plan (disponible o no para contratación)
);

-- ============================================================================
-- Tabla: membresia_usuario --
-- Descripción: Registra las membresías activas/históricas contratadas por cada usuario
-- ============================================================================
CREATE TABLE IF NOT EXISTS membresia_usuario( -- Tabla: membresia_usuario --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único de la membresía contratada
	usuario_id VARCHAR(36), -- FOREIGN KEY - Usuario que contrató la membresía
	tipo_membresia_id VARCHAR(36),-- FOREIGN KEY - Tipo de membresía contratada
	fecha_inicio DATE NOT NULL, -- Fecha de inicio de vigencia de la membresía
	fecha_fin DATE NOT NULL, -- Fecha de vencimiento de la membresía
	fecha_contratacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora en que se contrató
	estado ENUM('ACTIVA','SUSPENDIDA','VENCIDA','CANCELADA') DEFAULT 'ACTIVA', -- Estado actual de la membresía
	fecha_suspension DATETIME, -- Fecha en que se suspendió la membresía (si aplica)
	motivo_suspension VARCHAR(255), -- Razón de la suspensión de la membresía
	renovaciones INT DEFAULT 0, -- Número de veces que se ha renovado la membresía
	precio_pagado DECIMAL(10,2), -- Precio efectivamente pagado por la membresía
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario
	FOREIGN KEY (tipo_membresia_id) REFERENCES tipos_membresia(id) -- Relación con el tipo de membresía
);

-- Índice: idx_usuario_estado --
CREATE INDEX idx_usuario_estado ON usuario(estado); -- Índice: idx_usuario_estado -- Optimiza búsquedas por estado del usuario

-- Índice: idx_fecha_fin --
CREATE INDEX idx_fecha_fin ON membresia_usuario(fecha_fin); -- Índice: idx_fecha_fin -- Optimiza búsquedas de membresías por fecha de vencimiento

-- ============================================================================
-- Tabla: historial_cambio_membresia --
-- Descripción: Auditoría de cambios realizados a las membresías de los usuarios
-- ============================================================================
CREATE TABLE IF NOT EXISTS historial_cambio_membresia( -- Tabla: historial_cambio_membresia --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del registro de cambio
	membresia_usuario_id VARCHAR(36),-- FOREIGN KEY - Membresía afectada por el cambio
	usuario_id VARCHAR(36), -- FOREIGN KEY - Usuario dueño de la membresía
	tipo_anterior_id VARCHAR(36), -- FOREIGN KEY - Tipo de membresía antes del cambio
	tipo_nuevo_id VARCHAR(36), -- FOREIGN KEY - Tipo de membresía después del cambio
	usuario_modifico VARCHAR(36), -- FOREIGN KEY - Usuario (admin) que realizó el cambio
	fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora en que se realizó el cambio
	motivo VARCHAR(255), -- Razón o justificación del cambio de membresía
	FOREIGN KEY (membresia_usuario_id) REFERENCES membresia_usuario(id), -- Relación con la membresía
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario dueño
	FOREIGN KEY (tipo_anterior_id) REFERENCES tipos_membresia(id), -- Relación con el tipo anterior
	FOREIGN KEY (tipo_nuevo_id) REFERENCES tipos_membresia(id), -- Relación con el tipo nuevo
	FOREIGN KEY (usuario_modifico) REFERENCES usuario(id) -- Relación con el usuario que modificó
);

-- ============================================================================
-- Tabla: tipos_espacios --
-- Descripción: Catálogo de tipos de espacios disponibles en el coworking
-- ============================================================================
CREATE TABLE IF NOT EXISTS tipos_espacios( -- Tabla: tipos_espacios --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del tipo de espacio
	nombre VARCHAR(50) UNIQUE NOT NULL, -- Nombre del tipo (ej: Oficina Privada, Hot Desk, Sala de Reuniones)
	descripcion TEXT, -- Descripción detallada del tipo de espacio
	tarifa_base_hora DECIMAL (10,2) NOT NULL, -- Tarifa por hora de uso del espacio
	tarifa_base_dia DECIMAL (10,2), -- Tarifa por día completo de uso del espacio
	capacidad_minima INT DEFAULT 1, -- Capacidad mínima de personas que puede albergar
	capacidad_maxima INT NOT NULL, -- Capacidad máxima de personas que puede albergar
	equipamiento_incluido JSON, -- Lista de equipamiento incluido en formato JSON
	estado ENUM ('ACTIVO','INACTIVO') DEFAULT 'ACTIVO' -- Estado del tipo de espacio
);

-- ============================================================================
-- Tabla: espacios --
-- Descripción: Espacios físicos específicos disponibles para reserva en el coworking
-- ============================================================================
CREATE TABLE IF NOT EXISTS espacios ( -- Tabla: espacios --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del espacio físico
	codigo VARCHAR(20) UNIQUE NOT NULL, -- Código interno del espacio (ej: OF-101, HR-201)
	nombre VARCHAR (100) NOT NULL, -- Nombre descriptivo del espacio
	tipo_espacio_id VARCHAR(36),-- FOREIGN KEY - Tipo al que pertenece el espacio
	piso INT NOT NULL, -- Número de piso donde se ubica el espacio
	ubicacion VARCHAR(100), -- Ubicación específica dentro del piso
	capacidad INT NOT NULL, -- Número máximo de personas que caben en el espacio
	tamano_m2 DECIMAL(10,2), -- Tamaño del espacio en metros cuadrados
	hora_apertura TIME DEFAULT '8:00:00', -- Hora de apertura del espacio
	hora_cierre TIME DEFAULT '20:00:00', -- Hora de cierre del espacio
	dias_disponibles INT DEFAULT 1, -- 1=LUNES, 2=MARTES, 3=MIERCOLES... Días disponibles (puede ser bitmask)
	tiene_vista_exterior BOOLEAN DEFAULT FALSE, -- Indica si el espacio tiene vista al exterior
	equipamiento_extra JSON, -- Equipamiento adicional específico del espacio
	precio_personalizado DECIMAL(10,2), -- Precio personalizado (si difiere del tipo base)
	estado ENUM('DISPONIBLE','MANTENIMIENTO', 'FUERA DE SERVICIO'), -- Estado operativo actual del espacio
	FOREIGN KEY (tipo_espacio_id) REFERENCES tipos_espacios(id) -- Relación con el tipo de espacio
);

-- Índice: idx_tipo_estado --
CREATE INDEX idx_tipo_estado ON tipos_espacios(estado); -- Índice: idx_tipo_estado -- Optimiza búsquedas de tipos por estado

-- Índice: idx_piso --
CREATE INDEX idx_piso ON espacios(piso); -- Índice: idx_piso -- Optimiza búsquedas de espacios por piso

-- ============================================================================
-- Tabla: reservas --
-- Descripción: Registra las reservas de espacios realizadas por los usuarios
-- ============================================================================
CREATE TABLE IF NOT EXISTS reservas ( -- Tabla: reservas --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único de la reserva
	codigo VARCHAR(30) UNIQUE NOT NULL, -- Código único de la reserva (ej: RES-2026-001)
	usuario_id VARCHAR(36), -- FOREIGN KEY - Usuario que realizó la reserva
	espacio_id VARCHAR(36), -- FOREIGN KEY - Espacio reservado
	reserva_padre_id VARCHAR(36), -- FOREIGN KEY - Reserva padre (para reservas recurrentes)
	fecha_reserva DATE NOT NULL, -- Fecha para la cual se reservó el espacio
	hora_inicio TIME NOT NULL, -- Hora de inicio de la reserva
	hora_fin TIME NOT NULL, -- Hora de fin de la reserva
	duracion_horas DECIMAL(5,2), -- Duración total de la reserva en horas
	numero_asistentes INT NOT NULL, -- Número de personas que asistirán
	motivo VARCHAR(255), -- Motivo o propósito de la reserva
	estado ENUM('PENDIENTE','CONFIRMADA','CANCELADA','NOSHOW','COMPLETADA') DEFAULT 'PENDIENTE', -- Estado actual de la reserva
	precio_total DECIMAL(10,2) NOT NULL, -- Precio total antes de descuentos
	descuento_aplicado DECIMAL(10,2) DEFAULT 0, -- Descuento aplicado a la reserva
	precio_final DECIMAL (10,2) NOT NULL, -- Precio final después de descuentos
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación de la reserva
	fecha_confirmacion DATETIME, -- Fecha y hora en que se confirmó la reserva
	fecha_cancelacion DATETIME, -- Fecha y hora en que se canceló la reserva
	motivo_cancelacion VARCHAR(255), -- Razón de la cancelación
	es_recurrente BOOLEAN DEFAULT FALSE, -- Indica si la reserva es recurrente (diaria, semanal, etc.)
	notas TEXT, -- Notas adicionales sobre la reserva
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario
	FOREIGN KEY (espacio_id) REFERENCES espacios(id), -- Relación con el espacio
	FOREIGN KEY (reserva_padre_id) REFERENCES reservas(id) -- clave foránea autoreferenciada - Para reservas recurrentes
);

-- ============================================================================
-- Tabla: reservas_clientes --
-- Descripción: Registra los asistentes (clientes) confirmados para cada reserva
-- ============================================================================
CREATE TABLE IF NOT EXISTS reservas_clientes( -- Tabla: reservas_clientes --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del registro de asistencia
	reserva_id VARCHAR(36), -- FOREIGN KEY - Reserva a la que asiste el cliente
	usuario_id VARCHAR(36), -- FOREIGN KEY - Usuario/invitado que asistirá
	fecha_confirmacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de confirmación de asistencia
	asistio BOOLEAN DEFAULT FALSE, -- Indica si el invitado realmente asistió
	FOREIGN KEY (reserva_id) REFERENCES reservas(id), -- Relación con la reserva
	FOREIGN KEY (usuario_id) REFERENCES usuario(id) -- Relación con el usuario invitado
);

-- Índice: idx_usuario --
CREATE INDEX idx_usuario ON reservas_clientes(usuario_id); -- Índice: idx_usuario -- Optimiza búsquedas de reservas por usuario

-- Índice: idx_reserva --
CREATE INDEX idx_reserva ON reservas_clientes(reserva_id); -- Índice: idx_reserva -- Optimiza búsquedas de asistentes por reserva

-- ============================================================================
-- Tabla: servicios_adicionales --
-- Descripción: Catálogo de servicios adicionales disponibles en el coworking
-- ============================================================================
CREATE TABLE IF NOT EXISTS servicios_adicionales( -- Tabla: servicios_adicionales --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del servicio
	codigo VARCHAR(20) UNIQUE NOT NULL, -- Código interno del servicio
	nombre VARCHAR(100) UNIQUE NOT NULL, -- Nombre del servicio adicional
	descripcion TEXT, -- Descripción detallada del servicio
	categorias ENUM('CONECTIVIDAD','ALMACENAMIENTO','ALIMENTOS','IMPRESION','EQUIPAMIENTO','OTROS') NOT NULL, -- Categoría del servicio
	unidad_cobro ENUM('POR USO','POR HORA','POR DIA','POR MES', 'FIJO') NOT NULL, -- Forma en que se cobra el servicio
	precio_unitario DECIMAL(10,2) NOT NULL, -- Precio unitario del servicio
	impuesto_aplicable DECIMAL(5,2) DEFAULT 0.00, -- Porcentaje de impuesto aplicable
	disponibilidad_limitada BOOLEAN DEFAULT FALSE, -- Indica si el servicio tiene stock limitado
	stock_disponible INT, -- Cantidad disponible si tiene stock limitado
	tiempo_estimado_uso INT, -- Tiempo estimado de uso en minutos
	requiere_reserva BOOLEAN DEFAULT FALSE, -- Indica si el servicio requiere reserva previa
	incluido_en_membresia JSON, -- Membresías que incluyen este servicio en formato JSON
	imagen_url VARCHAR(400), -- URL de la imagen del servicio
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del registro
	estado ENUM('ACTIVO','INACTIVO','AGOTADO') DEFAULT 'ACTIVO' -- Estado actual del servicio
);

-- Índice: idx_categoria_estado --
CREATE INDEX idx_categoria_estado ON servicios_adicionales(categorias,estado); -- Índice: idx_categoria_estado -- Optimiza búsquedas por categoría y estado

-- Índice: idx_disponibilidad --
CREATE INDEX idx_disponibilidad ON servicios_adicionales(disponibilidad_limitada,stock_disponible); -- Índice: idx_disponibilidad -- Optimiza búsquedas de disponibilidad de stock

-- ============================================================================
-- Tabla: servicios_contratados --
-- Descripción: Registra los servicios adicionales contratados por los usuarios
-- ============================================================================
CREATE TABLE IF NOT EXISTS servicios_contratados( -- Tabla: servicios_contratados --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del servicio contratado
	codigo VARCHAR(30) UNIQUE NOT NULL, -- Código único del servicio contratado
	usuario_id VARCHAR(36), -- FOREIGN KEY - Usuario que contrató el servicio
	servicio_id VARCHAR(36), -- FOREIGN KEY - Servicio adicional contratado
	reserva_id VARCHAR(36), -- FOREIGN KEY - Reserva asociada (si aplica)
	fecha_contratacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de contratación
	fecha_uso DATE NOT NULL, -- Fecha en que se usará o usó el servicio
	hora_inicio TIME, -- Hora de inicio del uso del servicio
	hora_fin TIME, -- Hora de fin del uso del servicio
	cantidad DECIMAL(8,2) NOT NULL, -- Cantidad contratada del servicio
	unidad_cobro ENUM('POR USO','POR HORA','POR DIA','POR MES','FIJO') NOT NULL, -- Unidad de cobro aplicada
	precio_unitario DECIMAL(10,2) NOT NULL, -- Precio unitario al momento de contratar
	subtotal DECIMAL(10,2) NOT NULL, -- Subtotal antes de impuestos y descuentos
	impuesto DECIMAL(10,2) DEFAULT 0.00, -- Monto de impuesto aplicado
	descuento DECIMAL(10,2) DEFAULT 0.00, -- Monto de descuento aplicado
	total DECIMAL(10,2) NOT NULL, -- Total a pagar por el servicio
	estado ENUM('PENDIENTE','ACTIVO','USADO','CANCELADO','FACTURADO') DEFAULT 'PENDIENTE', -- Estado del servicio contratado
	metodo_entrega VARCHAR(100), -- Método de entrega o acceso al servicio
	notas TEXT, -- Notas adicionales sobre el servicio
	fecha_cancelacion DATETIME, -- Fecha y hora de cancelación (si aplica)
	motivo_cancelacion VARCHAR(255), -- Razón de la cancelación
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario
	FOREIGN KEY (servicio_id) REFERENCES servicios_adicionales(id), -- Relación con el servicio
	FOREIGN KEY (reserva_id) REFERENCES reservas(id) ON DELETE SET NULL -- Relación con la reserva (se mantiene si se elimina la reserva)
);

-- Índice: idx_usuario_estado --
CREATE INDEX idx_usuario_estado ON servicios_contratados(usuario_id, estado); -- Índice: idx_usuario_estado -- Optimiza búsquedas por usuario y estado

-- Índice: idx_servicio_fecha --
CREATE INDEX idx_servicio_fecha ON servicios_contratados(servicio_id, fecha_uso); -- Índice: idx_servicio_fecha -- Optimiza búsquedas por servicio y fecha de uso

-- Índice: idx_reserva --
CREATE INDEX idx_reserva ON servicios_contratados(reserva_id); -- Índice: idx_reserva -- Optimiza búsquedas por reserva asociada

-- Índice: idx_fecha_uso --
CREATE INDEX idx_fecha_uso ON servicios_contratados(fecha_uso); -- Índice: idx_fecha_uso -- Optimiza búsquedas por fecha de uso

-- Índice: idx_estado --
CREATE INDEX idx_estado ON servicios_contratados(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado del servicio

-- ============================================================================
-- Tabla: metodos_pago --
-- Descripción: Catálogo de métodos de pago aceptados en el coworking
-- ============================================================================
CREATE TABLE IF NOT EXISTS metodos_pago( -- Tabla: metodos_pago --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del método de pago
	codigo VARCHAR(20) UNIQUE NOT NULL, -- Código interno del método de pago
	nombre VARCHAR(50) UNIQUE NOT NULL, -- Nombre del método (ej: Tarjeta de Crédito, PayPal, Transferencia)
	descripcion TEXT, -- Descripción del método de pago
	comision_porcentual DECIMAL(5,2) DEFAULT 0.00, -- Comisión porcentual que cobra el método
	costo_fijo DECIMAL(10,2) DEFAULT 0.00, -- Costo fijo por transacción del método
	requiere_verificacion BOOLEAN DEFAULT FALSE, -- Indica si requiere verificación adicional
	limite_diario DECIMAL(12,2), -- Límite diario de transacciones permitido
	imagen_url VARCHAR(400), -- URL del logo/imagen del método de pago
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del registro
	estado ENUM('ACTIVO','INACTIVO') DEFAULT 'ACTIVO' -- Estado del método de pago
);

-- Índice: idx_estado --
CREATE INDEX idx_estado ON metodos_pago(estado); -- Índice: idx_estado -- Optimiza búsquedas de métodos por estado

-- ============================================================================
-- Tabla: facturas --
-- Descripción: Registra las facturas emitidas a los usuarios del coworking
-- ============================================================================
CREATE TABLE IF NOT EXISTS facturas( -- Tabla: facturas --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único de la factura
	numero_factura VARCHAR(30) UNIQUE NOT NULL, -- Número de factura único (ej: FAC-2026-0001)
	usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Usuario al que se emite la factura
	empresa_id VARCHAR(36), -- FOREIGN KEY (si es facturación corporativa) - Empresa para facturación
	tipo_factura ENUM('MEMBRESIA','RESERVA','SERVICIO','CONSOLIDADA') NOT NULL, -- Tipo de factura según el concepto
	fecha_emision DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de emisión de la factura
	fecha_vencimiento DATE NOT NULL, -- Fecha límite de pago de la factura
	subtotal DECIMAL(12,2) NOT NULL, -- Subtotal antes de impuestos y descuentos
	impuesto DECIMAL(12,2) DEFAULT 0.00, -- Monto total de impuestos aplicados
	descuento DECIMAL(12,2) DEFAULT 0.00, -- Monto total de descuentos aplicados
	total DECIMAL(12,2) NOT NULL, -- Total a pagar de la factura
	saldo_pendiente DECIMAL(12,2) NOT NULL, -- Saldo pendiente de pago
	estado ENUM('PENDIENTE','PAGADA','PARCIAL','VENCIDA','ANULADA') DEFAULT 'PENDIENTE', -- Estado de pago de la factura
	motivo_anulacion VARCHAR(255), -- Razón de la anulación (si aplica)
	fecha_anulacion DATETIME, -- Fecha y hora de anulación
	usuario_anulo VARCHAR(36), -- FOREIGN KEY - Usuario que anuló la factura
	observaciones TEXT, -- Observaciones o notas adicionales de la factura
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del registro
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario facturado
	FOREIGN KEY (empresa_id) REFERENCES empresas(id), -- Relación con la empresa (facturación corporativa)
	FOREIGN KEY (usuario_anulo) REFERENCES usuario(id) -- Relación con el usuario que anuló
);

-- Índice: idx_usuario_estado --
CREATE INDEX idx_usuario_estado ON facturas(usuario_id, estado); -- Índice: idx_usuario_estado -- Optimiza búsquedas de facturas por usuario y estado

-- Índice: idx_numero --
CREATE INDEX idx_numero ON facturas(numero_factura); -- Índice: idx_numero -- Optimiza búsquedas por número de factura

-- Índice: idx_fecha_vencimiento --
CREATE INDEX idx_fecha_vencimiento ON facturas(fecha_vencimiento); -- Índice: idx_fecha_vencimiento -- Optimiza búsquedas por fecha de vencimiento

-- Índice: idx_tipo --
CREATE INDEX idx_tipo ON facturas(tipo_factura); -- Índice: idx_tipo -- Optimiza búsquedas por tipo de factura

-- Índice: idx_empresa --
CREATE INDEX idx_empresa ON facturas(empresa_id); -- Índice: idx_empresa -- Optimiza búsquedas por empresa

-- ============================================================================
-- Tabla: detalle_factura --
-- Descripción: Detalle de conceptos incluidos en cada factura emitida
-- ============================================================================
CREATE TABLE IF NOT EXISTS detalle_factura( -- Tabla: detalle_factura --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del detalle
	factura_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Factura a la que pertenece el detalle
	concepto VARCHAR(200) NOT NULL, -- Descripción del concepto facturado
	cantidad DECIMAL(8,2) NOT NULL, -- Cantidad del concepto
	precio_unitario DECIMAL(10,2) NOT NULL, -- Precio unitario del concepto
	subtotal DECIMAL(12,2) NOT NULL, -- Subtotal del concepto (cantidad * precio)
	impuesto DECIMAL(12,2) DEFAULT 0.00, -- Impuesto aplicado al concepto
	descuento DECIMAL(12,2) DEFAULT 0.00, -- Descuento aplicado al concepto
	total DECIMAL(12,2) NOT NULL, -- Total del concepto
	referencia_tipo ENUM('MEMBRESIA','RESERVA','SERVICIO','RECARGO','OTRO'), -- Tipo de referencia asociada
	referencia_id VARCHAR(36), -- ID de la membresía, reserva o servicio asociado
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del detalle
	FOREIGN KEY (factura_id) REFERENCES facturas(id) ON DELETE CASCADE -- Relación con la factura (se elimina si se elimina la factura)
);

-- Índice: idx_factura --
CREATE INDEX idx_factura ON detalle_factura(factura_id); -- Índice: idx_factura -- Optimiza búsquedas de detalles por factura

-- Índice: idx_referencia --
CREATE INDEX idx_referencia ON detalle_factura(referencia_tipo, referencia_id); -- Índice: idx_referencia -- Optimiza búsquedas por tipo y ID de referencia

-- ============================================================================
-- Tabla: pagos --
-- Descripción: Registra los pagos realizados por los usuarios contra sus facturas
-- ============================================================================
CREATE TABLE IF NOT EXISTS pagos( -- Tabla: pagos --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del pago
	codigo_pago VARCHAR(30) UNIQUE NOT NULL, -- Código único del pago (ej: PAG-2026-0001)
	factura_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Factura que se está pagando
	usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Usuario que realiza el pago
	metodo_pago_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Método de pago utilizado
	usuario_registra VARCHAR(36), -- FOREIGN KEY (cajero/recepcionista) - Usuario que registró el pago
	monto DECIMAL(12,2) NOT NULL, -- Monto total del pago
	comision DECIMAL(10,2) DEFAULT 0.00, -- Comisión cobrada por el método de pago
	monto_neto DECIMAL(12,2) NOT NULL, -- Monto neto recibido (monto - comisión)
	moneda ENUM('USD','EUR','MXN','COP') DEFAULT 'USD', -- Moneda en que se realizó el pago
	referencia_externa VARCHAR(100), -- Número de transacción de PayPal, tarjeta, etc.
	fecha_pago DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora en que se realizó el pago
	estado ENUM('PAGADO','PENDIENTE','CANCELADO','RECHAZADO','REEMBOLSADO') DEFAULT 'PENDIENTE', -- Estado actual del pago
	es_parcial BOOLEAN DEFAULT FALSE, -- Indica si es un pago parcial de la factura
	motivo_cancelacion VARCHAR(255), -- Razón de cancelación del pago
	fecha_cancelacion DATETIME, -- Fecha y hora de cancelación
	notas TEXT, -- Notas adicionales sobre el pago
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del registro
	FOREIGN KEY (factura_id) REFERENCES facturas(id), -- Relación con la factura
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario que paga
	FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago(id), -- Relación con el método de pago
	FOREIGN KEY (usuario_registra) REFERENCES usuario(id) -- Relación con el usuario que registró
);

-- Índice: idx_factura --
CREATE INDEX idx_factura ON pagos(factura_id); -- Índice: idx_factura -- Optimiza búsquedas de pagos por factura

-- Índice: idx_usuario_estado --
CREATE INDEX idx_usuario_estado ON pagos(usuario_id, estado); -- Índice: idx_usuario_estado -- Optimiza búsquedas por usuario y estado

-- Índice: idx_metodo --
CREATE INDEX idx_metodo ON pagos(metodo_pago_id); -- Índice: idx_metodo -- Optimiza búsquedas por método de pago

-- Índice: idx_fecha_pago --
CREATE INDEX idx_fecha_pago ON pagos(fecha_pago); -- Índice: idx_fecha_pago -- Optimiza búsquedas por fecha de pago

-- Índice: idx_codigo --
CREATE INDEX idx_codigo ON pagos(codigo_pago); -- Índice: idx_codigo -- Optimiza búsquedas por código de pago

-- Índice: idx_estado --
CREATE INDEX idx_estado ON pagos(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado del pago

-- ============================================================================
-- Tabla: recargos --
-- Descripción: Registra los recargos aplicados a las facturas (moratorios, administrativos, etc.)
-- ============================================================================
CREATE TABLE IF NOT EXISTS recargos( -- Tabla: recargos --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del recargo
	factura_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Factura a la que se aplica el recargo
	usuario_aplico VARCHAR(36), -- FOREIGN KEY - Usuario que aplicó el recargo
	tipo_recargo ENUM('MORATORIO','ADMINISTRATIVO','POR_SERVICIO') NOT NULL, -- Tipo de recargo aplicado
	porcentaje DECIMAL(5,2), -- Porcentaje aplicado (para recargos moratorios)
	monto_fijo DECIMAL(10,2), -- Monto fijo del recargo
	monto_calculado DECIMAL(10,2) NOT NULL, -- Monto total calculado del recargo
	dias_mora INT DEFAULT 0, -- Días de mora (para recargos moratorios)
	fecha_aplicacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de aplicación del recargo
	descripcion VARCHAR(255), -- Descripción detallada del recargo
	estado ENUM('APLICADO','ANULADO') DEFAULT 'APLICADO', -- Estado actual del recargo
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del registro
	FOREIGN KEY (factura_id) REFERENCES facturas(id), -- Relación con la factura
	FOREIGN KEY (usuario_aplico) REFERENCES usuario(id) -- Relación con el usuario que aplicó
);

-- Índice: idx_factura --
CREATE INDEX idx_factura ON recargos(factura_id); -- Índice: idx_factura -- Optimiza búsquedas de recargos por factura

-- Índice: idx_tipo --
CREATE INDEX idx_tipo ON recargos(tipo_recargo); -- Índice: idx_tipo -- Optimiza búsquedas por tipo de recargo

-- Índice: idx_estado --
CREATE INDEX idx_estado ON recargos(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado del recargo

-- Índice: idx_fecha --
CREATE INDEX idx_fecha ON recargos(fecha_aplicacion); -- Índice: idx_fecha -- Optimiza búsquedas por fecha de aplicación

-- ============================================================================
-- Tabla: credenciales_acceso --
-- Descripción: Gestiona las credenciales de acceso (RFID, QR, biométricas) de los usuarios
-- ============================================================================
CREATE TABLE IF NOT EXISTS credenciales_acceso( -- Tabla: credenciales_acceso --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único de la credencial
	usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Usuario propietario de la credencial
	tipo_credencial ENUM('RFID','QR','BIOMETRICO','TEMPORAL') NOT NULL, -- Tipo de credencial de acceso
	codigo VARCHAR(100) UNIQUE NOT NULL, -- Código único de la credencial (UID, hash, etc.)
	descripcion VARCHAR(255), -- Descripción o etiqueta de la credencial
	fecha_asignacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de asignación
	fecha_vencimiento DATETIME, -- Fecha de vencimiento de la credencial
	fecha_revocacion DATETIME, -- Fecha en que se revocó la credencial
	motivo_revocacion VARCHAR(255), -- Razón de la revocación
	estado ENUM('ACTIVA','REVOCADA','VENCIDA','PERDIDA','REEMPLAZADA') DEFAULT 'ACTIVA', -- Estado actual de la credencial
	intentos_fallidos INT DEFAULT 0, -- Número de intentos fallidos de uso
	fecha_ultimo_uso DATETIME, -- Fecha y hora del último uso exitoso
	notas TEXT, -- Notas adicionales sobre la credencial
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del registro
	FOREIGN KEY (usuario_id) REFERENCES usuario(id) -- Relación con el usuario
);

-- Índice: idx_usuario_estado --
CREATE INDEX idx_usuario_estado ON credenciales_acceso(usuario_id, estado); -- Índice: idx_usuario_estado -- Optimiza búsquedas por usuario y estado

-- Índice: idx_codigo --
CREATE INDEX idx_codigo ON credenciales_acceso(codigo); -- Índice: idx_codigo -- Optimiza búsquedas por código de credencial

-- Índice: idx_tipo_estado --
CREATE INDEX idx_tipo_estado ON credenciales_acceso(tipo_credencial, estado); -- Índice: idx_tipo_estado -- Optimiza búsquedas por tipo y estado

-- Índice: idx_vencimiento --
CREATE INDEX idx_vencimiento ON credenciales_acceso(fecha_vencimiento); -- Índice: idx_vencimiento -- Optimiza búsquedas por fecha de vencimiento

-- ============================================================================
-- Tabla: accesos --
-- Descripción: Registra los accesos físicos (entradas/salidas) de los usuarios al coworking
-- ============================================================================
CREATE TABLE IF NOT EXISTS accesos( -- Tabla: accesos --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del registro de acceso
	usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Usuario que accedió
	credencial_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Credencial utilizada para el acceso
	tipo_acceso ENUM('ENTRADA','SALIDA') NOT NULL, -- Tipo de acceso (entrada o salida)
	metodo_validacion ENUM('RFID','QR','BIOMETRICO','MANUAL','AUTOMATICO') NOT NULL, -- Método usado para validar el acceso
	fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora exacta del acceso
	punto_acceso VARCHAR(100), -- Punto de acceso físico (ej: Puerta Principal, Lobby)
	validacion_membresia ENUM('ACTIVA','VENCIDA','SUSPENDIDA','SIN_MEMBRESIA') NOT NULL, -- Estado de la membresía al momento del acceso
	validacion_reserva ENUM('CON_RESERVA','SIN_RESERVA','RESERVA_VENCIDA') DEFAULT 'SIN_RESERVA', -- Estado de la reserva al momento del acceso
	estado ENUM('PERMITIDO','RECHAZADO','PENDIENTE_VALIDACION') DEFAULT 'PERMITIDO', -- Resultado del acceso
	motivo_rechazo VARCHAR(255), -- Razón del rechazo (si aplica)
	temperatura_corporal DECIMAL(4,1), -- Temperatura corporal registrada (control sanitario)
	foto_url VARCHAR(400), -- URL de la foto capturada en el acceso
	notas TEXT, -- Notas adicionales sobre el acceso
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del registro
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario
	FOREIGN KEY (credencial_id) REFERENCES credenciales_acceso(id) -- Relación con la credencial
);

-- Índice: idx_usuario_fecha --
CREATE INDEX idx_usuario_fecha ON accesos(usuario_id, fecha_hora); -- Índice: idx_usuario_fecha -- Optimiza búsquedas por usuario y fecha

-- Índice: idx_fecha_hora --
CREATE INDEX idx_fecha_hora ON accesos(fecha_hora); -- Índice: idx_fecha_hora -- Optimiza búsquedas por fecha y hora

-- Índice: idx_tipo_acceso --
CREATE INDEX idx_tipo_acceso ON accesos(tipo_acceso); -- Índice: idx_tipo_acceso -- Optimiza búsquedas por tipo de acceso

-- Índice: idx_estado --
CREATE INDEX idx_estado ON accesos(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado del acceso

-- Índice: idx_credencial --
CREATE INDEX idx_credencial ON accesos(credencial_id); -- Índice: idx_credencial -- Optimiza búsquedas por credencial

-- Índice: idx_punto_acceso --
CREATE INDEX idx_punto_acceso ON accesos(punto_acceso); -- Índice: idx_punto_acceso -- Optimiza búsquedas por punto de acceso

-- Índice: idx_validacion --
CREATE INDEX idx_validacion ON accesos(validacion_membresia, validacion_reserva); -- Índice: idx_validacion -- Optimiza búsquedas por validación de membresía y reserva

-- ============================================================================
-- Tabla: intentos_acceso_rechazados --
-- Descripción: Auditoría de intentos de acceso rechazados al coworking
-- ============================================================================
CREATE TABLE IF NOT EXISTS intentos_acceso_rechazados( -- Tabla: intentos_acceso_rechazados --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del intento rechazado
	usuario_id VARCHAR(36), -- FOREIGN KEY - Usuario que intentó acceder (si se identificó)
	credencial_id VARCHAR(36), -- FOREIGN KEY - Credencial utilizada en el intento
	codigo_intentado VARCHAR(100), -- Código que se intentó usar (para análisis forense)
	metodo_validacion ENUM('RFID','QR','BIOMETRICO','MANUAL') NOT NULL, -- Método de validación intentado
	fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora del intento
	punto_acceso VARCHAR(100), -- Punto de acceso donde se intentó entrar
	motivo_rechazo ENUM('CREDENCIAL_INVALIDA','CREDENCIAL_REVOCADA','CREDENCIAL_VENCIDA','MEMBRESIA_VENCIDA','MEMBRESIA_SUSPENDIDA','SIN_MEMBRESIA','SIN_RESERVA','HORARIO_NO_PERMITIDO','ESPACIO_NO_DISPONIBLE','INTENTOS_EXCEDIDOS','SOSPECHA_FRAUDE','OTRO') NOT NULL, -- Razón específica del rechazo
	descripcion_detallada VARCHAR(500), -- Descripción detallada del incidente
	ip_origen VARCHAR(45), -- Dirección IP de origen (IPv4 o IPv6)
	dispositivo VARCHAR(100), -- Dispositivo utilizado en el intento
	foto_url VARCHAR(400), -- URL de la foto capturada del intento
	estado ENUM('REGISTRADO','REVISADO','FALSA_ALARMA','BLOQUEADO') DEFAULT 'REGISTRADO', -- Estado del análisis del intento
	notas TEXT, -- Notas de seguridad sobre el incidente
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del registro
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario (si se identificó)
	FOREIGN KEY (credencial_id) REFERENCES credenciales_acceso(id) -- Relación con la credencial
);

-- Índice: idx_usuario_fecha --
CREATE INDEX idx_usuario_fecha ON intentos_acceso_rechazados(usuario_id, fecha_hora); -- Índice: idx_usuario_fecha -- Optimiza búsquedas por usuario y fecha

-- Índice: idx_fecha_hora --
CREATE INDEX idx_fecha_hora ON intentos_acceso_rechazados(fecha_hora); -- Índice: idx_fecha_hora -- Optimiza búsquedas por fecha y hora

-- Índice: idx_motivo --
CREATE INDEX idx_motivo ON intentos_acceso_rechazados(motivo_rechazo); -- Índice: idx_motivo -- Optimiza búsquedas por motivo de rechazo

-- Índice: idx_codigo --
CREATE INDEX idx_codigo ON intentos_acceso_rechazados(codigo_intentado); -- Índice: idx_codigo -- Optimiza búsquedas por código intentado

-- Índice: idx_estado --
CREATE INDEX idx_estado ON intentos_acceso_rechazados(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado del intento

-- Índice: idx_punto_acceso --
CREATE INDEX idx_punto_acceso ON intentos_acceso_rechazados(punto_acceso); -- Índice: idx_punto_acceso -- Optimiza búsquedas por punto de acceso

-- ============================================================================
-- Tabla: log_membresias --
-- Descripción: Auditoría completa de cambios realizados a las membresías
-- ============================================================================
CREATE TABLE IF NOT EXISTS log_membresias( -- Tabla: log_membresias --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del registro de log
	membresia_usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Membresía afectada
	usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Usuario dueño de la membresía
	tipo_anterior_id VARCHAR(36), -- FOREIGN KEY - Tipo de membresía antes del cambio
	tipo_nuevo_id VARCHAR(36), -- FOREIGN KEY - Tipo de membresía después del cambio
	usuario_sistema_id VARCHAR(36), -- FOREIGN KEY - Usuario del sistema que realizó el cambio
	accion ENUM('CREADA','ACTIVADA','SUSPENDIDA','VENCIDA','CANCELADA','RENOVADA','CAMBIO_TIPO','CAMBIO_ESTADO') NOT NULL, -- Acción realizada sobre la membresía
	estado_anterior ENUM('ACTIVA','SUSPENDIDA','VENCIDA','CANCELADA'), -- Estado antes del cambio
	estado_nuevo ENUM('ACTIVA','SUSPENDIDA','VENCIDA','CANCELADA'), -- Estado después del cambio
	precio_anterior DECIMAL(10,2), -- Precio antes del cambio
	precio_nuevo DECIMAL(10,2), -- Precio después del cambio
	fecha_inicio_anterior DATE, -- Fecha de inicio antes del cambio
	fecha_inicio_nueva DATE, -- Fecha de inicio después del cambio
	fecha_fin_anterior DATE, -- Fecha de fin antes del cambio
	fecha_fin_nueva DATE, -- Fecha de fin después del cambio
	motivo VARCHAR(255), -- Motivo del cambio
	datos_adicionales JSON, -- Datos adicionales en formato JSON flexible
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora del registro del log
	FOREIGN KEY (membresia_usuario_id) REFERENCES membresia_usuario(id), -- Relación con la membresía
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario dueño
	FOREIGN KEY (tipo_anterior_id) REFERENCES tipos_membresia(id), -- Relación con el tipo anterior
	FOREIGN KEY (tipo_nuevo_id) REFERENCES tipos_membresia(id), -- Relación con el tipo nuevo
	FOREIGN KEY (usuario_sistema_id) REFERENCES usuario(id) -- Relación con el usuario que realizó el cambio
);

-- Índice: idx_membresia_fecha --
CREATE INDEX idx_membresia_fecha ON log_membresias(membresia_usuario_id, fecha_creacion); -- Índice: idx_membresia_fecha -- Optimiza búsquedas por membresía y fecha

-- Índice: idx_usuario_fecha --
CREATE INDEX idx_usuario_fecha ON log_membresias(usuario_id, fecha_creacion); -- Índice: idx_usuario_fecha -- Optimiza búsquedas por usuario y fecha

-- Índice: idx_accion --
CREATE INDEX idx_accion ON log_membresias(accion); -- Índice: idx_accion -- Optimiza búsquedas por tipo de acción

-- Índice: idx_fecha --
CREATE INDEX idx_fecha ON log_membresias(fecha_creacion); -- Índice: idx_fecha -- Optimiza búsquedas por fecha de creación

-- ============================================================================
-- Tabla: log_reservas --
-- Descripción: Auditoría completa de cambios realizados a las reservas
-- ============================================================================
CREATE TABLE IF NOT EXISTS log_reservas( -- Tabla: log_reservas --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del registro de log
	reserva_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Reserva afectada
	usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Usuario dueño de la reserva
	espacio_anterior_id VARCHAR(36), -- FOREIGN KEY - Espacio antes del cambio
	espacio_nuevo_id VARCHAR(36), -- FOREIGN KEY - Espacio después del cambio
	usuario_sistema_id VARCHAR(36), -- FOREIGN KEY (quien realizó el cambio) - Usuario que realizó el cambio
	accion ENUM('CREADA','CONFIRMADA','CANCELADA','NOSHOW','COMPLETADA','MODIFICADA','REPROGRAMADA') NOT NULL, -- Acción realizada sobre la reserva
	estado_anterior ENUM('PENDIENTE','CONFIRMADA','CANCELADA','NOSHOW','COMPLETADA'), -- Estado antes del cambio
	estado_nuevo ENUM('PENDIENTE','CONFIRMADA','CANCELADA','NOSHOW','COMPLETADA'), -- Estado después del cambio
	fecha_anterior DATE, -- Fecha antes del cambio
	fecha_nueva DATE, -- Fecha después del cambio
	hora_inicio_anterior TIME, -- Hora de inicio antes del cambio
	hora_inicio_nueva TIME, -- Hora de inicio después del cambio
	hora_fin_anterior TIME, -- Hora de fin antes del cambio
	hora_fin_nueva TIME, -- Hora de fin después del cambio
	precio_anterior DECIMAL(10,2), -- Precio antes del cambio
	precio_nuevo DECIMAL(10,2), -- Precio después del cambio
	motivo VARCHAR(255), -- Motivo del cambio
	datos_adicionales JSON, -- Datos adicionales en formato JSON flexible
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora del registro del log
	FOREIGN KEY (reserva_id) REFERENCES reservas(id), -- Relación con la reserva
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario
	FOREIGN KEY (espacio_anterior_id) REFERENCES espacios(id), -- Relación con el espacio anterior
	FOREIGN KEY (espacio_nuevo_id) REFERENCES espacios(id), -- Relación con el espacio nuevo
	FOREIGN KEY (usuario_sistema_id) REFERENCES usuario(id) -- Relación con el usuario que realizó el cambio
);

-- Índice: idx_reserva_fecha --
CREATE INDEX idx_reserva_fecha ON log_reservas(reserva_id, fecha_creacion); -- Índice: idx_reserva_fecha -- Optimiza búsquedas por reserva y fecha

-- Índice: idx_usuario_fecha --
CREATE INDEX idx_usuario_fecha ON log_reservas(usuario_id, fecha_creacion); -- Índice: idx_usuario_fecha -- Optimiza búsquedas por usuario y fecha

-- Índice: idx_accion --
CREATE INDEX idx_accion ON log_reservas(accion); -- Índice: idx_accion -- Optimiza búsquedas por tipo de acción

-- Índice: idx_fecha --
CREATE INDEX idx_fecha ON log_reservas(fecha_creacion); -- Índice: idx_fecha -- Optimiza búsquedas por fecha de creación

-- Índice: idx_estado --
CREATE INDEX idx_estado ON log_reservas(estado_nuevo); -- Índice: idx_estado -- Optimiza búsquedas por estado nuevo

-- ============================================================================
-- Tabla: log_pagos --
-- Descripción: Auditoría completa de cambios realizados a los pagos
-- ============================================================================
CREATE TABLE IF NOT EXISTS log_pagos( -- Tabla: log_pagos --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del registro de log
	pago_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Pago afectado
	factura_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Factura asociada al pago
	usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Usuario que realizó el pago
	usuario_sistema_id VARCHAR(36), -- FOREIGN KEY - Usuario del sistema que registró el cambio
	metodo_pago_anterior_id VARCHAR(36), -- FOREIGN KEY - Método de pago antes del cambio
	metodo_pago_nuevo_id VARCHAR(36), -- FOREIGN KEY - Método de pago después del cambio
	accion ENUM('CREADO','CONFIRMADO','CANCELADO','RECHAZADO','REEMBOLSADO','MODIFICADO') NOT NULL, -- Acción realizada sobre el pago
	estado_anterior ENUM('PAGADO','PENDIENTE','CANCELADO','RECHAZADO','REEMBOLSADO'), -- Estado antes del cambio
	estado_nuevo ENUM('PAGADO','PENDIENTE','CANCELADO','RECHAZADO','REEMBOLSADO'), -- Estado después del cambio
	monto_anterior DECIMAL(12,2), -- Monto antes del cambio
	monto_nuevo DECIMAL(12,2), -- Monto después del cambio
	motivo VARCHAR(255), -- Motivo del cambio
	datos_adicionales JSON, -- Datos adicionales en formato JSON flexible
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora del registro del log
	FOREIGN KEY (pago_id) REFERENCES pagos(id), -- Relación con el pago
	FOREIGN KEY (factura_id) REFERENCES facturas(id), -- Relación con la factura
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario
	FOREIGN KEY (metodo_pago_anterior_id) REFERENCES metodos_pago(id), -- Relación con el método anterior
	FOREIGN KEY (metodo_pago_nuevo_id) REFERENCES metodos_pago(id), -- Relación con el método nuevo
	FOREIGN KEY (usuario_sistema_id) REFERENCES usuario(id) -- Relación con el usuario que realizó el cambio
);

-- Índice: idx_pago_fecha --
CREATE INDEX idx_pago_fecha ON log_pagos(pago_id, fecha_creacion); -- Índice: idx_pago_fecha -- Optimiza búsquedas por pago y fecha

-- Índice: idx_factura_fecha --
CREATE INDEX idx_factura_fecha ON log_pagos(factura_id, fecha_creacion); -- Índice: idx_factura_fecha -- Optimiza búsquedas por factura y fecha

-- Índice: idx_usuario_fecha --
CREATE INDEX idx_usuario_fecha ON log_pagos(usuario_id, fecha_creacion); -- Índice: idx_usuario_fecha -- Optimiza búsquedas por usuario y fecha

-- Índice: idx_accion --
CREATE INDEX idx_accion ON log_pagos(accion); -- Índice: idx_accion -- Optimiza búsquedas por tipo de acción

-- Índice: idx_fecha --
CREATE INDEX idx_fecha ON log_pagos(fecha_creacion); -- Índice: idx_fecha -- Optimiza búsquedas por fecha de creación

-- Índice: idx_estado --
CREATE INDEX idx_estado ON log_pagos(estado_nuevo); -- Índice: idx_estado -- Optimiza búsquedas por estado nuevo

-- ============================================================================
-- Tabla: log_accesos --
-- Descripción: Auditoría de eventos de acceso y seguridad del sistema
-- ============================================================================
CREATE TABLE IF NOT EXISTS log_accesos( -- Tabla: log_accesos --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del registro de log
	usuario_id VARCHAR(36), -- FOREIGN KEY - Usuario relacionado con el evento
	acceso_id VARCHAR(36), -- FOREIGN KEY - Registro de acceso asociado
	credencial_id VARCHAR(36), -- FOREIGN KEY - Credencial relacionada con el evento
	usuario_sistema_id VARCHAR(36), -- FOREIGN KEY - Usuario del sistema que registró el evento
	accion ENUM('ACCESO_PERMITIDO','ACCESO_RECHAZADO','CREDENCIAL_BLOQUEADA','CREDENCIAL_DESBLOQUEADA','CREDENCIAL_REVOCADA','CREDENCIAL_REEMPLAZADA','SALIDA_REGISTRADA_AUTOMATICAMENTE','ALERTA_SEGURIDAD') NOT NULL, -- Acción de seguridad registrada
	detalle VARCHAR(500), -- Detalle del evento de seguridad
	metodo_validacion ENUM('RFID','QR','BIOMETRICO','MANUAL','AUTOMATICO'), -- Método de validación utilizado
	punto_acceso VARCHAR(100), -- Punto de acceso donde ocurrió el evento
	datos_adicionales JSON, -- Datos adicionales en formato JSON flexible
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora del registro del log
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario
	FOREIGN KEY (acceso_id) REFERENCES accesos(id), -- Relación con el acceso
	FOREIGN KEY (credencial_id) REFERENCES credenciales_acceso(id), -- Relación con la credencial
	FOREIGN KEY (usuario_sistema_id) REFERENCES usuario(id) -- Relación con el usuario del sistema
);

-- Índice: idx_usuario_fecha --
CREATE INDEX idx_usuario_fecha ON log_accesos(usuario_id, fecha_creacion); -- Índice: idx_usuario_fecha -- Optimiza búsquedas por usuario y fecha

-- Índice: idx_accion --
CREATE INDEX idx_accion ON log_accesos(accion); -- Índice: idx_accion -- Optimiza búsquedas por tipo de acción

-- Índice: idx_fecha --
CREATE INDEX idx_fecha ON log_accesos(fecha_creacion); -- Índice: idx_fecha -- Optimiza búsquedas por fecha de creación

-- Índice: idx_credencial --
CREATE INDEX idx_credencial ON log_accesos(credencial_id); -- Índice: idx_credencial -- Optimiza búsquedas por credencial

-- ============================================================================
-- Tabla: recordatorios --
-- Descripción: Gestiona los recordatorios y notificaciones enviadas a los usuarios
-- ============================================================================
CREATE TABLE IF NOT EXISTS recordatorios( -- Tabla: recordatorios --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del recordatorio
	usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Usuario destinatario del recordatorio
	tipo_recordatorio ENUM('RENOVACION_MEMBRESIA','RESERVA_PROXIMA','PAGO_PENDIENTE','FACTURA_VENCIDA','SERVICIO_DISPONIBLE','BIENVENIDA','OTRO') NOT NULL, -- Tipo de recordatorio
	referencia_tipo ENUM('MEMBRESIA','RESERVA','FACTURA','SERVICIO','USUARIO'), -- Tipo de entidad referenciada
	referencia_id VARCHAR(36), -- ID de la entidad referenciada
	canal_envio ENUM('EMAIL','SMS','PUSH','WHATSAPP','INTERNO') NOT NULL, -- Canal por el cual se envía el recordatorio
	asunto VARCHAR(255), -- Asunto del recordatorio (para email/SMS)
	mensaje TEXT NOT NULL, -- Contenido del mensaje del recordatorio
	fecha_programada DATETIME NOT NULL, -- Fecha y hora programada para el envío
	fecha_envio DATETIME, -- Fecha y hora real del envío
	estado ENUM('PROGRAMADO','ENVIADO','FALLIDO','CANCELADO') DEFAULT 'PROGRAMADO', -- Estado actual del recordatorio
	intentos_envio INT DEFAULT 0, -- Número de intentos de envío realizados
	ultimo_intento DATETIME, -- Fecha y hora del último intento de envío
	error_envio VARCHAR(500), -- Mensaje de error si el envío falló
	leido BOOLEAN DEFAULT FALSE, -- Indica si el usuario leyó el recordatorio
	fecha_lectura DATETIME, -- Fecha y hora en que el usuario leyó el recordatorio
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del recordatorio
	FOREIGN KEY (usuario_id) REFERENCES usuario(id) -- Relación con el usuario destinatario
);

-- Índice: idx_usuario_estado --
CREATE INDEX idx_usuario_estado ON recordatorios(usuario_id, estado); -- Índice: idx_usuario_estado -- Optimiza búsquedas por usuario y estado

-- Índice: idx_tipo_fecha --
CREATE INDEX idx_tipo_fecha ON recordatorios(tipo_recordatorio, fecha_programada); -- Índice: idx_tipo_fecha -- Optimiza búsquedas por tipo y fecha programada

-- Índice: idx_estado_fecha --
CREATE INDEX idx_estado_fecha ON recordatorios(estado, fecha_programada); -- Índice: idx_estado_fecha -- Optimiza búsquedas por estado y fecha programada

-- Índice: idx_fecha_envio --
CREATE INDEX idx_fecha_envio ON recordatorios(fecha_envio); -- Índice: idx_fecha_envio -- Optimiza búsquedas por fecha de envío

-- Índice: idx_referencia --
CREATE INDEX idx_referencia ON recordatorios(referencia_tipo, referencia_id); -- Índice: idx_referencia -- Optimiza búsquedas por tipo y ID de referencia

-- ============================================================================
-- Tabla: reportes_generados --
-- Descripción: Almacena los reportes generados por el sistema
-- ============================================================================
CREATE TABLE IF NOT EXISTS reportes_generados( -- Tabla: reportes_generados --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del reporte
	usuario_genero VARCHAR(36), -- FOREIGN KEY - Usuario que generó el reporte
	tipo_reporte ENUM('DIARIO_ASISTENCIAS','SEMANAL_MEMBRESIAS','SEMANAL_OCUPACION','MENSUAL_FACTURACION','MENSUAL_INGRESOS','TOP_USUARIOS','USUARIOS_INACTIVOS','ACCESOS_FUERA_HORARIO','OCUPACION_GLOBAL','OTRO') NOT NULL, -- Tipo de reporte generado
	titulo VARCHAR(255) NOT NULL, -- Título descriptivo del reporte
	descripcion TEXT, -- Descripción detallada del reporte
	periodo_inicio DATETIME NOT NULL, -- Fecha y hora de inicio del periodo del reporte
	periodo_fin DATETIME NOT NULL, -- Fecha y hora de fin del periodo del reporte
	formato ENUM('JSON','CSV','PDF','EXCEL','TEXTO') DEFAULT 'JSON', -- Formato del archivo generado
	contenido JSON, -- Contenido del reporte en formato JSON
	archivo_url VARCHAR(400), -- URL del archivo generado (si se almacenó externamente)
	tamano_bytes INT, -- Tamaño del archivo en bytes
	destinatarios JSON, -- Lista de destinatarios del reporte en formato JSON
	estado ENUM('GENERADO','ENVIADO','FALLIDO','PENDIENTE_ENVIO') DEFAULT 'GENERADO', -- Estado actual del reporte
	tiempo_ejecucion_segundos DECIMAL(8,2), -- Tiempo que tomó generar el reporte
	error_generacion VARCHAR(500), -- Mensaje de error si la generación falló
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del reporte
	FOREIGN KEY (usuario_genero) REFERENCES usuario(id) -- Relación con el usuario que generó
);

-- Índice: idx_tipo_fecha --
CREATE INDEX idx_tipo_fecha ON reportes_generados(tipo_reporte, fecha_creacion); -- Índice: idx_tipo_fecha -- Optimiza búsquedas por tipo y fecha

-- Índice: idx_estado --
CREATE INDEX idx_estado ON reportes_generados(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado

-- Índice: idx_fecha --
CREATE INDEX idx_fecha ON reportes_generados(fecha_creacion); -- Índice: idx_fecha -- Optimiza búsquedas por fecha de creación

-- Índice: idx_periodo --
CREATE INDEX idx_periodo ON reportes_generados(periodo_inicio, periodo_fin); -- Índice: idx_periodo -- Optimiza búsquedas por periodo

-- ============================================================================
-- Tabla: roles --
-- Descripción: Define los roles de usuario disponibles en el sistema
-- ============================================================================
CREATE TABLE IF NOT EXISTS roles( -- Tabla: roles --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del rol
	codigo VARCHAR(20) UNIQUE NOT NULL, -- Código único del rol (ej: ADMIN, USER, GUEST)
	nombre VARCHAR(50) UNIQUE NOT NULL, -- Nombre descriptivo del rol
	descripcion TEXT, -- Descripción detallada del rol
	nivel_acceso INT NOT NULL, -- 1=básico, 10=máximo (para jerarquía) - Nivel de privilegios
	es_sistema BOOLEAN DEFAULT FALSE, -- TRUE si es rol del sistema (no se puede eliminar)
	color VARCHAR(7), -- Color para UI (ej: #FF5733) - Color visual del rol
	icono VARCHAR(50), -- Icono para UI (ej: 'fa-user-shield') - Ícono visual del rol
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del rol
	estado ENUM('ACTIVO','INACTIVO') DEFAULT 'ACTIVO' -- Estado actual del rol
);

-- Índice: idx_estado --
CREATE INDEX idx_estado ON roles(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado

-- Índice: idx_nivel --
CREATE INDEX idx_nivel ON roles(nivel_acceso); -- Índice: idx_nivel -- Optimiza búsquedas por nivel de acceso

-- ============================================================================
-- Tabla: permisos --
-- Descripción: Define los permisos disponibles en el sistema por módulo y acción
-- ============================================================================
CREATE TABLE IF NOT EXISTS permisos( -- Tabla: permisos --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del permiso
	codigo VARCHAR(50) UNIQUE NOT NULL, -- Ej: 'USUARIOS_CREAR', 'RESERVAS_CANCELAR' - Código único del permiso
	nombre VARCHAR(100) UNIQUE NOT NULL, -- Nombre descriptivo del permiso
	descripcion TEXT, -- Descripción detallada del permiso
	modulo ENUM('USUARIOS','MEMBRESIAS','ESPACIOS','RESERVAS','SERVICIOS','PAGOS','FACTURAS','ACCESOS','REPORTES','ADMINISTRACION','SEGURIDAD') NOT NULL, -- Módulo al que pertenece el permiso
	accion ENUM('VER','CREAR','EDITAR','ELIMINAR','EJECUTAR','APROBAR','RECHAZAR','EXPORTAR','IMPORTAR') NOT NULL, -- Acción permitida
	es_sistema BOOLEAN DEFAULT FALSE, -- TRUE si es permiso del sistema (no se puede eliminar)
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de creación del permiso
	estado ENUM('ACTIVO','INACTIVO') DEFAULT 'ACTIVO' -- Estado actual del permiso
);

-- Índice: idx_modulo --
CREATE INDEX idx_modulo ON permisos(modulo); -- Índice: idx_modulo -- Optimiza búsquedas por módulo

-- Índice: idx_modulo_accion --
CREATE INDEX idx_modulo_accion ON permisos(modulo, accion); -- Índice: idx_modulo_accion -- Optimiza búsquedas por módulo y acción

-- Índice: idx_estado --
CREATE INDEX idx_estado ON permisos(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado

-- ============================================================================
-- Tabla: roles_permisos --
-- Descripción: Relación muchos a muchos entre roles y permisos asignados
-- ============================================================================
CREATE TABLE IF NOT EXISTS roles_permisos( -- Tabla: roles_permisos --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único de la asignación
	rol_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Rol al que se asigna el permiso
	permiso_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Permiso asignado al rol
	usuario_asigno VARCHAR(36), -- FOREIGN KEY (admin que asignó el permiso) - Usuario que realizó la asignación
	fecha_asignacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de la asignación
	estado ENUM('ACTIVO','INACTIVO') DEFAULT 'ACTIVO', -- Estado de la asignación
	FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE CASCADE, -- Relación con el rol (se elimina si se elimina el rol)
	FOREIGN KEY (permiso_id) REFERENCES permisos(id) ON DELETE CASCADE, -- Relación con el permiso (se elimina si se elimina el permiso)
	FOREIGN KEY (usuario_asigno) REFERENCES usuario(id), -- Relación con el usuario que asignó
	UNIQUE KEY uq_rol_permiso (rol_id, permiso_id) -- Un rol no puede tener el mismo permiso dos veces
);

-- Índice: idx_rol --
CREATE INDEX idx_rol ON roles_permisos(rol_id); -- Índice: idx_rol -- Optimiza búsquedas por rol

-- Índice: idx_permiso --
CREATE INDEX idx_permiso ON roles_permisos(permiso_id); -- Índice: idx_permiso -- Optimiza búsquedas por permiso

-- Índice: idx_estado --
CREATE INDEX idx_estado ON roles_permisos(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado

-- ============================================================================
-- Tabla: usuarios_roles --
-- Descripción: Relación muchos a muchos entre usuarios y roles asignados
-- ============================================================================
CREATE TABLE IF NOT EXISTS usuarios_roles( -- Tabla: usuarios_roles --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único de la asignación
	usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Usuario al que se asigna el rol
	rol_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Rol asignado al usuario
	fecha_asignacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de la asignación
	fecha_expiracion DATETIME, -- Para roles temporales (ej: invitado por 1 día) - Fecha de expiración
	usuario_asigno VARCHAR(36), -- FOREIGN KEY (admin que asignó el rol) - Usuario que realizó la asignación
	motivo_asignacion VARCHAR(255), -- Motivo de la asignación del rol
	estado ENUM('ACTIVO','INACTIVO','EXPIRADO','REVOCADO') DEFAULT 'ACTIVO', -- Estado de la asignación
	FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE, -- Relación con el usuario (se elimina si se elimina el usuario)
	FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE CASCADE, -- Relación con el rol (se elimina si se elimina el rol)
	FOREIGN KEY (usuario_asigno) REFERENCES usuario(id), -- Relación con el usuario que asignó
	UNIQUE KEY uq_usuario_rol (usuario_id, rol_id) -- Un usuario no puede tener el mismo rol dos veces
);

-- Índice: idx_usuario --
CREATE INDEX idx_usuario ON usuarios_roles(usuario_id); -- Índice: idx_usuario -- Optimiza búsquedas por usuario

-- Índice: idx_rol --
CREATE INDEX idx_rol ON usuarios_roles(rol_id); -- Índice: idx_rol -- Optimiza búsquedas por rol

-- Índice: idx_estado --
CREATE INDEX idx_estado ON usuarios_roles(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado

-- Índice: idx_expiracion --
CREATE INDEX idx_expiracion ON usuarios_roles(fecha_expiracion); -- Índice: idx_expiracion -- Optimiza búsquedas por fecha de expiración

-- ============================================================================
-- Tabla: sesiones --
-- Descripción: Gestiona las sesiones activas de los usuarios en el sistema
-- ============================================================================
CREATE TABLE IF NOT EXISTS sesiones( -- Tabla: sesiones --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único de la sesión
	usuario_id VARCHAR(36) NOT NULL, -- FOREIGN KEY - Usuario propietario de la sesión
	token VARCHAR(255) UNIQUE NOT NULL, -- Token de sesión (JWT, session ID, etc.) - Token único de autenticación
	ip_address VARCHAR(45), -- IPv4 o IPv6 - Dirección IP desde donde se inició la sesión
	user_agent VARCHAR(500), -- Navegador/dispositivo - Información del cliente
	dispositivo VARCHAR(100), -- Descripción del dispositivo - Nombre del dispositivo
	ubicacion VARCHAR(255), -- Ubicación geográfica (si se puede determinar) - Geolocalización
	fecha_login DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora de inicio de sesión
	fecha_ultimo_acceso DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora del último acceso
	fecha_logout DATETIME, -- Fecha y hora de cierre de sesión
	fecha_expiracion DATETIME NOT NULL, -- Fecha y hora de expiración de la sesión
	estado ENUM('ACTIVA','EXPIRADA','CERRADA','INVALIDADA') DEFAULT 'ACTIVA', -- Estado actual de la sesión
	motivo_cierre VARCHAR(255), -- Razón del cierre de sesión
	intentos_fallidos INT DEFAULT 0, -- Número de intentos fallidos en la sesión
	FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE -- Relación con el usuario (se elimina si se elimina el usuario)
);

-- Índice: idx_usuario --
CREATE INDEX idx_usuario ON sesiones(usuario_id); -- Índice: idx_usuario -- Optimiza búsquedas por usuario

-- Índice: idx_token --
CREATE INDEX idx_token ON sesiones(token); -- Índice: idx_token -- Optimiza búsquedas por token

-- Índice: idx_estado --
CREATE INDEX idx_estado ON sesiones(estado); -- Índice: idx_estado -- Optimiza búsquedas por estado

-- Índice: idx_expiracion --
CREATE INDEX idx_expiracion ON sesiones(fecha_expiracion); -- Índice: idx_expiracion -- Optimiza búsquedas por fecha de expiración

-- Índice: idx_fecha_login --
CREATE INDEX idx_fecha_login ON sesiones(fecha_login); -- Índice: idx_fecha_login -- Optimiza búsquedas por fecha de login

-- ============================================================================
-- Tabla: log_autorizacion --
-- Descripción: Auditoría de intentos de acceso a recursos del sistema
-- ============================================================================
CREATE TABLE IF NOT EXISTS log_autorizacion( -- Tabla: log_autorizacion --
	id VARCHAR(36) DEFAULT (UUID()) PRIMARY KEY, -- Identificador único del registro de autorización
	usuario_id VARCHAR(36), -- FOREIGN KEY (NULL si es usuario no autenticado) - Usuario que intentó acceder
	sesion_id VARCHAR(36), -- FOREIGN KEY (sesión desde la que se intentó acceder) - Sesión activa
	recurso VARCHAR(255) NOT NULL, -- Ej: '/api/reservas', 'REPORTES_MENSUALES' - Recurso al que se intentó acceder
	accion ENUM('VER','CREAR','EDITAR','ELIMINAR','EJECUTAR','APROBAR','RECHAZAR','EXPORTAR','IMPORTAR') NOT NULL, -- Acción intentada sobre el recurso
	modulo VARCHAR(50), -- Módulo al que pertenece el recurso
	permiso_requerido VARCHAR(50), -- Código del permiso requerido para acceder
	resultado ENUM('PERMITIDO','DENEGADO','ERROR') NOT NULL, -- Resultado del intento de acceso
	motivo_denegacion VARCHAR(255), -- Razón de la denegación (si aplica)
	ip_address VARCHAR(45), -- Dirección IP desde donde se intentó acceder
	user_agent VARCHAR(500), -- Navegador/dispositivo utilizado
	fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP(), -- Fecha y hora del registro
	FOREIGN KEY (usuario_id) REFERENCES usuario(id), -- Relación con el usuario
	FOREIGN KEY (sesion_id) REFERENCES sesiones(id) -- Relación con la sesión
);

-- Índice: idx_usuario_fecha --
CREATE INDEX idx_usuario_fecha ON log_autorizacion(usuario_id, fecha_creacion); -- Índice: idx_usuario_fecha -- Optimiza búsquedas por usuario y fecha

-- Índice: idx_resultado --
CREATE INDEX idx_resultado ON log_autorizacion(resultado); -- Índice: idx_resultado -- Optimiza búsquedas por resultado

-- Índice: idx_recurso --
CREATE INDEX idx_recurso ON log_autorizacion(recurso); -- Índice: idx_recurso -- Optimiza búsquedas por recurso

-- Índice: idx_fecha --
CREATE INDEX idx_fecha ON log_autorizacion(fecha_creacion); -- Índice: idx_fecha -- Optimiza búsquedas por fecha

-- Índice: idx_modulo --
CREATE INDEX idx_modulo ON log_autorizacion(modulo); -- Índice: idx_modulo -- Optimiza búsquedas por módulo
