-- Vistas de Seguridad
-- Se ejecuta como 'Administrador' para crear la vista y asignar permisos
USE coworking;

-- Vistas para el rol 'Usuario'
-- Ideal para que el usuario solo pueda ver sus datos y no de los demas
-- Se filtra la tabla 'usuario' basado en el email o en la identificacion del usuario conectado
CREATE OR REPLACE VIEW coworking.mis_datos AS
SELECT * FROM coworking.usuario
WHERE email = SUBSTRING_INDEX(USER(), '@',1)
	OR identificacion = SUBSTRING_INDEX(USER(), '@', 1);

-- Vistas para el rol 'Contador'
-- El contador podra VER la informacion financiera RELEVANTE para su cargo
CREATE OR REPLACE VIEW coworking.vista_reportes_financieros AS
SELECT
	f.numero_factura,
	f.total,
	f.estado AS estado_factura,
	f.fecha_vencimiento,
	p.codigo_pago,
	p.monto
FROM coworking.facturas f
LEFT JOIN coworking.pagos p ON f.id = p.factura_id;

-- Vistas para el rol 'Recepcionista'
-- El Recepcionista gestiona usuarios sin necesidad de conocer la facturacion de los mismos ya que no es su rol
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

-- Vistas para el rol 'Gerente'
-- El Gerente solo debe ver los empleados y la facturacion de su empresa
CREATE OR REPLACE VIEW coworking.vista_reporte_corporativo AS
SELECT
	u.nombre,
	u.apellidos,
	u.email,
	u.estado AS estado_usuario,
	f.numero_factura,
	f.total,
	f.estado AS estado_factura
FROM coworking.usuario u
INNER JOIN coworking.empresas e ON u.empresa_id = e.id
LEFT JOIN coworking.facturas f ON e.id = f.empresa_id
WHERE e.persona_contacto = SUBSTRING_INDEX(USER(), '@', 1);

-- Restricciones de vistas globales a limitarlas de manera mas individual

-- Restricciones al rol 'Usuario'
REVOKE ALL PRIVILEGES ON coworking.usuario FROM 'Usuario';
GRANT SELECT ON coworking.mis_datos TO 'Usuario';
-- El usuario solo podra ver sus datos mas no de los demas Usuarios

-- Restricciones al rol 'Contador'
REVOKE ALL PRIVILEGES ON coworking.facturas FROM 'Contador';
REVOKE ALL PRIVILEGES ON coworking.pagos FROM 'Contador';
GRANT SELECT ON coworking.vista_reportes_financieros TO 'Contador';
-- El contador solo podra ver los datos necesarios para los reportes sin amenazar la integridad de los datos o detalles personales

-- Restricciones al rol 'Recepcionista'
REVOKE ALL PRIVILEGES ON coworking.usuario FROM 'Recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking.vista_gestion_recepcion TO 'Recepcionista';
-- Se limita la vista para limitar los INSERT/UPDATE sin afectar la integridad del resto de las tablas a las que tiene acceso

-- Restricciones al rol 'Gerente'
REVOKE ALL PRIVILEGES ON coworking.usuario FROM 'Gerente';
REVOKE ALL PRIVILEGES ON coworking.facturas FROM 'Gerente';
GRANT SELECT ON coworking.vista_reporte_corporativo TO 'Gerente';
-- Se evita que el Gerente de una empresa pueda acceder a la informacion sensible de otras empresas

FLUSH PRIVILEGES;
-- Flush Privileges obliga a MySQL a recargar todas las tablas de permiso desde cero, garantizando su cambio absoluto e instantaneo ignorando el cache existente