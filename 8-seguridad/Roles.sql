USE coworking;

-- Creacion de los Roles
CREATE ROLE IF NOT EXISTS 'Administrador';
CREATE ROLE IF NOT EXISTS 'Recepcionista';
CREATE ROLE IF NOT EXISTS 'Usuario';
CREATE ROLE IF NOT EXISTS 'Gerente';
CREATE ROLE IF NOT EXISTS 'Contador';

-- Asignacion de Permisos a cada Rol
-- Permisos Admin: GOD MODE
GRANT ALL PRIVILEGES ON coworking.* TO 'Administrador';

-- Permisos Recepcion: Gestion de Usuarios, Reservas y Membresias
GRANT SELECT, INSERT, UPDATE ON coworking.usuario TO 'Recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking.reservas TO 'Recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking.reservas_clientes TO 'Recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking.credenciales_acceso TO 'Recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking.accesos TO 'Recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking.intentos_acceso_rechazados TO 'Recepcionista';

-- Permisos de solo lectura para el Recepcionista
GRANT SELECT ON coworking.tipos_membresia TO 'Recepcionista';
GRANT SELECT ON coworking.empresas TO 'Recepcionista';
GRANT SELECT ON coworking.membresia_usuario TO 'Recepcionista';
GRANT SELECT ON coworking.tipos_espacios TO 'Recepcionista';
GRANT SELECT ON coworking.espacios TO 'Recepcionista';
GRANT SELECT ON coworking.servicios_adicionales TO 'Recepcionista';

-- Permisos Usuarios: Ver sus propios datos, montar sus propias reservaciones y ver sus propias facturas
GRANT SELECT, INSERT, UPDATE ON coworking.reservas TO 'Usuario';
GRANT SELECT, INSERT ON coworking.reservas_clientes TO 'Usuario';
GRANT SELECT, INSERT ON coworking.servicios_contratados TO 'Usuario';

-- Permisos de solo lectura para el 'Usuario'
GRANT SELECT ON coworking.usuario TO 'Usuario';
GRANT SELECT ON coworking.facturas TO 'Usuario';
GRANT SELECT ON coworking.detalle_factura TO 'Usuario';
GRANT SELECT ON coworking.espacios TO 'Usuario';
GRANT SELECT ON coworking.tipos_membresia TO 'Usuario';
GRANT SELECT ON coworking.servicios_adicionales TO 'Usuario';

-- Permisos Gerente: Ver los reportes y facturacion de su empresa
GRANT SELECT ON coworking.usuario TO 'Gerente';
GRANT SELECT ON coworking.facturas TO 'Gerente';
GRANT SELECT ON coworking.empresas TO 'Gerente';
GRANT SELECT ON coworking.detalle_factura TO 'Gerente';

-- Permisos Contador: Lectura de los Reportes Financieros
GRANT SELECT ON coworking.pagos TO 'Contador';
GRANT SELECT ON coworking.facturas TO 'Contador';
GRANT SELECT ON coworking.detalle_factura TO 'Contador';
GRANT SELECT ON coworking.metodos_pago TO 'Contador';
GRANT SELECT ON coworking.servicios_contratados TO 'Contador';

-- Creacion de Usuarios de Prueba
CREATE USER IF NOT EXISTS 'admin_01'@'%' IDENTIFIED BY 'PasswordSegura123!';
CREATE USER IF NOT EXISTS 'recep_01'@'%' IDENTIFIED BY 'PasswordSegura123!';
CREATE USER IF NOT EXISTS 'usuario_01'@'%' IDENTIFIED BY 'PasswordSeguro123!';
CREATE USER IF NOT EXISTS 'gerente_01'@'%' IDENTIFIED BY 'PasswordSeguro123!';
CREATE USER IF NOT EXISTS 'contador_01'@'%' IDENTIFIED BY 'PasswordSeguro123!';

-- Asignacion de los Roles a los Usuarios existentes
GRANT 'Administrador' TO 'admin_01'@'%';
GRANT 'Recepcionista' TO 'recep_01'@'%';
GRANT 'Usuario' TO 'usuario_01'@'%';
GRANT 'Gerente' TO 'gerente_01'@'%';
GRANT 'Contador' TO 'contador_01'@'%';

-- Asignacion automatica de los Roles a los usuarios existentes
SET DEFAULT ROLE 'Administrador' TO 'admin_01'@'%';
SET DEFAULT ROLE 'Recepcionista' TO 'recep_01'@'%';
SET DEFAULT ROLE 'Usuario' TO 'usuario_01'@'%';
SET DEFAULT ROLE 'Gerente' TO 'gerente_01'@'%';
SET DEFAULT ROLE 'Contador' TO 'contador_01'@'%';

FLUSH PRIVILEGES;
-- Flush Privileges obliga a MySQL a recargar todas las tablas de permiso desde cero, garantizando su cambio absoluto e instantaneo ignorando el cache existente