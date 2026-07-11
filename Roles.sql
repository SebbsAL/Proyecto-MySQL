-- Creacion de los Roles
CREATE ROLE 'Administrador';
CREATE ROLE 'Recepcionista';
CREATE ROLE 'Usuario';
CREATE ROLE 'Gerente';
CREATE ROLE 'Contador';
-- Asignacion de Permisos a cada Rol
-- Permisos Admin: GOD MODE
GRANT ALL PRIVILEGES ON coworking.* TO 'Administrador';
-- Permisos Recepcion: Gestion de Usuarios, Reservas y Membresias
GRANT SELECT, INSERT, UPDATE ON coworking.usuario TO 'Recepcionista';
GRANT SELECT, INSERT, UPDATE ON coworking.reservas TO 'Recepcionista';
GRANT SELECT ON coworking.tipos_membresia TO 'Recepcionista';
-- Permisos Usuarios: Ver Datos, Montar Reservaciones y Ver Facturacion
GRANT SELECT, UPDATE ON coworking.usuario TO 'Usuario';
GRANT SELECT, INSERT ON coworking.reservas TO 'Usuario';
GRANT SELECT ON coworking.facturas TO 'Usuario';
-- Permisos Gerente: Ver los Reportes de su Empresa
GRANT SELECT ON coworking.usuario TO 'Gerente';
GRANT SELECT ON coworking.facturas TO 'Gerente';
-- Permisos Contador: Lectura de los Reportes Financieros
GRANT SELECT ON coworking.pagos TO 'Contador';
GRANT SELECT ON coworking.facturas TO 'Contador';
-- Creacion de Usuarios de Prueba
CREATE USER 'admin_01'@'%' IDENTIFIED BY 'PasswordSegura123!';
CREATE USER 'recep_01'@'%' IDENTIFIED BY 'PasswordSegura123!';
CREATE USER 'usuario_01'@'%' IDENTIFIED BY 'PasswordSeguro123!';
CREATE USER 'gerente_01'@'%' IDENTIFIED BY 'PasswordSeguro123!';
CREATE USER 'contador_01'@'%' IDENTIFIED BY 'PasswordSeguro123!';
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
-- Sujeto a Posibles Cambios para seguir la estructura con las tablas finales