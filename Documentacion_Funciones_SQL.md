# Documentación de Funciones SQL

## Objetivo
Este documento describe las funciones almacenadas desarrolladas para apoyar la lógica de negocio del sistema de coworking. Cada función encapsula consultas frecuentes, facilita la reutilización del código y simplifica la obtención de indicadores relacionados con membresías, reservas, pagos y accesos.

## Funciones

### 1. `fn_membresia_activa`
- **Propósito:** Determinar si un usuario posee una membresía activa para permitir o restringir operaciones dentro del sistema.
- **Parámetros:** `p_usuario_id VARCHAR(36)`
- **Retorna:** `BOOLEAN`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 2. `fn_dias_restantes_membresia`
- **Propósito:** Calcular los días restantes de vigencia de la membresía activa.
- **Parámetros:** `p_usuario_id VARCHAR(36)`
- **Retorna:** `INT`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 3. `fn_tipo_membresia`
- **Propósito:** Identificar el tipo de membresía vigente del usuario.
- **Parámetros:** `p_usuario_id VARCHAR(36)`
- **Retorna:** `VARCHAR(255)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 4. `fn_renovaciones_membresia`
- **Propósito:** Consultar cuántas veces se ha renovado la membresía activa.
- **Parámetros:** `p_usuario_id VARCHAR(36)`
- **Retorna:** `INT`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 5. `fn_estado_membresia`
- **Propósito:** Obtener el estado más reciente de la membresía del usuario.
- **Parámetros:** `p_usuario_id VARCHAR(36)`
- **Retorna:** `VARCHAR(100)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 6. `fn_total_reservas`
- **Propósito:** Conocer el número total de reservas realizadas por un usuario.
- **Parámetros:** `r_usuario_id VARCHAR(36)`
- **Retorna:** `INT`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 7. `fn_horas_reservadas`
- **Propósito:** Calcular el total de horas reservadas en un período específico.
- **Parámetros:** `p_usuario_id VARCHAR(36), p_mes INT, p_anio INT`
- **Retorna:** `DECIMAL(10,2)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 8. `fn_espacio_mas_reservado`
- **Propósito:** Identificar el espacio con mayor demanda.
- **Parámetros:** `Ninguno`
- **Retorna:** `VARCHAR(36)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 9. `fn_reservas_activas`
- **Propósito:** Contabilizar las reservas que aún siguen vigentes.
- **Parámetros:** `r_usuario_id VARCHAR(36)`
- **Retorna:** `INT`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 10. `fn_duracion_promedio_reservas`
- **Propósito:** Medir la duración promedio de uso de un espacio.
- **Parámetros:** `p_espacio_id VARCHAR(36)`
- **Retorna:** `DECIMAL(5,2)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 11. `fn_total_pagado`
- **Propósito:** Calcular el dinero pagado por un usuario.
- **Parámetros:** `p_usuario_id VARCHAR(36)`
- **Retorna:** `DECIMAL(12,2)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 12. `fn_ingresos_por_mes`
- **Propósito:** Obtener los ingresos generados en un mes determinado.
- **Parámetros:** `p_mes INT, p_anio INT`
- **Retorna:** `DECIMAL (14,2)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 13. `fn_ingresos_por_membresias`
- **Propósito:** Calcular los ingresos provenientes de membresías.
- **Parámetros:** `Ninguno`
- **Retorna:** `DECIMAL(14,2)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 14. `fn_ingresos_por_reservas`
- **Propósito:** Calcular los ingresos provenientes de reservas.
- **Parámetros:** `Ninguno`
- **Retorna:** `DECIMAL(14,2)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 15. `fn_ingresos_por_empresa`
- **Propósito:** Conocer los ingresos asociados a una empresa.
- **Parámetros:** `p_empresa_id VARCHAR(36)`
- **Retorna:** `DECIMAL(14,2)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 16. `fn_total_asistencias`
- **Propósito:** Contar todas las asistencias registradas de un usuario.
- **Parámetros:** `p_usuario_id VARCHAR(36)`
- **Retorna:** `INT`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 17. `fn_asistencias_mes`
- **Propósito:** Contar las asistencias en un período mensual.
- **Parámetros:** `p_usuario_id VARCHAR(36), p_mes INT, p_anio INT`
- **Retorna:** `INT`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 18. `fn_top_usuario_asistencias`
- **Propósito:** Identificar el usuario con mayor asistencia.
- **Parámetros:** `Ninguno`
- **Retorna:** `VARCHAR(155)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 19. `fn_ultima_asistencia`
- **Propósito:** Consultar la fecha de la última entrada registrada.
- **Parámetros:** `p_usuario_id VARCHAR(36)`
- **Retorna:** `DATETIME`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

### 20. `fn_promedio_asistencias`
- **Propósito:** Calcular el promedio de asistencias por usuario.
- **Parámetros:** `Ninguno`
- **Retorna:** `DECIMAL(10,2)`
- **Tablas utilizadas:** Según la consulta implementada (membresia_usuario, reservas, pagos, facturas, accesos o tipos_membresia).
- **Observaciones:** La función únicamente realiza consultas (`READS SQL DATA`) y no modifica información de la base de datos.

## Trabajo realizado

Se desarrollaron **20 funciones almacenadas** en MySQL con el objetivo de centralizar la lógica de consulta del sistema.

### Módulos cubiertos
- **Membresías:** validación de membresías activas, estado, tipo, renovaciones y vigencia.
- **Reservas:** estadísticas de uso, horas reservadas, reservas activas, duración promedio y espacio más utilizado.
- **Pagos:** cálculo de ingresos por usuario, empresa, tipo de factura y período.
- **Accesos:** consultas de asistencias, última entrada, usuario con mayor asistencia y promedio general.

### Características técnicas
- Implementadas mediante `CREATE FUNCTION`.
- Declaradas como `DETERMINISTIC`.
- Configuradas con `READS SQL DATA`.
- Uso de funciones agregadas como `COUNT`, `SUM`, `AVG`, `MAX` y `DATEDIFF`.
- Manejo de valores nulos mediante `IFNULL`.
- Uso de estructuras condicionales (`IF`) para validar distintos escenarios.
- Optimización de consultas mediante `JOIN`, `GROUP BY`, `ORDER BY` y `LIMIT` cuando fue necesario.

Estas funciones permiten reutilizar consultas complejas, reducir código repetitivo y facilitar la generación de reportes y estadísticas del sistema.
