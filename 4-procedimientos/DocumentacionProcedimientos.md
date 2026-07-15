# 📖 Documentación de Procedimientos Almacenados

> **Proyecto:** Sistema de Gestión de Coworking  
> **Módulo:** Base de Datos (Stored Procedures)  
> **Descripción:** Este documento detalla la estructura y lógica de negocio encapsulada en la base de datos a través de Procedimientos Almacenados. Estos automatizan procesos críticos, centralizan las reglas operativas y garantizan la integridad contable y de accesos.

---

## 🎟️ 1. Módulo de Membresías

### 1.1. `RegistrarNuevaMembresia`
**Propósito:** Inserta una nueva membresía para un usuario, validando preventivamente que no cuente con una activa. Calcula de forma automática la fecha de vencimiento utilizando la duración predefinida del tipo de membresía.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_usuario_id` | `VARCHAR(36)` | ID del usuario a asociar. |
| `p_tipo_membresia_id` | `VARCHAR(36)` | ID del tipo de membresía adquirida. |
| `p_fecha_inicio` | `DATE` | Fecha desde la cual comienza la vigencia de la membresía. |

### 1.2. `RenovarMembresia`
**Propósito:** Extiende la vigencia de una membresía existente basándose en una nueva fecha de inicio. Aumenta el contador de renovaciones de manera automática y limpia el historial de suspensión (si lo hubiera), garantizando la reactivación total del servicio.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_membresia_usuario_id` | `VARCHAR(36)` | ID único de la membresía del usuario a renovar. |
| `p_nueva_fecha_inicio` | `DATE` | Fecha desde la cual inicia la nueva vigencia. |

### 1.3. `ActualizarEstadoMembresias`
**Propósito:** Script de mantenimiento masivo para el servidor de base de datos. Recorre todas las membresías en estado `ACTIVA` y las actualiza a `VENCIDA` si su fecha de fin es menor a la fecha de ejecución (día actual).

*No requiere parámetros.*

### 1.4. `SuspenderMembresiasPorDeuda`
**Propósito:** Rutina de control financiero. Cambia el estado a `SUSPENDIDA` y registra el motivo del bloqueo para aquellos usuarios que tengan facturas (`PENDIENTE` o `PARCIAL`) con una antigüedad superior a los días de tolerancia especificados.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_dias_atraso` | `INT` | Días de tolerancia de mora antes de aplicar la suspensión. |

---

## 🏢 2. Módulo de Reservas y Espacios

### 2.1. `VerificarDisponibilidad`
**Propósito:** Lógica de validación que previene el solapamiento de horarios ("Overbooking"). Verifica si un espacio específico ya cuenta con una reserva (`PENDIENTE` o `CONFIRMADA`) cruzando los horarios de inicio y fin en el mismo día.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_espacio_id` | `VARCHAR(36)` | ID del espacio a consultar. |
| `p_fecha_reserva` | `DATE` | Fecha de la reserva solicitada. |
| `p_hora_inicio` | `TIME` | Hora de inicio deseada. |
| `p_hora_fin` | `TIME` | Hora de fin deseada. |

### 2.2. `CrearReserva`
**Propósito:** Registra una nueva reserva (`PENDIENTE`). Ejecuta primero `VerificarDisponibilidad`. Si el espacio está libre, calcula automáticamente el precio total utilizando la tarifa base y genera un código de referencia legible para el usuario.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_usuario_id` | `VARCHAR(36)` | ID del usuario que crea la reserva. |
| `p_espacio_id` | `VARCHAR(36)` | ID del espacio o sala. |
| `p_fecha_reserva` | `DATE` | Fecha agendada para el uso del espacio. |
| `p_hora_inicio` | `TIME` | Hora de entrada programada. |
| `p_hora_fin` | `TIME` | Hora de salida programada. |
| `p_numero_asistentes` | `INT` | Cantidad total de personas esperadas. |
| `p_motivo` | `VARCHAR(255)` | Descripción o propósito de la reserva (ej. Reunión de ventas). |

### 2.3. `ConfirmarReserva`
**Propósito:** Actualiza el estado de la reserva a `CONFIRMADA` una vez que se ha detectado su respectivo pago, validando primero que provenga de un estado `PENDIENTE` para asegurar la coherencia del ciclo de vida.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_reserva_id` | `VARCHAR(36)` | ID de la reserva a confirmar. |
| `p_pago_id` | `VARCHAR(36)` | ID del registro de pago asociado. |

### 2.4. `CancelarReserva`
**Propósito:** Cambia el estado de una reserva a `CANCELADA`. Incluye la lógica para generar de manera automática un registro de reembolso (pago en negativo) según un porcentaje proporcionado como política de flexibilidad.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_reserva_id` | `VARCHAR(36)` | ID de la reserva a cancelar. |
| `p_motivo` | `VARCHAR(255)` | Razón provista por el usuario o administrador para la cancelación. |
| `p_porcentaje_reembolso` | `DECIMAL(3,2)` | Fracción del costo final que se devuelve (Ej. `0.50` para un 50%). |

### 2.5. `LiberarReservasPendientes`
**Propósito:** Barredor del sistema. Limpia el inventario buscando reservas `PENDIENTE` que no recibieron confirmación de pago y que han excedido su límite máximo de horas sin confirmar, cambiándolas automáticamente a `CANCELADA`.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_horas_limite` | `INT` | Cantidad de horas de vida límite que tiene una reserva no confirmada. |

---

## 💳 3. Módulo de Pagos y Facturación

### 3.1. `GenerarFacturaMembresia`
**Propósito:** Estructura de forma relacional una factura nueva (Creando la cabecera en `facturas` y el ítem individual en `detalle_factura`) cuando se activa o renueva una membresía.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_membresia_usuario_id` | `VARCHAR(36)` | ID de la membresía sobre la que se calculará la facturación. |

### 3.2. `GenerarFacturaConsolidadaCorporativa`
**Propósito:** Agrupa de forma inteligente todos los cargos no facturados (membresías, reservas, servicios) de los empleados de una misma empresa utilizando `UNION ALL`, consolidando una sola cuenta de cobro global a nombre de la entidad jurídica.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_empresa_id` | `VARCHAR(36)` | ID de la empresa contratante. |

### 3.3. `AplicarRecargosMora`
**Propósito:** Actualiza el `total` y `saldo_pendiente` de facturas vencidas incrementándolo con un recargo porcentual como penalidad (interés de mora). Posee una protección `NOT LIKE` para evitar bucles o aplicación cíclica del recargo.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_dias_atraso` | `INT` | Días mínimos que deben transcurrir tras el vencimiento para multar. |
| `p_porcentaje_recargo` | `DECIMAL(5,2)` | Valor decimal del recargo (Ej. `0.10` para un 10%). |

### 3.4. `BloquearServiciosPorDeuda`
**Propósito:** Restringe de forma automatizada los servicios adicionales y amenidades de todos los usuarios vinculados a facturas en mora, cambiándolos a `BLOQUEADO` y registrando el incidente para el equipo de atención al cliente.

*No requiere parámetros.*

---

## 🛡️ 4. Módulo de Accesos y Asistencias

### 4.1. `RegistrarAccesoEntrada`
**Propósito:** Control físico/digital en la puerta. Valida si el usuario tiene privilegios de ingreso verificando si cuenta con: (A) Una membresía `ACTIVA` o (B) Una reserva `CONFIRMADA` programada en el horario y fecha actuales. En caso afirmativo, estampa su hora de `ENTRADA` en la bitácora de asistencia.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_usuario_id` | `VARCHAR(36)` | ID del usuario frente a la terminal/puerta. |
| `p_espacio_id` | `VARCHAR(36)` | ID del espacio o sucursal donde se escanea el acceso. |

### 4.2. `RegistrarAccesoSalida`
**Propósito:** Cierra el ciclo de asistencia. Busca en la bitácora (`ORDER BY fecha DESC LIMIT 1`) el último registro de `ENTRADA` abierto de un usuario y estampa su hora de `SALIDA`.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_usuario_id` | `VARCHAR(36)` | ID del usuario que finaliza su permanencia. |

### 4.3. `GenerarReporteDiarioAsistencia`
**Propósito:** Resumen analítico gerencial (BI) que mediante funciones de agregación y subconsultas determina: Total de ingresos brutos, total de usuarios únicos (Reach) y calcula en qué hora exacta operó el máximo tráfico.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_fecha` | `DATE` | Día en calendario a evaluar y reportar. |

### 4.4. `DetectarNoShow`
**Propósito:** Procedimiento financiero y de control. Combina la tabla de reservas y el log de asistencias (`LEFT JOIN ... IS NULL`). Si el sistema descubre una reserva pasada donde el usuario jamás tuvo un registro de entrada, la clasifica como `NOSHOW` y le inyecta una penalidad (multa) automática del 20% en sus servicios.

*No requiere parámetros.*

---

## 💼 5. Módulo Corporativo y de Administración

### 5.1. `RegistrarLoteEmpleados`
**Propósito:** Facilita la adopción corporativa. Crea un nuevo usuario y lo vincula directamente a una empresa asumiendo el rol de `EMPLEADO`. De forma paralela y atómica, le asigna una membresía `ACTIVA` con un mes de vigencia por defecto.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_empresa_id` | `VARCHAR(36)` | ID de la compañía empleadora. |
| `p_nombre_empleado` | `VARCHAR(100)` | Nombre completo de la nueva cuenta. |
| `p_email_empleado` | `VARCHAR(100)` | Correo de registro (generalmente corporativo). |
| `p_membresia_tipo_id` | `VARCHAR(36)` | ID del plan a asignar masivamente. |

### 5.2. `CancelarReservasFuturasUsuario`
**Propósito:** Limpieza de privilegios ("Off-boarding"). Cuando a un usuario se le revoca su membresía, este script detecta y libera automáticamente todas las reservas `PENDIENTE` o `CONFIRMADA` que haya hecho a futuro, retornando la disponibilidad del espacio al negocio.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_usuario_id` | `VARCHAR(36)` | ID del usuario al que se le aplicará la revocación. |
| `p_motivo` | `VARCHAR(255)` | Razón de la limpieza sistémica de sus apartados. |

### 5.3. `GenerarReporteIngresosAnuales`
**Propósito:** Herramienta financiera de alto nivel. Mediante el uso inteligente de subconsultas correlacionadas, este reporte lista los ingresos totales por mes de un año y va construyendo simultáneamente una métrica de "Ingresos Acumulados Anuales" (Running Total) vital para las decisiones gerenciales.

**Parámetros:**
| Parámetro | Tipo | Descripción |
| :--- | :--- | :--- |
| `p_anio` | `INT` | Año fiscal a consultar y reportar (Ej. `2026`). |

---

*Documentación autogenerada para el ecosistema de base de datos MySQL.*