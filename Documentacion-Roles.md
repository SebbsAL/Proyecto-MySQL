## Roles de Usuario y Permisos

Para garantizar la seguridad y el correcto flujo de la información dentro del sistema de Coworking, se implementó un modelo de control de acceso basado en el principio de privilegios mínimos. 

El sistema cuenta con **5 roles de usuario** específicos:

1. **Administrador (`Administrador`)**: 
   * **Nivel de acceso:** Total (God Mode).
   * **Permisos:** `ALL PRIVILEGES` sobre toda la base de datos `coworking`. Tiene la capacidad de gestionar estructura, datos, seguridad y auditoría.

2. **Recepcionista (`Recepcionista`)**: 
   * **Nivel de acceso:** Operativo.
   * **Permisos:** Diseñado para la gestión diaria. Puede consultar, insertar y actualizar datos en las tablas `usuario` y `reservas`. Adicionalmente, tiene permisos de solo lectura (`SELECT`) sobre los `tipos_membresia`.

3. **Usuario (`Usuario`)**: 
   * **Nivel de acceso:** Cliente del Coworking.
   * **Permisos:** Puede visualizar y actualizar su propia información (`SELECT`, `UPDATE` en `usuario`), crear nuevas reservaciones (`SELECT`, `INSERT` en `reservas`) y consultar su historial de facturación (`SELECT` en `facturas`).

4. **Gerente Corporativo (`Gerente`)**: 
   * **Nivel de acceso:** Administrativo.
   * **Permisos:** Acceso de solo lectura (`SELECT`) a las tablas `usuario` y `facturas` para auditar los consumos y empleados vinculados a su respectiva empresa.

5. **Contador (`Contador`)**: 
   * **Nivel de acceso:** Financiero.
   * **Permisos:** Acceso estricto de solo lectura (`SELECT`) a las tablas de `pagos` y `facturas` para la consolidación de ingresos y reportes financieros, sin riesgo de alterar la información operativa.

### Instrucciones para la Creación y Asignación de Roles

Para implementar este esquema de seguridad en MySQL o a través de clientes como DBeaver, se debe ejecutar el script `Roles.sql` incluido en la carpeta de este repositorio.

**Paso 1: Creación de los Roles**
Primero, se definen los roles lógicos en el motor de base de datos:
```sql
CREATE ROLE 'Administrador', 'Recepcionista', 'Usuario', 'Gerente', 'Contador';

Paso 2: Asignación de Permisos a los Roles
Se otorgan los privilegios específicos a cada rol utilizando sentencias GRANT. Por ejemplo, para el recepcionista:
GRANT SELECT, INSERT, UPDATE ON coworking.usuario TO 'Recepcionista';

Paso 3: Creación de Usuarios de Prueba
Se instancian los usuarios físicos que accederán al sistema, definiendo su host de conexión y contraseña:
CREATE USER 'recep_01'@'%' IDENTIFIED BY 'PasswordSegura123!';

Paso 4: Asignación y Activación del Rol
Finalmente, se vincula el rol lógico al usuario físico y se configura para que se active automáticamente al iniciar sesión:
GRANT 'Recepcionista' TO 'recep_01'@'%';
SET DEFAULT ROLE 'Recepcionista' TO 'recep_01'@'%';