# Explicación técnica de los eventos programados

Este documento describe, evento por evento, la función técnica de cada uno de los 20 eventos definidos en [EVENTOS.sql](EVENTOS.sql). La intención es explicar no solo qué hace cada rutina, sino también por qué forma parte del flujo automático del sistema y qué impacto operativo tiene.

---

## Módulo: Membresías

### 1. evt_mem_vencidas
- **Función técnica:** actualizar automáticamente el estado de las membresías que ya han expirado.
- **Frecuencia:** cada 1 día.
- **Lógica interna:** revisa las membresías cuyo campo de vencimiento es anterior a la fecha actual y que todavía están activas.
- **Objetivo operativo:** evitar que una membresía siga considerando como vigente después de su fecha límite.
- **Impacto:** mantiene la información de membresías alineada con el tiempo real y evita inconsistencias en accesos o servicios.

### 2. evt_mem_recordatorio
- **Función técnica:** generar recordatorios automáticos para usuarios cuyas membresías vencen en cinco días.
- **Frecuencia:** cada 1 día.
- **Lógica interna:** consulta los registros de membresía del usuario y, cuando la fecha de fin coincide con una fecha futura de 5 días, inserta un mensaje en la tabla de recordatorios.
- **Objetivo operativo:** anticipar la renovación y reducir la pérdida de usuarios por expiración.
- **Impacto:** convierte la expiración en un proceso comunicativo y preventivo.

### 3. evt_mem_suspender_inactivas
- **Función técnica:** suspender membresías que llevan mucho tiempo sin registrar un pago.
- **Frecuencia:** cada 1 día.
- **Lógica interna:** compara la fecha del último pago con la fecha actual y, si la diferencia supera los 30 días, cambia el estado de la membresía a `SUSPENDIDA`.
- **Objetivo operativo:** aplicar una política de control frente a usuarios que no mantienen sus pagos al día.
- **Impacto:** protege la operación del sistema contra membresías que quedan “activas” aunque ya no están al corriente.

### 4. evt_mem_reporte_semanal
- **Función técnica:** consolidar un reporte semanal del volumen de nuevas membresías.
- **Frecuencia:** cada 1 semana.
- **Lógica interna:** cuenta cuántas membresías fueron creadas o iniciadas en los últimos 7 días y guarda ese dato en la tabla de reportes generados.
- **Objetivo operativo:** medir crecimiento, captación y actividad de membresías en el periodo semanal.
- **Impacto:** facilita la toma de decisiones y la evaluación del negocio.

### 5. evt_mem_notificar_susp
- **Función técnica:** notificar de forma automática a recepción cuando una membresía fue suspendida.
- **Frecuencia:** cada 1 día.
- **Lógica interna:** busca membresías con estado `SUSPENDIDA` y fecha de suspensión igual a la fecha actual, para insertar un recordatorio o mensaje de alerta.
- **Objetivo operativo:** asegurar que el área de recepción conozca los casos que requieren seguimiento.
- **Impacto:** mejora la coordinación operativa entre sistemas y personal.

---

## Módulo: Reservas

### 6. evt_res_cancelar_pendientes
- **Función técnica:** cancelar reservas que quedaron pendientes durante demasiado tiempo.
- **Frecuencia:** cada 1 hora.
- **Lógica interna:** detecta reservas con estado `PENDIENTE` y una fecha de creación antigua, superior a dos horas, para cambiarlas a `CANCELADA`.
- **Objetivo operativo:** evitar que reservas en espera queden reteniendo un espacio sin confirmación real.
- **Impacto:** libera recursos y evita bloqueos innecesarios.

### 7. evt_res_recordatorio
- **Función técnica:** enviar alertas de reserva una hora antes de la hora programada.
- **Frecuencia:** cada 30 minutos.
- **Lógica interna:** identifica reservas cuya fecha coincide con el día actual y cuya hora de inicio es exactamente una hora después de la hora actual, y crea un recordatorio.
- **Objetivo operativo:** recordar al usuario que debe presentarse o confirmar su asistencia.
- **Impacto:** reduce ausencias y mejora la gestión de ocupación.

### 8. evt_res_limpiar_pasadas
- **Función técnica:** eliminar reservas pasadas que fueron marcadas como no asistidas.
- **Frecuencia:** cada 1 día.
- **Lógica interna:** borra reservas con estado `NOSHOW` y con una fecha anterior a siete días del día actual.
- **Objetivo operativo:** limpiar la base de datos de registros obsoletos y evitar sobrecarga de información histórica.
- **Impacto:** mejora el rendimiento y mantiene la tabla de reservas más ordenada.

### 9. evt_res_reporte_ocupacion
- **Función técnica:** generar un reporte semanal de ocupación por espacio.
- **Frecuencia:** cada 1 semana.
- **Lógica interna:** agrupa reservas de los últimos 7 días por `espacio_id` y prepara un dato resumen para reportes generados.
- **Objetivo operativo:** medir la demanda y la utilización de cada espacio.
- **Impacto:** apoya la planificación de capacidad y la toma de decisiones operativas.

### 10. evt_res_liberar_bloqueadas
- **Función técnica:** convertir automáticamente en no asistidas las reservas que quedaron “bloqueadas” sin iniciar.
- **Frecuencia:** cada 15 minutos.
- **Lógica interna:** busca reservas que siguen en estado pendiente y cuya hora de inicio ya pasó por más de 15 minutos, para cambiarlas a `NOSHOW`.
- **Objetivo operativo:** liberar el espacio de reservas que no se utilizaron.
- **Impacto:** evita que un recurso permanezca indisponible por falta de uso real.

---

## Módulo: Pagos y facturación

### 11. evt_pag_recordatorio
- **Función técnica:** emitir un aviso recurrente cuando existen pagos pendientes.
- **Frecuencia:** cada 3 días.
- **Lógica interna:** busca facturas con saldo pendiente y crea recordatorios para el usuario asociado.
- **Objetivo operativo:** recordar a los usuarios que aún tienen obligaciones financieras abiertas.
- **Impacto:** aumenta la probabilidad de cobro y reduce la morosidad.

### 12. evt_pag_bloquear_servicios
- **Función técnica:** bloquear el acceso a servicios para usuarios con facturas vencidas y sin pago.
- **Frecuencia:** cada 1 día.
- **Lógica interna:** identifica usuarios que poseen facturas vencidas por más de 10 días con saldo pendiente y actualiza su estado a `BLOQUEADO`.
- **Objetivo operativo:** aplicar una política de control financiero antes de que un usuario siga usando servicios sin cancelar.
- **Impacto:** protege la operación y refuerza la disciplina de pago.

### 13. evt_pag_resumen_mensual
- **Función técnica:** construir un resumen mensual de la facturación.
- **Frecuencia:** cada 1 mes.
- **Lógica interna:** suma el total de las facturas creadas en el mes corriente y lo registra en la tabla de reportes generados.
- **Objetivo operativo:** tener una vista consolidada del movimiento financiero mensual.
- **Impacto:** facilita la contabilidad y la evaluación del desempeño económico.

### 14. evt_pag_recargos
- **Función técnica:** aplicar recargos automáticos a facturas vencidas.
- **Frecuencia:** cada 1 día.
- **Lógica interna:** detecta facturas con fecha de vencimiento anterior a la fecha actual por más de 15 días y con saldo pendiente, y les incrementa el total en un 5%.
- **Objetivo operativo:** compensar el retraso en el pago y aplicar penalidades automáticas.
- **Impacto:** mejora la gestión de cobranza y el control del riesgo financiero.

### 15. evt_pag_reporte_contador
- **Función técnica:** preparar un reporte mensual de ingresos para el área contable.
- **Frecuencia:** cada 1 mes, a partir del 31 de enero a las 23:59:00.
- **Lógica interna:** suma los pagos marcados como `PAGADO` del mes actual y los deposita en un reporte destinado al contador.
- **Objetivo operativo:** automatizar la generación de información para contabilidad.
- **Impacto:** reduce trabajo manual y asegura periodicidad en la entrega de reportes.

---

## Módulo: Accesos y asistencias

### 16. evt_acc_limpiar_antiguos
- **Función técnica:** eliminar registros de acceso antiguos para conservar la base de datos en un tamaño controlado.
- **Frecuencia:** cada 1 mes.
- **Lógica interna:** borra accesos con fecha anterior a un año de la fecha actual.
- **Objetivo operativo:** prevenir el crecimiento excesivo de tablas de auditoría y monitoreo.
- **Impacto:** mejora el rendimiento y la mantenibilidad del sistema.

### 17. evt_acc_reporte_diario
- **Función técnica:** registrar un resumen diario de asistencias o accesos.
- **Frecuencia:** cada 1 día, a partir del 1 de enero a las 23:00:00.
- **Lógica interna:** cuenta los accesos registrados en el día actual y los guarda como reporte.
- **Objetivo operativo:** medir la actividad diaria del espacio o del sistema.
- **Impacto:** permite realizar análisis operativos y de uso diario.

### 18. evt_acc_inactivos
- **Función técnica:** detectar usuarios inactivos en base a su último acceso.
- **Frecuencia:** cada 1 semana.
- **Lógica interna:** identifica usuarios con un `ultimo_acceso` anterior a 30 días y registra esa condición en un reporte.
- **Objetivo operativo:** detectar bajas de actividad y posibles usuarios abandonados.
- **Impacto:** apoya campañas de retención o seguimiento de clientes.

### 19. evt_acc_fuera_horario
- **Función técnica:** alertar sobre accesos realizados fuera del horario laboral estándar.
- **Frecuencia:** cada 1 hora.
- **Lógica interna:** revisa accesos ocurridos en la última hora y detecta aquellos cuyo horario cae fuera del rango de 8:00 a 20:00.
- **Objetivo operativo:** reforzar el control de seguridad y de operación.
- **Impacto:** permite reaccionar ante eventos inesperados o accesos no autorizados.

### 20. evt_acc_top_usuarios
- **Función técnica:** identificar los usuarios más frecuentes del sistema en un periodo mensual.
- **Frecuencia:** cada 1 mes.
- **Lógica interna:** agrupa los accesos del mes actual por usuario, ordena los resultados por frecuencia y toma los 10 primeros.
- **Objetivo operativo:** reconocer patrones de uso intensivo y usuarios recurrentes.
- **Impacto:** sirve como base para reportes de comportamiento, fidelización y uso del espacio.

---

## Valor general del conjunto de eventos

Los eventos programados del archivo cumplen una función de automatización operativa. En conjunto, permiten:
- mantener la base de datos actualizada sin intervención manual;
- aplicar reglas de negocio de forma consistente;
- generar reportes periódicos;
- reducir errores humanos y mejorar la escalabilidad del sistema.

En términos técnicos, estos eventos actúan como una capa de procesamiento automático que complementa la lógica transaccional de la base de datos y facilita la gestión diaria del negocio.
