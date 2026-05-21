# Hora Dorada Prop House — Manual de Sistema
**Versión 1.0 · Mayo 2026**  
**Autor:** Ana Luisa Martínez · Materia Marte  
**Contacto:** analuisamg97@gmail.com · 81 1717 0541

---

## Índice

1. [El negocio](#1-el-negocio)
2. [Arquitectura del sistema](#2-arquitectura-del-sistema)
3. [Base de datos — Airtable](#3-base-de-datos--airtable)
4. [La app — Hora Dorada Scanner](#4-la-app--hora-dorada-scanner)
5. [Paleta de colores y estilos](#5-paleta-de-colores-y-estilos)
6. [Automatizaciones](#6-automatizaciones)
7. [Credenciales y accesos](#7-credenciales-y-accesos)
8. [Pendientes y roadmap](#8-pendientes-y-roadmap)

---

## 1. El negocio

### ¿Qué es Hora Dorada Prop House?
Hora Dorada es una prop house boutique cinematográfica y editorial ubicada en Monterrey, México. Opera como negocio de renta de props para producciones audiovisuales, campañas, videoclips y contenido editorial.

**Operada por:** Ana Luisa Martínez — directora de arte y diseñadora de producción (Materia Marte)

**Estéticas del inventario:**
- Cinematic Office
- Retro Tech
- Nostálgico
- Weird/Editorial
- Smoker Lounge
- Airport Waiting
- Domestic Realism
- Vintage Texture

### Glosario de términos

| Término | Definición |
|---|---|
| **Prop** | Objeto físico disponible para renta |
| **Renta** | Acuerdo de préstamo de uno o más props por fechas determinadas |
| **Salida** | Momento físico en que los props salen de la bodega |
| **Entrada** | Momento físico en que los props regresan a la bodega |
| **Orden de renta** | Documento PDF con términos, props, precios y firmas |
| **Monto Adelanto** | Pago parcial o total recibido antes o durante la renta |
| **Monto liquidación** | Pago final para completar el total de la renta |
| **Monto a liquidar** | Campo fórmula en Airtable: Monto total - Monto Adelanto |
| **Nivel Visual** | Importancia del prop en una producción (Hero/Supporting/Utility/Background/Funcional) |
| **Última verificación física** | Timestamp que se actualiza cada vez que se escanea o consulta un prop |
| **Gasto fijo** | Costo que se repite cada mes (bodega, suscripciones, etc.) |
| **Gasto variable** | Costo que ocurre según necesidad (materiales, transporte, etc.) |

### Flujo de operación típico

```
1. Cliente contacta → se crea en tabla CLIENTES
2. Se acuerdan props, fechas y precio → Nueva Renta en la app
3. Se genera Orden de Renta (PDF con términos y datos)
4. Cliente firma y paga adelanto → se registra en Pagos
5. Día de salida → flujo de Salida en la app (props → "Rentado")
6. Día de regreso → flujo de Entrada en la app (props → "Disponible")
7. Se registra liquidación si aplica
8. Si hay daños → se registran en Daños, prop → "En reparación"
```

### Política de precios — días cobrados

La lógica de cobro de días es:

```
días reales = fecha_regreso - fecha_salida
días cobrados = máximo(1, días reales - 1)
```

**Ejemplos:**
- Sale lunes, regresa miércoles = 2 días calendario → **cobra 1 día**
- Sale lunes, regresa jueves = 3 días calendario → **cobra 2 días**
- Sale y regresa el mismo día → **cobra 1 día (mínimo)**

### Política de cancelación

- Cancelación con **más de 48hrs** de anticipación → estado "Cancelada", sin cargo
- Cancelación con **menos de 48hrs** de anticipación → estado "Cancelada con cargo", adelanto retenido

---

## 2. Arquitectura del sistema

### Herramientas en uso

| Herramienta | Función | Estado |
|---|---|---|
| **Airtable** | Base de datos central | ✅ Activo |
| **GitHub Pages** | Hosting de la app | ✅ Activo |
| **La app (HTML/JS)** | Interfaz de operación | ✅ Activo |
| **Make/Integromat** | Automatizaciones futuras | 🔜 Pendiente |
| **Imgbb** | Hosting de fotos de props | 🔜 Pendiente |

### Cómo se conectan

```
┌─────────────────────────────────────────────┐
│             Ana Luisa (operadora)            │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│         App Hora Dorada (GitHub Pages)       │
│   prophouse_scanner.html                    │
│   URL: analuisamg97.github.io/prophouse/    │
└──────────────────┬──────────────────────────┘
                   │ API calls (fetch)
                   │ Bearer Token
                   ▼
┌─────────────────────────────────────────────┐
│            Airtable API v0                   │
│   Base ID: appmSGpYKnIlQvHW7               │
│   6 tablas: INVENTARIO, RENTAS, CLIENTES,   │
│   DAÑOS, UBICACIONES, GASTOS                │
└─────────────────────────────────────────────┘
```

### Credenciales de la app

La app guarda las credenciales en `localStorage` del navegador del dispositivo. Nunca se transmiten a ningún servidor externo salvo Airtable.

- `ph_token` → Personal Access Token de Airtable
- `ph_base` → Base ID de Airtable
- `hd_pin` → PIN de 4 dígitos para la sección de Finanzas

---

## 3. Base de datos — Airtable

**Base ID:** `appmSGpYKnIlQvHW7`

### Tabla: INVENTARIO

Registro central de todos los props.

| Campo | Tipo | Descripción |
|---|---|---|
| Nombre del prop | Texto | Nombre descriptivo del prop |
| Código único | Texto | ID del prop (ej. RT-001). Ver sistema de códigos |
| Categoría | Select | Categoría del prop |
| Mood/Estética | Select | Estética visual del prop (se llena en Airtable) |
| Estado | Select | Disponible / Rentado / En reparación / En mantenimiento / Baja |
| Ubicación | Link → UBICACIONES | Zona física en bodega |
| Foto principal | Attachment | Foto del prop (pendiente integración Imgbb) |
| Notas cinematográficas | Texto | Notas de uso creativo |
| Renta x 1 día | Número | Precio de renta por día en MXN |
| Valor de reposición | Número | Costo real de reposición |
| Nivel Visual | Select | Hero / Supporting / Utility / Background / Funcional |
| Costo reposición cliente | Fórmula | Valor de reposición × multiplicador según nivel |
| Notas de mantenimiento | Texto | Estado físico y mantenimiento |
| Veces rentado | Número | Contador de rentas |
| Última verificación física | DateTime | Timestamp del último escaneo o consulta |
| Fecha de adquisición | Fecha | Cuándo se adquirió el prop |
| RENTAS | Link → RENTAS | Rentas en que ha participado |
| DAÑOS | Link → DAÑOS | Daños registrados |

**Sistema de códigos de inventario:**

| Prefijo | Categoría |
|---|---|
| MU | Mueble |
| RT | Retro Tech |
| PP | Props Pequeños |
| LT | Light |
| DC | Decoración |
| AR | Arte |
| VT | Vintage |
| WE | Weird/Editorial |
| OF | Office Props |
| FU | Funcionales |
| SOL | Verano |

**Fórmula de costo de reposición al cliente:**
```
IF(Nivel Visual = "Hero", Valor de reposición × 2.5,
IF(Nivel Visual = "Supporting", Valor de reposición × 2,
IF(Nivel Visual = "Utility", Valor de reposición × 1.5,
IF(Nivel Visual = "Background", Valor de reposición × 1.2))))
```

**Niveles Visuales:**
- **Hero** — protagonista de la toma, más difícil de reemplazar
- **Supporting** — apoya al hero, tiene carácter visual
- **Utility** — funcional con estética, no busca protagonismo
- **Background** — relleno de calidad, da textura y profundidad
- **Funcional** — uso práctico, sin rol visual

### Tabla: RENTAS

Registro de todas las rentas.

| Campo | Tipo | Descripción |
|---|---|---|
| ID de renta | Texto | Formato RNT-2026-001, generado automáticamente |
| Fecha de salida | Fecha | Día en que salen los props |
| Fecha de regreso | Fecha | Día en que regresan los props |
| Monto total | Número | Total calculado de la renta |
| Monto Adelanto | Número | Pago recibido como adelanto |
| Fecha de adelanto | Fecha | Fecha en que se recibió el adelanto (automática) |
| Monto liquidación | Número | Pago de liquidación final |
| Fecha de liquidación | Fecha | Fecha en que se recibió la liquidación (automática) |
| Monto a liquidar | Fórmula | Monto total - Monto Adelanto |
| Estado del pago | Select | Pendiente / Adelanto depositado / Pagado |
| Estado de la renta | Select | Activa / Cerrada / Finalizada / Cancelada / Cancelada con cargo |
| Fecha de cancelación | Fecha | Si aplica |
| Notas | Texto | Notas generales de la renta |
| Fecha de registro | Fecha | Fecha en que se creó en el sistema |
| Cliente | Link → CLIENTES | Cliente de la renta |
| Props rentados | Link → INVENTARIO | Props incluidos en la renta |
| DAÑOS | Link → DAÑOS | Daños ocurridos en esta renta |

**Lógica de Estado del pago:**
```
Sin pagos → "Pendiente"
Adelanto > 0, falta saldo → "Adelanto depositado"
Adelanto + Liquidación ≥ Monto total → "Pagado"
```

### Tabla: CLIENTES

| Campo | Tipo | Descripción |
|---|---|---|
| Nombre o empresa | Texto | Nombre del cliente o productora |
| Contacto principal | Texto | Nombre de la persona de contacto |
| Email | Email | Correo electrónico |
| Teléfono | Texto | Número de contacto |
| Tipo de cliente | Select | Tipo de cliente |
| Origen | Select | Instagram / Recomendación / Otro |
| Notas | Texto | Notas generales |
| Ciudad | Texto | Ciudad del cliente |
| Empresa registrada | Texto | Razón social si factura |
| Clasificación | Select | VIP / Recurrente / Nuevo / etc. |
| RENTAS | Link → RENTAS | Historial de rentas |
| DAÑOS | Link → DAÑOS | Daños relacionados |

### Tabla: DAÑOS

| Campo | Tipo | Descripción |
|---|---|---|
| ID daño | Texto | Formato DMG-RNT2026001-01, generado automáticamente |
| Prop afectado | Link → INVENTARIO | Prop que sufrió el daño |
| Renta relacionada | Link → RENTAS | Renta en que ocurrió |
| Cliente relacionado | Link → CLIENTES | Cliente responsable |
| Descripción del daño | Texto | Descripción detallada |
| Fotos del daño | Attachment | Fotos del daño |
| Costo de reparación | Número | Costo estimado (opcional al momento de registrar) |
| Estado del cobro | Select | Pendiente / Cobrado / Absorbido |
| Fecha del reporte | Fecha | Generada automáticamente al registrar |

**ID de daño — formato:**
```
DMG-[número de renta sin guiones]-[consecutivo]
Ejemplo: DMG-RNT2026001-01
```

### Tabla: UBICACIONES

| Campo | Tipo | Descripción |
|---|---|---|
| Nombre ubicación | Texto | Nombre de la zona |
| Código de ubicación | Texto | Código corto (A-MUEBLES, B-E1, C-CJ01, D-DELICADOS) |
| Tipo de espacio | Select | Tipo de área |
| Zona | Select | Zona en bodega |
| Props aquí | Link → INVENTARIO | Props en esta ubicación |
| Foto del espacio | Attachment | Foto de la zona |
| Capacidad aproximada | Número | Capacidad estimada |
| Notas | Texto | Notas de la ubicación |

**Zonas de bodega** (contenedor 3×2.35m, 2.45m alto, 7m²):
- **Zona A** — Muebles grandes (pared/piso)
- **Zona B** — Rack negro 5 estantes (Retro Tech + Office Props)
- **Zona C** — Cajas negras con tapa amarilla (props pequeños, decoración)
- **Zona D** — Props delicados con burbuja wrap
- **Mesa staging** — revisión de props antes de salida/entrada

### Tabla: GASTOS

| Campo | Tipo | Descripción |
|---|---|---|
| Nombre | Texto | Descripción del gasto |
| Monto | Número/Moneda | Monto en MXN |
| Tipo | Select | Fijo / Variable |
| Categoría | Select | Bodega / Materiales / Transporte / Asistentes / Suscripciones / Mi tiempo / Otro |
| Fecha | Fecha | Fecha del gasto |
| Mes | Fórmula | `DATETIME_FORMAT(Fecha, 'YYYY-MM')` — para filtrar por mes |
| Notas | Texto | Notas opcionales |
| Recurrente | Checkbox | Si es un gasto que se repite mensualmente |

---

## 4. La app — Hora Dorada Scanner

**URL:** `https://analuisamg97.github.io/prophouse/prophouse_scanner.html`  
**Repositorio:** `github.com/analuisamg97/prophouse`  
**Tecnología:** HTML + CSS + JavaScript puro (sin frameworks)  
**Librería QR:** Html5Qrcode (cdnjs)

### Estructura de archivos

```
prophouse/
├── prophouse_scanner.html   ← La app completa (todo en un archivo)
└── HORA_DORADA_MANUAL.md   ← Este documento
```

### Navegación — Menú inferior

La app tiene 4 tabs en el menú inferior fijo:

| Tab | Ícono | Contenido |
|---|---|---|
| Inicio | 🏠 | Salida, Entrada, Consultar, Nueva renta, Registrar pago, Registrar daño |
| Inventario | 📦 | Consultar prop, Alta de prop, Inventario físico, Registrar daño |
| Rentas | 📋 | Nueva renta, Rentas activas, Generar orden de renta, Registrar pago |
| Finanzas | 💰 | Ingresos, Gastos, Ganancia del mes (protegida con PIN) |

### Pantallas de la app

#### Inicio (Home)
- Muestra fecha actual
- 4 tiles de acción: Salida, Entrada, Consultar, Nueva renta
- Acciones rápidas: Registrar pago, Registrar daño

#### Salida / Entrada
1. Seleccionar modo (Salida o Entrada)
2. Seleccionar renta de la lista
3. Escanear props por QR o buscar por código
4. Confirmar salida/entrada completa
- Al escanear: actualiza Estado del prop + escribe timestamp en `Última verificación física`

#### Consultar prop
- Buscar por código o escanear QR
- Muestra toda la info del prop
- Permite cambiar el estado del prop directamente (botones de estado)
- Al consultar: escribe timestamp en `Última verificación física`

#### Nueva renta
1. Seleccionar o crear cliente (nombre, teléfono, email, origen)
2. Definir fechas de salida y regreso
3. Agregar props por código o QR → calcula monto automáticamente
4. Registrar adelanto si aplica
5. Crear renta → aparece en tabla RENTAS de Airtable
6. Opción de generar orden de renta directamente

#### Rentas activas
- Lista de todas las rentas con cliente, saldo y estado de pago
- Tap en una renta → ver detalle completo con props
- Botones de: Generar orden, Registrar pago, Cancelar renta

#### Generar orden de renta
- Seleccionar renta existente de la lista
- Genera documento PDF con:
  - Datos del cliente
  - Props rentados con precios
  - Totales, adelanto y saldo
  - Datos bancarios para pago
  - 8 cláusulas de términos y condiciones
  - Espacio para firmas
- Botón WhatsApp: envía resumen de la orden
- Botón PDF: imprime / guarda como PDF

#### Registrar pago
- Seleccionar renta
- Ingresar Monto Adelanto y/o Monto liquidación
- Fechas se registran automáticamente (fecha de hoy)
- Estado del pago se actualiza automáticamente en Airtable
- Preview en tiempo real del estado resultante

#### Dar de alta prop
- Nombre del prop
- Categoría (genera código automático, ej. RT-008)
- Estado inicial
- Nivel visual (botones)
- Precio de renta por día
- Valor de reposición
- Se guarda en tabla INVENTARIO de Airtable

#### Inventario físico
- Modo de verificación rápida
- Escribes o escaneas códigos uno por uno
- Barra de progreso del inventario
- Cada prop verificado → actualiza timestamp en Airtable

#### Registrar daño
- Buscar prop por código o QR
- Seleccionar renta relacionada (muestra cliente automáticamente)
- Describir el daño
- Costo de reparación (opcional)
- Al guardar:
  - Crea registro en tabla DAÑOS con ID automático
  - Cambia estado del prop a "En reparación" automáticamente

#### Finanzas (protegida con PIN)
- Selector de mes con flechas
- Flashcards: Ingresos del mes, Gastos del mes, Ganancia
- Indicador de punto de equilibrio
- Lista de gastos agrupada por categoría
- Botón registrar gasto nuevo

#### Registrar gasto
- Nombre, tipo (Fijo/Variable), categoría
- Monto, fecha, notas
- Checkbox de recurrente
- Se guarda en tabla GASTOS de Airtable

### Capa central de datos (API functions)

Todas las llamadas a Airtable pasan por funciones centralizadas. Si cambia un campo en Airtable, solo se edita en un lugar:

```javascript
// CLIENTES
db_getClientes()              // Cargar lista
db_crearCliente({...})        // Crear nuevo
db_buscarOCrearCliente({...}) // Buscar o crear

// RENTAS
db_getRentas({...})           // Listar con filtros
db_getRenta(recordId)         // Una por ID
db_generarRentaId()           // Siguiente RNT-2026-XXX
db_crearRenta({...})          // Crear con todos los campos
db_calcEstadoPago(...)        // Calcular estado según montos
db_registrarPago({...})       // Actualizar pagos en Airtable

// INVENTARIO
db_getProps()                 // Todos, paginado
db_getProp(recordId)          // Uno por record ID
db_crearProp(fields)          // Crear nuevo
db_actualizarEstadoProps(...) // Cambiar estado en lote
findPropByCode(codigo)        // Buscar por código único

// GASTOS
airtableGet('GASTOS', ...)    // Cargar gastos
airtablePost('GASTOS', ...)   // Registrar gasto
```

### Scanner QR

El botón 📷 está disponible en **todos** los campos de búsqueda de props:
- Consultar prop
- Nueva renta (agregar props)
- Inventario físico
- Registrar daño
- Orden de renta
- Salida/Entrada

Usa la librería `Html5Qrcode` — abre la cámara trasera del dispositivo.

---

## 5. Paleta de colores y estilos

### Variables CSS — Paleta Tabaco

```css
:root {
  --black: #1c1410;        /* Fondo principal — café oscuro */
  --black-deep: #141008;   /* Fondo más profundo (nav, header) */
  --gray: #241c14;         /* Fondo de tarjetas */
  --gray-light: #2e2018;   /* Bordes y divisores */
  --gray-mid: #3a2e20;     /* Bordes de énfasis */
  --white: #d4c4a8;        /* Texto principal */
  --white-bright: #f0e8d8; /* Texto de énfasis */
  --gold: #c9a84c;         /* Color de marca — dorado */
  --gold-dim: #8a6f2e;     /* Dorado atenuado */
  --red: #c0392b;          /* Salidas, errores */
  --green: #27ae60;        /* Entradas, éxito */
  --blue: #2980b9;         /* Nueva renta, info */
  --text-dim: #6b5a40;     /* Texto secundario — tabaco */
  --text-mid: #9a8060;     /* Texto medio */
}
```

### Tiles de acción — fondos

```css
.action-card.salida  { background: #3d1a18; border-color: #c0392b44; } /* Rojo oscuro */
.action-card.entrada { background: #1a2e1e; border-color: #27ae6044; } /* Verde oscuro */
.action-card.buscar  { background: #2e2618; border-color: #c9a84c44; } /* Dorado oscuro */
.action-card.nueva   { background: #1a2030; border-color: #2980b944; } /* Azul oscuro */
```

### Tipografía

```css
/* Principal — monoespaciada para look operacional */
font-family: 'DM Mono', monospace;

/* Títulos y logo — serif elegante */
font-family: 'Playfair Display', serif;

/* Importar desde Google Fonts */
@import url('https://fonts.googleapis.com/css2?family=DM+Mono:wght@300;400;500&family=Playfair+Display:ital,wght@0,400;0,700;1,400&display=swap');
```

### Componentes principales

```css
/* Botón primario */
.btn-accion {
  background: #241c14;
  border: 1px solid #2e2018;
  border-radius: 8px;
  padding: 14px 16px;
  color: var(--white);
  font-family: 'DM Mono', monospace;
}

/* Botón dorado */
.btn-accion.gold {
  background: var(--gold);
  color: #1c1410;
  border: none;
}

/* Inputs */
.alta-input, .setup-input, .search-input {
  background: #241c14;
  border: 1px solid #2e2018;
  border-radius: 4px;
  color: var(--white);
  font-family: 'DM Mono', monospace;
  padding: 11px 14px;
}

/* Menú inferior */
.bottom-nav {
  position: fixed;
  bottom: 0;
  background: #141008;
  border-top: 1px solid #2e2018;
}
```

### Badges de estado

```css
.mode-salida  { background: rgba(192,57,43,0.15);  color: #e74c3c; border: 1px solid #c0392b44; }
.mode-entrada { background: rgba(39,174,96,0.15);  color: #2ecc71; border: 1px solid #27ae6044; }
.mode-buscar  { background: rgba(201,168,76,0.15); color: #c9a84c; border: 1px solid #c9a84c55; }
```

---

## 6. Automatizaciones

### Lo que la app hace automáticamente

| Acción del usuario | Lo que pasa en Airtable automáticamente |
|---|---|
| Escanear prop en Salida | Estado → "Rentado" + timestamp `Última verificación física` |
| Escanear prop en Entrada | Estado → "Disponible" + timestamp `Última verificación física` |
| Consultar prop por código | Timestamp `Última verificación física` actualizado |
| Escanear en Inventario físico | Timestamp `Última verificación física` actualizado |
| Registrar daño | Estado del prop → "En reparación" + registro en DAÑOS con ID automático + fecha automática |
| Cancelar renta | Calcula si <48hrs → "Cancelada con cargo" o "Cancelada" + fecha de cancelación |
| Crear nueva renta | ID RNT-2026-XXX generado automáticamente + cliente linkeado + props linkeados |
| Registrar pago (adelanto) | Fecha de adelanto automática + Estado del pago recalculado |
| Registrar pago (liquidación) | Fecha de liquidación automática + Estado del pago recalculado |
| Dar de alta prop | Código único generado automáticamente según categoría (RT-XXX, MU-XXX, etc.) |
| Crear cliente nuevo | Se guarda en tabla CLIENTES con origen |

### Seguridad — PIN de Finanzas

La sección de Finanzas está protegida con PIN de 4 dígitos:

```
Primera vez:
  → Pide PIN maestro (solo Ana Luisa lo sabe)
  → Si correcto → crear PIN personal
  → Confirmación → acceso a Finanzas

Uso normal:
  → Pide PIN personal → acceso

Cambiar PIN:
  → Desde pantalla de PIN → "Cambiar PIN"
  → Pide PIN maestro → crear nuevo PIN
```

El PIN se guarda en `localStorage` del dispositivo bajo la clave `hd_pin`. La sesión de Finanzas se cierra al tocar 🔒 o al salir de la sección.

---

## 7. Credenciales y accesos

> ⚠️ **Este documento NO debe contener contraseñas ni tokens.** Los accesos sensibles se guardan en el gestor de contraseñas personal de Ana Luisa.

### Dónde está cada cosa

| Qué | Dónde |
|---|---|
| Airtable Personal Access Token | Guardado en localStorage de la app + gestor de contraseñas |
| Airtable Base ID | `appmSGpYKnIlQvHW7` |
| GitHub usuario | `analuisamg97` |
| GitHub repo | `github.com/analuisamg97/prophouse` |
| URL de la app | `https://analuisamg97.github.io/prophouse/prophouse_scanner.html` |
| Email de contacto (temporal) | `analuisamg97@gmail.com` |
| Teléfono (temporal) | `81 1717 0541` |
| Banco | Banamex |
| CLABE | Por definir |
| PIN de Finanzas | Solo Ana Luisa |

### Permisos necesarios del token de Airtable

El Personal Access Token debe tener estos permisos en Airtable:
- `data.records:read`
- `data.records:write`
- `schema.bases:read`

### Cómo actualizar la app

1. Editar `prophouse_scanner.html` localmente o en `vscode.dev`
2. Ir a `github.com/analuisamg97/prophouse`
3. Subir el archivo actualizado (upload / commit)
4. Esperar 1-2 minutos para que GitHub Pages publique
5. Forzar recarga en el navegador: `Cmd+Shift+R` (Mac) o mantener el botón de recarga (iPhone)

---

## 8. Pendientes y roadmap

### 🔴 En progreso

- [ ] Facturación — IVA 16% en orden de renta + campos RFC del cliente
- [ ] Verificar bugs reportados (liquidación, timestamp, crear cliente)

### 🟡 Prioridad media

- [ ] Catálogo web — página con fotos, precios y botón WhatsApp (Opción A)
- [ ] Rentas largas — precio semanal/mensual además del diario
- [ ] Descuentos por cliente recurrente — campo `% descuento` en CLIENTES
- [ ] Sistema de recordatorios — evaluar WhatsApp vs email vs Make para fechas de regreso
- [ ] RFC y datos fiscales del cliente para facturación

### 🟢 Para después

- [ ] Documento orden de renta — revisar y editar contenido del PDF
- [ ] QR físicos — generar e imprimir etiquetas para todos los props del inventario
- [ ] Fotos de props — integración con Imgbb (API gratuita)
- [ ] Sets/insumos consumibles — agrupar props que se consumen
- [ ] Multiusuario — permisos por sección cuando haya equipo
- [ ] Cerrar daño — flujo para cambiar prop de "En reparación" a "Disponible"
- [ ] Dashboard financiero más completo — punto de equilibrio, rentabilidad por prop

### 📋 Decisiones pendientes

- [ ] CLABE interbancaria Banamex para la orden de renta
- [ ] Email y teléfono profesionales (reemplazar gmail y número personal)
- [ ] Dominio propio (en lugar de github.io)
- [ ] Nombre de titular para datos bancarios en la orden de renta

---

*Documento generado en mayo 2026. Actualizar con cada cambio significativo al sistema.*
