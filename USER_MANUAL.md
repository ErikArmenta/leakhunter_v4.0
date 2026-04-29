# 🏭💧 Leak Hunter Digital Twin v4.2 — Manual de Usuario

**Sistema Integral de Gestión, Auditoría y Control de Fugas Industriales**

> *"Accuracy is our signature, and innovation is our nature."*
> — Erik Armenta, M.Eng.

---

## Tabla de Contenidos

1. [Introducción](#1-introducción)
2. [Requisitos del Sistema](#2-requisitos-del-sistema)
3. [Acceso al Sistema](#3-acceso-al-sistema)
4. [Navegación Principal](#4-navegación-principal)
5. [Vista de Mapa Interactivo](#5-vista-de-mapa-interactivo)
6. [Vista de Gestión](#6-vista-de-gestión)
7. [Vista de Reportes](#7-vista-de-reportes)
8. [Administración de Usuarios](#8-administración-de-usuarios)
9. [Sistema de Filtros](#9-sistema-de-filtros)
10. [Exportaciones y Reportes](#10-exportaciones-y-reportes)
11. [Modelo Económico Dinámico](#11-modelo-económico-dinámico)
12. [Métricas de Consumo Acumulado](#12-métricas-de-consumo-acumulado)
13. [Preguntas Frecuentes](#13-preguntas-frecuentes)
14. [Soporte Técnico](#14-soporte-técnico)

---

## 1. Introducción

**Leak Hunter Digital Twin v4.2** es una plataforma de auditoría industrial de última generación diseñada para la detección, registro, seguimiento y análisis económico de fugas en plantas industriales. La aplicación opera como un **Gemelo Digital** del plano físico de la planta, permitiendo a los ingenieros de mantenimiento y operaciones visualizar en tiempo real el estado de cada hallazgo sobre el mapa maestro de la instalación.

### ¿Qué problemas resuelve?

| Problema Industrial | Solución Leak Hunter |
|---|---|
| Fugas no documentadas | Registro georreferenciado con evidencia fotográfica |
| Impacto económico desconocido | Modelo de taxímetro dinámico que calcula el costo acumulado por minuto |
| Falta de trazabilidad | Historial completo con línea de tiempo (auditoría) |
| Reportes manuales | Generación automática de PDF ejecutivo y Excel |
| Datos dispersos | Dashboard centralizado con KPIs en tiempo real |
| Saturación visual en mapas con muchas fugas | Agrupamiento inteligente con Marker Clustering |

### Tipos de Fluidos Soportados

| Fluido | Emoji | Unidad de Consumo | Descripción |
|---|---|---|---|
| **Aire** | 💨 | kWh | Fugas de aire comprimido. Se calcula el impacto en consumo eléctrico. |
| **Gas Natural** | 🔥 | m³ | Fugas de gas natural. Se calcula el volumen acumulado en metros cúbicos. |
| **Agua** | 💧 | m³ | Fugas de agua industrial. Se calcula el volumen acumulado en metros cúbicos. |
| **Helio** | 🎈 | m³ | Fugas de helio industrial. Se calcula el volumen acumulado en metros cúbicos. |
| **Aceite** | 🛢️ | Lts | Fugas de aceite hidráulico/lubricante. Se calcula el consumo acumulado en litros. |
| **Inspección (OK)** | ✅ | — | Zona inspeccionada sin hallazgos. |

---

## 2. Requisitos del Sistema

### Plataformas Soportadas
- **Web**: Navegadores modernos (Chrome, Edge, Firefox, Safari)
- **Windows**: Windows 10/11 (aplicación nativa de escritorio)
- **Móvil**: Android e iOS (en desarrollo)

### Conectividad
- Conexión a Internet requerida para sincronización con la base de datos Supabase.
- Las credenciales de acceso son proporcionadas por el Administrador Principal.

---

## 3. Acceso al Sistema

### Pantalla de Login

Al iniciar la aplicación, se presenta una pantalla de acceso seguro con los siguientes campos:

1. **Usuario**: Ingrese su correo electrónico corporativo.
2. **Contraseña**: Ingrese la contraseña asignada por el Administrador.
3. Presione **"Ingresar"** para acceder al sistema.

> **Nota:** La autenticación se gestiona a través de Supabase Auth con políticas de seguridad a nivel de fila (RLS).

### Roles del Sistema

| Rol | Permisos |
|---|---|
| **Admin Principal** | Acceso total: Mapa, Gestión, Reportes, Administración de Usuarios, Reubicar fugas |
| **Supervisor** | Mapa, Gestión, Reportes |
| **Inspector** | Mapa, Gestión (solo registro) |

---

## 4. Navegación Principal

### Versión Desktop (≥ 800px)

En pantallas de escritorio, Leak Hunter presenta un **panel flotante arrastrable** con las siguientes características:

- **Logo corporativo**: Identidad visual EA Engineering en la parte superior.
- **Selector de Planta**: Dropdown para cambiar entre instalaciones configuradas.
- **NavigationRail vertical**: Iconos de navegación para cada módulo.
- **Filtros integrados**: Panel lateral con filtros avanzados.
- **Botón Ocultar/Mostrar**: Permite colapsar el panel para una vista de mapa sin obstrucciones.
- **Arrastrable**: El panel puede ser reposicionado con clic + arrastrar. Clic derecho lo reposiciona a su ubicación predeterminada.
- **Indicador de versión**: `v4.2` visible en la parte inferior.

### Versión Móvil (< 800px)

En dispositivos móviles o pantallas estrechas:
- **AppBar** superior con el nombre de la planta.
- **NavigationBar** inferior para cambiar entre módulos.
- **Drawer lateral** para acceder a los filtros.

---

## 5. Vista de Mapa Interactivo

### Mapa Maestro de Planta

El corazón de Leak Hunter es el **mapa interactivo CRS Simple** que utiliza un plano de alta resolución de la planta industrial como capa base. Las fugas registradas se superponen como marcadores geolocalizados directamente sobre el plano.

### Marcadores (Pepos)

Cada fuga se representa con un marcador circular que codifica información visual:

- **Emoji del fluido**: 💨 Aire, 🔥 Gas Natural, 💧 Agua, 🎈 Helio, 🛢️ Aceite.
- **Color del borde**: Indica el estado de la fuga.
  - 🟢 Verde: Completada / Inspección OK.
  - 🟡 Amarillo: En proceso de reparar.
  - 🔴 Rojo: Dañada.
- **Animación de rebote**: Las fugas de severidad **Alta** presentan una animación pulsante para máxima visibilidad.
- **Tooltip al hover**: Al pasar el cursor sobre un marcador, se despliega información resumida (Área, Instalación, Severidad, Comentarios).

### Agrupamiento Inteligente (Marker Clustering)

Cuando la vista del mapa está alejada (zoom bajo), las fugas cercanas se **agrupan automáticamente** en clusters:

- **Burbuja oscura con borde azul**: Muestra el número total de fugas agrupadas en esa zona.
- **Al hacer clic** en el cluster: Las fugas se redistribuyen mostrando sus marcadores individuales con sus colores y emojis originales.
- **Al hacer zoom in**: Los clusters se desarman progresivamente revelando los marcadores individuales.
- **Radio de agrupamiento**: 60 píxeles (optimizado para el plano industrial).
- **MaxZoom**: Los clusters se disuelven completamente al alcanzar el nivel de zoom 6.

### Ficha Técnica (Popup)

Al hacer **clic** en cualquier marcador individual, se despliega una ficha técnica completa con:

| Campo | Descripción |
|---|---|
| ID Máquina | Identificador del equipo afectado |
| Área de Planta | Sector donde se ubica la fuga |
| Instalación | Tipo: Terrestre 🚜 o Aérea ☁️ |
| Estado | Dañada, En proceso de reparar, Completada |
| Categoría | Clasificación crítica (Fuga A, B, C, D, E) |
| Caudal | Litros por minuto (l/min) |
| Impacto Acumulado | Costo económico dinámico en USD |
| Consumo Acumulado | Según tipo: m³ (Gas, Agua, Helio), Lts (Aceite), kWh (Aire) |
| Severidad | Baja, Media, Alta (con código de color) |
| Fechas | Rango de detección-reparación y días transcurridos |
| Comentarios | Observaciones del inspector |
| Evidencia Fotográfica | Fotos de detección y reparación |
| Historial | Botón para ver la trazabilidad completa |

### Métricas del Mapa

En la esquina superior derecha del mapa se encuentran tarjetas KPI interactivas:

- **Hallazgos Totales**: Cantidad de fugas en la vista actual.
- **🚨 Prioridad Alta**: Fugas de severidad Alta.
- **💰 Impacto Total**: Suma del costo acumulado de todas las fugas.
- **✅ Ahorro Generado**: Costo acumulado de fugas ya reparadas.
- **⏳ Por Mitigar**: Costo pendiente de fugas sin reparar.

> **Tip:** Cada tarjeta es clicable y abre un diálogo de drill-down con la lista detallada de fugas correspondientes, incluyendo opción de exportar a Excel.

### Zonas de Inspección

Las inspecciones sin hallazgos (`Inspección (OK)`) se visualizan como **polígonos verdes semitransparentes** sobre el mapa, indicando áreas ya revisadas.

---

## 6. Vista de Gestión

### Panel de Registro de Fugas

Esta vista permite registrar nuevas fugas directamente sobre el mapa maestro:

#### Paso 1: Seleccionar ubicación
1. Haz **clic izquierdo** en el mapa para colocar el **punto 1** (esquina del rectángulo).
2. Haz un **segundo clic** para colocar el **punto 2** (esquina opuesta).
3. Se dibujará un rectángulo azul semitransparente indicando la zona seleccionada.
4. Presiona **ESC** en cualquier momento para cancelar la selección.

#### Paso 2: Llenar el formulario
El formulario se organiza en 3 columnas:

**Columna 1 — Clasificación:**
- Fluido (Aire, Gas Natural, Agua, Helio, Aceite, Inspección OK)
- Fecha de Inicio
- Fecha Estimada de Término
- Categoría Crítica (autoseleccionada según el fluido)

**Columna 2 — Identificación:**
- ID Equipo / Máquina
- Área de Planta
- l/min (calculado automáticamente según la categoría)

**Columna 3 — Estado:**
- Severidad Visual (Baja, Media, Alta)
- Costo por año USD (calculado automáticamente)
- Tipo de Instalación (Terrestre, Aérea)
- Estado Inicial (En proceso, Dañada, Completada)

#### Paso 3: Evidencia fotográfica
- **📷 Evidencia de Detección**: Captura o selecciona una foto/video del hallazgo.
- **📷 Evidencia de Reparación**: Captura o selecciona una foto/video post-reparación.
- Límite: 10 MB por archivo.

#### Paso 4: Registrar
- Presiona **"🚰📝 Registrar fuga"** para guardar en la base de datos.

### Modo Reubicar Fugas (Solo Admin)

Los administradores pueden activar el **Modo Reubicar**:
1. Activa el switch "📍 Modo Reubicar Fugas".
2. Haz clic derecho o mantén presionado sobre una fuga existente para seleccionarla.
3. Haz clic izquierdo en la nueva ubicación deseada.
4. La fuga se reposiciona automáticamente.

### Historial de Gestión

Debajo del formulario se presenta una grilla paginada (20 por página) con todas las fugas registradas, permitiendo:
- **Editar**: Modificar cualquier campo de una fuga existente.
- **Eliminar**: Borrar una fuga (con confirmación).
- **Ver Detalles**: Expandir la información completa.

---

## 7. Vista de Reportes

### Panel de Control Operativo

Esta vista ofrece un dashboard ejecutivo completo con:

#### KPIs Principales
Cinco tarjetas de indicadores clave de rendimiento:

| KPI | Descripción | Color |
|---|---|---|
| **Hallazgos** | Número total de fugas registradas | 🔵 Azul |
| **Impacto Total** | Suma del costo acumulado (formato con separador de miles) | 🔴 Rojo |
| **Ahorro Generado** | Costo acumulado de fugas reparadas (formato $X,XXX) | 🟢 Verde |
| **Reparaciones** | Cantidad de fugas en estado Completada | 🟢 Verde claro |
| **Eficiencia** | Porcentaje de reparaciones vs total | 🟠 Naranja |

#### Gráficas de Análisis

1. **📈 Historial de Reparaciones**: Gráfica de barras agrupadas por mes mostrando la evolución temporal.
2. **📊 Comparativa Detección vs Reparación**: Análisis mensual cruzado.
3. **📊 Análisis de Hallazgos** (5 gráficas de dona):
   - Severidad (Baja, Media, Alta)
   - Estatus (Dañada, En proceso, Completada)
   - Impacto Económico por tipo de fluido
   - Eficiencia de Reparación
   - Cobertura de Inspección
4. **🚨 Top Sectores Críticos**: Ranking de las áreas con mayor impacto económico.
5. **Mapa de Calor**: Heatmap visual de concentración de fugas.

---

## 8. Administración de Usuarios

*(Acceso exclusivo para Admin Principal)*

Esta vista permite gestionar los usuarios del sistema:
- **Crear usuarios**: Registrar nuevos inspectores, supervisores o administradores.
- **Editar roles**: Cambiar el nivel de permisos de un usuario.
- **Desactivar cuentas**: Inhabilitar el acceso a usuarios.

---

## 9. Sistema de Filtros

El panel de filtros está disponible en todas las vistas y permite refinar los datos mostrados:

- **Tipo de Fluido**: Filtrar por uno o varios tipos de fuga.
- **Severidad**: Baja, Media, Alta.
- **Estado**: Dañada, En proceso de reparar, Completada.
- **Área de Planta**: Filtrar por sector específico.
- **Rango de Fechas**: Filtrar por período temporal.

> **Nota:** Los filtros se aplican de manera reactiva e instantánea gracias a la arquitectura Riverpod. Cualquier cambio actualiza automáticamente el mapa, la gestión y los reportes.

---

## 10. Exportaciones y Reportes

### Centro de Reportes

Desde la vista de Reportes, sección "📥 Centro de Reportes":

#### Reporte Ejecutivo PDF
Genera un documento PDF profesional con:
- **Portada corporativa** con logo EA Engineering y fecha de emisión.
- **KPIs ejecutivos**: Total de hallazgos, impacto económico, ahorro generado, eficiencia global.
- **Gráficas de análisis**: Pie charts de estado y severidad.
- **Tabla de Puntos Críticos**: Desglose con columnas: ID, Área, Máquina, Tipo, Severidad, Costo/Año, **Consumo Acumulado** (con unidad de medida), Estado.
- **Anexo Fotográfico**: Fichas técnicas con evidencia de detección y reparación.

#### Reporte Excel
Exporta un archivo `.xlsx` con todas las fugas filtradas, incluyendo:
- Todas las columnas de datos (ID, Fecha, Tipo, Área, etc.)
- **Columna "Consumo Acumulado"** con el valor formateado y unidad de medida:
  - `XX.XX m³` para Gas Natural, Helio y Agua
  - `XX.XX Lts` para Aceite
  - `XX.XX kWh` para Aire
- Encabezados estilizados con fondo azul corporativo.
- Anchos de columna optimizados para lectura.

#### Plano Interactivo HTML
Genera un archivo HTML autocontenido con un mapa Leaflet interactivo que puede compartirse y abrirse en cualquier navegador sin necesidad de la aplicación.

#### Drill-Down Excel
Desde cualquier tarjeta KPI (en el mapa o reportes), al hacer clic se abre un diálogo con la lista de fugas correspondientes y un botón para exportar ese subconjunto específico a Excel.

---

## 11. Modelo Económico Dinámico

### El Taxímetro Digital

Leak Hunter implementa un modelo económico tipo **"taxímetro"** que calcula el impacto económico de cada fuga en tiempo real:

```
Costo Acumulado = (Costo Anual / Minutos en un Año) × Minutos Transcurridos
```

Donde:
- **Costo Anual**: Se obtiene de las tablas de clasificación de fugas (categorías A-E) definidas para cada tipo de fluido.
- **Minutos en un Año**: 365 × 24 × 60 = 525,600 minutos.
- **Minutos Transcurridos**: Diferencia entre la fecha de detección y:
  - La **fecha actual** (si la fuga sigue activa).
  - La **fecha de reparación** (si la fuga fue completada).

### Reglas de Negocio
- Si el estado es `Inspección (OK)`, el costo es **$0.00**.
- Si la fuga fue reparada el mismo día de detección, el impacto muestra **$0** (se documenta con una nota en el PDF ejecutivo).
- Los costos se formatean con separador de miles: `$1,500,000 USD`.

---

## 12. Métricas de Consumo Acumulado

Además del impacto económico, Leak Hunter calcula el **consumo físico acumulado** de cada fuga según su tipo:

### Metros Cúbicos (m³) — Gas Natural, Helio, Agua

```
Consumo (m³) = (l/min ÷ 1000) × Minutos Transcurridos
```

Se convierte de litros por minuto a metros cúbicos por minuto, y se acumula durante todo el período de la fuga.

### Litros (Lts) — Aceite

```
Consumo (Lts) = l/min × Minutos Transcurridos
```

Para aceite, el caudal ya está en litros por minuto, por lo que se acumula directamente.

### Kilovatios-Hora (kWh) — Aire Comprimido

```
Consumo (kWh) = (Costo Acumulado USD × 19.0) ÷ 2.4
```

Donde:
- `19.0` es el tipo de cambio USD → MXN.
- `2.4` es el precio promedio por kWh en MXN.

### Dónde se visualiza

| Ubicación | Fluidos Mostrados | Formato |
|---|---|---|
| Ficha Técnica del Mapa | Todos | Valor + unidad con color diferenciado |
| Detalle de Fuga (pantalla completa) | Todos | Valor + unidad prominente |
| Tabla del PDF Ejecutivo | Todos | Columna "Consumo Acum" |
| Excel (todos los exports) | Todos | Columna "Consumo Acumulado" |

---

## 13. Preguntas Frecuentes

### ¿Por qué una fuga muestra $0 de impacto?
Si la fuga fue registrada y reparada el mismo día, el modelo de taxímetro calcula un impacto cercano a cero. Esto es correcto y documenta una respuesta rápida del equipo de mantenimiento.

### ¿Puedo usar Leak Hunter sin Internet?
No. La aplicación requiere conexión a Internet para sincronizar con la base de datos Supabase en tiempo real.

### ¿Qué formatos de evidencia se soportan?
Imágenes (JPG, PNG) y video (MP4, MOV, WebM). Tamaño máximo: 10 MB por archivo.

### ¿Cómo se calcula la Eficiencia Global?
`Eficiencia = (Fugas Reparadas ÷ Total de Fugas) × 100`

### ¿Puedo filtrar los datos antes de exportar?
Sí. Todos los filtros activos se aplican a las exportaciones. Si filtras por "Aire" y "Severidad Alta", el Excel y PDF solo incluirán esas fugas.

### ¿Qué pasa si agregan clusters al mapa?
Los clusters son puramente visuales para mejorar la navegación. Al hacer zoom o clic, los marcadores individuales aparecen en sus posiciones reales con toda su información intacta. No afectan los datos ni los reportes.

---

## 14. Soporte Técnico

**Desarrollado por:** Erik Armenta, M.Eng.

**Plataforma:** Leak Hunter Digital Twin v4.2

**Stack Tecnológico:**
- Frontend: Flutter (Dart)
- Backend: Supabase (PostgreSQL + Auth + Storage)
- State Management: Riverpod
- Mapas: flutter_map + flutter_map_marker_cluster
- Gráficos: fl_chart
- Exportación: pdf, excel, printing

---

*Documento generado automáticamente. Última actualización: Abril 2026.*
