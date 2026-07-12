Roles de Usuario y Permisos
Para garantizar la seguridad y el correcto flujo de la información dentro del sistema de Coworking, se implementó un modelo de control de acceso basado en el principio de privilegios mínimos.

Este sistema de control de acceso ha sido diseñado para proteger la integridad de los datos financieros y operativos del Coworking, asegurando que cada rol cuente únicamente con los privilegios necesarios para cumplir sus funciones (Principio de Menor Privilegio), mitigando riesgos de acceso no autorizado mediante el uso de vistas de seguridad y restricciones de nivel de registro.

El sistema cuenta con 5 roles de usuario específicos:

Administrador (Administrador):

Nivel de acceso: Total (God Mode).

Permisos: ALL PRIVILEGES sobre toda la base de datos coworking. Tiene la capacidad de gestionar estructura, datos, seguridad y auditoría.

Recepcionista (Recepcionista):

Nivel de acceso: Operativo.

Permisos: Diseñado para la gestión diaria. Puede consultar, insertar y actualizar datos en las tablas operativas como usuario, reservas, reservas_clientes, credenciales_acceso, accesos e intentos_acceso_rechazados. Adicionalmente, tiene permisos de solo lectura (SELECT) sobre catálogos como tipos_membresia, empresas, espacios y servicios_adicionales.

Usuario (Usuario):

Nivel de acceso: Cliente del Coworking.

Permisos: Puede visualizar su propia información, crear nuevas reservaciones (INSERT en reservas y reservas_clientes), contratar servicios (INSERT en servicios_contratados) y consultar su historial de facturación de forma segura (SELECT en facturas y detalle_factura).

Gerente Corporativo (Gerente):

Nivel de acceso: Administrativo.

Permisos: Acceso de solo lectura (SELECT) a las tablas usuario, empresas, facturas y detalle_factura para auditar los consumos y empleados vinculados a su respectiva empresa.

Contador (Contador):

Nivel de acceso: Financiero.

Permisos: Acceso estricto de solo lectura (SELECT) a las tablas financieras (pagos, facturas, detalle_factura, metodos_pago y servicios_contratados) para la consolidación de ingresos y reportes financieros, sin riesgo de alterar la información operativa.

Instrucciones para la Creación y Asignación de Roles
Para implementar este esquema de seguridad en MySQL o a través de clientes como DBeaver, se debe ejecutar el script Roles.sql incluido en la carpeta de este repositorio.

Paso 1: Creación de los Roles
Primero, se definen los roles lógicos en el motor de base de datos de forma segura:
CREATE ROLE IF NOT EXISTS 'Administrador', 'Recepcionista', 'Usuario', 'Gerente', 'Contador';

Paso 2: Asignación de Permisos a los Roles
Se otorgan los privilegios específicos a cada rol utilizando sentencias GRANT. Por ejemplo, para el recepcionista:
GRANT SELECT, INSERT, UPDATE ON coworking.usuario TO 'Recepcionista';

Paso 3: Creación de Usuarios de Prueba
Se instancian los usuarios físicos que accederán al sistema, definiendo su host de conexión y contraseña:
CREATE USER IF NOT EXISTS 'recep_01'@'%' IDENTIFIED BY 'PasswordSegura123!';

Paso 4: Asignación y Activación del Rol
Se vincula el rol lógico al usuario físico y se configura para que se active automáticamente al iniciar sesión. Finalmente, se recargan los privilegios:
GRANT 'Recepcionista' TO 'recep_01'@'%';
SET DEFAULT ROLE 'Recepcionista' TO 'recep_01'@'%';
FLUSH PRIVILEGES;
Nota: FLUSH PRIVILEGES obliga a MySQL a recargar todas las tablas de permiso desde cero, garantizando su aplicación inmediata

Seguridad Avanzada: Vistas y Privacidad de Datos (Row-Level Security)
Para elevar el estándar de seguridad y garantizar la estricta privacidad de los datos sensibles, el módulo de usuarios implementa Vistas SQL que actúan como una capa de abstracción. Este enfoque asegura que cada rol interactúe únicamente con la información estrictamente necesaria para su labor, limitando el acceso a nivel de registro.

Para aplicar esta capa, se debe ejecutar el script de Vistas de Seguridad (ej. VistasSeguridad.sql), el cual revoca los accesos directos a las tablas base y otorga permisos exclusivos sobre las siguientes vistas:

Vista mis_datos (Rol: Usuario): Filtra la tabla usuario de forma dinámica comparando el usuario de sesión contra el correo electrónico o la identificación utilizando la función SUBSTRING_INDEX(USER(), '@', 1). Esto garantiza que el cliente autenticado solo pueda consultar su propio perfil.

Vista vista_reporte_corporativo (Rol: Gerente): A través de consultas combinadas (JOIN) con la tabla empresas y validando el usuario activo, esta vista restringe el acceso para que el gerente visualice única y exclusivamente a los empleados y la facturación asociada a su propia organización.

Vista vista_gestion_recepcion (Rol: Recepcionista): Proyecta la tabla usuario permitiendo la visualización de los datos operativos (nombre, identificación, estado), pero limitando el acceso a información que no corresponde a la recepción, protegiendo la integridad de otras tablas.

Vista vista_reportes_financieros (Rol: Contador): Consolida la información financiera excluyendo los datos de contacto y detalles personales de los clientes, permitiendo realizar cruces de información contable manteniendo el anonimato de la clientela.

Paso 5: Aplicación de las Vistas de Seguridad
Una vez creados los roles e instanciados los usuarios, se ejecutan las sentencias que reemplazan el acceso a las tablas por el acceso a las vistas. Por ejemplo, la transición para el rol del Contador:
-- Se retiran permisos directos sobre las tablas financieras
REVOKE ALL PRIVILEGES ON coworking.facturas FROM 'Contador';
REVOKE ALL PRIVILEGES ON coworking.pagos FROM 'Contador';

-- Se otorga acceso exclusivo a la vista anonimizada
GRANT SELECT ON coworking.vista_reportes_financieros TO 'Contador';