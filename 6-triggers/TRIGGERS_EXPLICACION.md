# Explicación detallada de la lógica interna de los triggers

Este documento describe, trigger por trigger, qué hace cada uno de los 20 triggers definidos en [TRIGGERS.sql](TRIGGERS.sql), cuál es su momento de ejecución, qué condición evalúa y qué efecto produce sobre la base de datos.

---

## 1. trg_mem_vencimiento

- **Tabla afectada:** membresia_usuario
- **Momento:** BEFORE INSERT
- **Objetivo:** asignar automáticamente una fecha de vencimiento cuando se registra una nueva membresía.
- **Lógica interna:**
  - Antes de insertar un nuevo registro, toma el valor de `fecha_inicio`.
  - Le suma un intervalo de 1 mes mediante `DATE_ADD(..., INTERVAL 1 MONTH)`.
  - Guarda ese resultado en `NEW.fecha_fin`.
- **Resultado:** la membresía ya viene con una fecha de finalización calculada sin necesidad de enviar ese valor manualmente.

---

## 2. trg_mem_activar_pago

- **Tabla afectada:** pagos
- **Momento:** AFTER UPDATE
- **Objetivo:** activar la membresía del usuario cuando un pago cambia a estado `PAGADO`.
- **Lógica interna:**
  - Se activa cuando un registro de pagos es actualizado.
  - Comprueba si el nuevo estado es `PAGADO`.
  - Si la condición es verdadera, ejecuta un `UPDATE` sobre `membresia_usuario`.
  - Cambia el estado de la membresía del usuario a `ACTIVA`.
- **Resultado:** el sistema vincula el éxito del pago con la activación de la membresía.

---

## 3. trg_mem_suspender

- **Tabla afectada:** membresia_usuario
- **Momento:** BEFORE UPDATE
- **Objetivo:** suspender automáticamente una membresía si ya venció y estaba activa.
- **Lógica interna:**
  - Se ejecuta antes de actualizar un registro de membresía.
  - Evalúa si `fecha_fin` es menor que la fecha actual y si el estado actual es `ACTIVA`.
  - En ese caso, cambia `NEW.estado` a `SUSPENDIDA`.
- **Resultado:** evita que una membresía vencida siga marcada como activa.

---

## 4. trg_mem_log_tipo

- **Tabla afectada:** membresia_usuario
- **Momento:** AFTER UPDATE
- **Objetivo:** registrar en el log un cambio de tipo de membresía.
- **Lógica interna:**
  - Se activa cuando cambia el valor de `tipo_membresia_id`.
  - Compara el valor anterior (`OLD`) con el nuevo (`NEW`).
  - Si son distintos, inserta un registro en `log_membresias`.
  - El mensaje del cambio se construye con una concatenación de valores.
- **Resultado:** permite auditar modificaciones de tipo de membresía.

---

## 5. trg_bloquear_del_activo

- **Tabla afectada:** membresia_usuario
- **Momento:** BEFORE DELETE
- **Objetivo:** impedir eliminar una membresía si el usuario tiene reservas activas.
- **Lógica interna:**
  - Antes de borrar una membresía, consulta si existen reservas asociadas al usuario.
  - Busca reservas con estado `PENDIENTE` o `CONFIRMADO`.
  - Si encuentra alguna, lanza un error con `SIGNAL SQLSTATE '45000'`.
- **Resultado:** evita inconsistencias al borrar una membresía mientras el usuario aún tiene reservas en curso.

---

## 6. trg_res_duplicado

- **Tabla afectada:** reservas
- **Momento:** BEFORE INSERT
- **Objetivo:** evitar reservas duplicadas para el mismo espacio en la misma fecha.
- **Lógica interna:**
  - Antes de insertar una reserva nueva, verifica si ya existe otra reserva con el mismo `espacio_id` y la misma `fecha_reserva`.
  - Si existe, lanza una excepción.
- **Resultado:** impide que un espacio quede reservado dos veces para el mismo día en la misma condición.

---

## 7. trg_res_pendiente

- **Tabla afectada:** reservas
- **Momento:** BEFORE INSERT
- **Objetivo:** asignar un estado inicial de espera a toda reserva nueva.
- **Lógica interna:**
  - Antes de insertar, sobrescribe `NEW.estado` con `'Pendiente de Confirmación'`.
- **Resultado:** toda reserva nueva entra en un estado preliminar hasta que se confirme su pago o aprobación.

---

## 8. trg_res_confirmar

- **Tabla afectada:** pagos
- **Momento:** AFTER UPDATE
- **Objetivo:** confirmar una reserva cuando el pago asociado queda marcado como `PAGADO`.
- **Lógica interna:**
  - Se activa al actualizar un pago.
  - Si el estado del pago pasa a `PAGADO`, actualiza la reserva relacionada.
  - Cambia el estado de la reserva a `CONFIRMADA`.
- **Resultado:** el sistema automatiza la transición de una reserva de pendiente a confirmada.

---

## 9. trg_res_cancelar_mem

- **Tabla afectada:** membresia_usuario
- **Momento:** AFTER DELETE
- **Objetivo:** cancelar reservas cuando se elimina la membresía del usuario.
- **Lógica interna:**
  - Después de borrar una membresía, busca reservas del usuario.
  - Cambia su estado a `CANCELADA` siempre que aún no estén `COMPLETADA`.
- **Resultado:** evita que una reserva quede activa después de haber perdido la membresía.

---

## 10. trg_res_log_cancel

- **Tabla afectada:** reservas
- **Momento:** AFTER UPDATE
- **Objetivo:** registrar en un log toda reserva cancelada.
- **Lógica interna:**
  - Se ejecuta cuando cambia el estado de una reserva.
  - Verifica si el nuevo estado es `CANCELADA` y el anterior no lo era.
  - Inserta un registro en `log_reservas` con el identificador de la reserva y un motivo.
- **Resultado:** permite llevar seguimiento de cancelaciones.

---

## 11. trg_pag_crear_factura

- **Tabla afectada:** pagos
- **Momento:** AFTER INSERT
- **Objetivo:** generar automáticamente una factura al crear un nuevo pago.
- **Lógica interna:**
  - Después de insertar un pago, inserta un registro en `facturas`.
  - Usa `codigo_pago`, `usuario_id`, `monto` y un estado inicial `'Emitida'`.
- **Resultado:** cada pago queda asociado a una factura de manera automática.

---

## 12. trg_pag_factura_pagada

- **Tabla afectada:** pagos
- **Momento:** AFTER UPDATE
- **Objetivo:** marcar la factura como pagada cuando el pago cambia a `PAGADO`.
- **Lógica interna:**
  - Al actualizar un pago, evalúa si el estado nuevo es `PAGADO`.
  - Si es así, actualiza la factura que corresponde al pago.
  - Cambia el estado de esa factura a `PAGADA`.
- **Resultado:** sincroniza el estado del pago con el estado de la factura.

---

## 13. trg_pag_bloquear_del

- **Tabla afectada:** pagos
- **Momento:** BEFORE DELETE
- **Objetivo:** impedir borrar un pago si ya existe una factura asociada.
- **Lógica interna:**
  - Antes de eliminar un pago, verifica si hay facturas vinculadas.
  - Si existe al menos una, lanza un error.
- **Resultado:** protege la integridad de los datos financieros.

---

## 14. trg_pag_saldo

- **Tabla afectada:** pagos
- **Momento:** AFTER INSERT
- **Objetivo:** actualizar el saldo pendiente de la factura al registrar un pago.
- **Lógica interna:**
  - Después de insertar un pago, resta el monto del pago al saldo pendiente de la factura correspondiente.
- **Resultado:** la factura refleja el monto ya abonado.

---

## 15. trg_pag_log_anulado

- **Tabla afectada:** pagos
- **Momento:** AFTER UPDATE
- **Objetivo:** registrar en el log cuando un pago es rechazado.
- **Lógica interna:**
  - Se activa cuando cambia el estado de un pago.
  - Si el nuevo estado es `RECHAZADO` y el anterior no lo era, inserta un registro en `log_pagos`.
- **Resultado:** deja evidencia de pagos rechazados para auditoría.

---

## 16. trg_acc_asistencia

- **Tabla afectada:** accesos
- **Momento:** AFTER INSERT
- **Objetivo:** registrar una asistencia o evento de acceso al insertar un nuevo ingreso.
- **Lógica interna:**
  - Después de insertar un registro en `accesos`, inserta un registro en `log_accesos`.
  - Usa `usuario_id` y `fecha_creacion` del acceso.
- **Resultado:** permite llevar un historial de accesos registrados.

---

## 17. trg_acc_bloquear

- **Tabla afectada:** accesos
- **Momento:** BEFORE INSERT
- **Objetivo:** denegar el acceso si el usuario no tiene una membresía activa.
- **Lógica interna:**
  - Antes de insertar un acceso, consulta el estado de la membresía del usuario.
  - Si este estado no es `ACTIVA`, lanza una excepción.
- **Resultado:** impide que usuarios sin membresía válida entren al espacio.

---

## 18. trg_acc_ultima_fecha

- **Tabla afectada:** accesos
- **Momento:** AFTER INSERT
- **Objetivo:** actualizar la última fecha de acceso del usuario.
- **Lógica interna:**
  - Después de insertar un acceso, actualiza la tabla `usuario`.
  - Asigna `ultimo_acceso` con `fecha_hora` del nuevo acceso.
- **Resultado:** el sistema mantiene un registro del último acceso del usuario.

---

## 19. trg_acc_salida_auto

- **Tabla afectada:** accesos
- **Momento:** BEFORE INSERT
- **Objetivo:** convertir automáticamente un acceso en salida si el último registro del usuario fue una entrada.
- **Lógica interna:**
  - Antes de insertar, revisa el último acceso del usuario.
  - Si el último tipo fue `ENTRADA`, cambia el nuevo tipo a `SALIDA`.
- **Resultado:** ayuda a modelar un flujo de entrada/salida sin requerir que la aplicación indique manualmente el tipo.

---

## 20. trg_acc_log_rechazado

- **Tabla afectada:** intentos_acceso_rechazados
- **Momento:** AFTER INSERT
- **Objetivo:** registrar un log cada vez que un intento de acceso es rechazado.
- **Lógica interna:**
  - Después de insertar un intento rechazado, inserta un registro en `log_acceso`.
  - Guarda el evento, el motivo de rechazo y la fecha actual.
- **Resultado:** permite auditar intentos fallidos de acceso.

---

## Observaciones generales

- Los triggers se utilizan para automatizar reglas de negocio y asegurar consistencia en la base de datos.
- Algunos triggers trabajan sobre eventos de inserción, actualización o eliminación.
- Los triggers `BEFORE` permiten modificar datos antes de que se persistan.
- Los triggers `AFTER` permiten reaccionar a cambios ya realizados y disparar acciones adicionales.
- En general, la lógica es de tipo de negocio: validar, modificar, registrar y proteger información.
