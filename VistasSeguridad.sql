-- Vistas de Seguridad
-- Vistas para el rol 'Usuario'
-- Ideal para que el usuario solo pueda ver sus datos y no de los demas
-- Se filtra la tabla 'usuario' basado en el email del usuario conectado
-- Se ejecuta como 'Administrador' para crear la vista y asignar permisos
CREATE OR REPLACE VIEW coworking.mis_datos AS
SELECT * FROM coworking.usuario
WHERE email = SUBSTRING_INDEX(USER(), '@',1);
-- Se revocan los accesos a la tabla completa
REVOKE ALL PRIVILEGES ON coworking.usuario FROM 'Usuario';
-- Se genera acceso UNICAMENTE a la vista de sus datos personales
GRANT SELECT ON coworking.mis_datos TO 'Usuario';
-- Vistas para el rol 'Contador'
-- El contador podra VER la informacion financiera RELEVANTE para su cargo
CREATE OR REPLACE VIEW coworking.vista_reportes_financieros AS
SELECT
	f.numero_factura,
	f.total,
	f.estado,
	f.fecha_emision,
	p.codigo_pago,
	p.monto
FROM coworking.facturas f
LEFT JOIN coworking.pagos p ON f.id = p.factura_id;
-- Se retiran permisos de toda la tabla financiera y se LIMITA la vista para evitar filtracion de datos sensibles
REVOKE ALL PRIVILEGES ON coworking.facturas FROM 'Contador';
GRANT SELECT ON coworking.vista_reportes_financieros TO 'Contador';
-- Con esta vista se evita violacion de la privacidad de los clientes
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
-- Revocamos acceso a la tabla completa y se reasigna permisos a la vista para que solo tenga acceso a la informacion relevante
REVOKE ALL PRIVILEGES ON coworking.usuario FROM 'Recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking.vista_gestion_recepcion TO 'Recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking.reservas TO 'Recepcionista';
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
-- Limitamos la vista del Gerente para que no pueda ver la informacion de las otras empresas
REVOKE ALL PRIVILEGES ON coworking.usuario FROM 'Gerente';
REVOKE ALL PRIVILEGES ON coworking.facturas FROM 'Gerente';
GRANT SELECT ON coworking.vista_reporte_corporativo TO 'Gerente';