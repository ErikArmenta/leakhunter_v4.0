---
marp: true
theme: default
paginate: true
backgroundColor: #0d1117
color: #e6edf3
style: |
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
    background-color: #0d1117;
    color: #e6edf3;
  }
  h1 { color: #58a6ff; }
  h2 { color: #79c0ff; border-bottom: 2px solid #30363d; padding-bottom: 8px; }
  h3 { color: #d2a8ff; }
  table { border-collapse: collapse; width: 100%; }
  th { background-color: #161a22; color: #58a6ff; padding: 8px 12px; }
  td { padding: 8px 12px; border-bottom: 1px solid #30363d; }
  tr:hover td { background-color: #161a22; }
  blockquote { border-left: 4px solid #58a6ff; padding-left: 16px; color: #8b949e; }
  code { background-color: #161a22; padding: 2px 6px; border-radius: 4px; color: #79c0ff; }
---

<!-- SLIDE 1 — TÍTULO -->

# 🔍 Leak Hunter

## Inteligencia Industrial para el Control de Fugas

---

> **"Cada fuga no detectada es dinero que se escapa — literalmente."**

| | |
|---|---|
| **Versión** | 1.0 |
| **Plataforma** | Web Progresiva (PWA) — Tablet / Celular / Desktop |
| **Stack** | Flutter Web · Supabase · Vercel |
| **Tipo** | Aplicación Industrial de Gestión de Fugas |

```
[ LOGOTIPO LEAK HUNTER ]
```

---

<!-- SLIDE 2 — EL PROBLEMA -->

## 🚨 El Problema: Fugas No Detectadas = Pérdidas Invisibles

Las plantas industriales pierden millones de pesos al año por fugas de fluidos que **nadie registra, nadie prioriza y nadie repara a tiempo.**

---

### Costo anual por tipo de fluido (sin reparar)

| Fluido | Fuga Mínima | Fuga Máxima | Riesgo |
|---|---|---|---|
| 🟣 **Helio** | $182,500 USD/año | **$1,095,000 USD/año** | Crítico |
| 🔴 **Aceite** | $2,181 USD/año | **$109,058 USD/año** | Alto |
| 🟠 **Gas Natural** | $450 USD/año | $5,200 USD/año | Alto |
| 🔵 **Agua** | $114 USD/año | $6,840 USD/año | Medio |
| 🔵 **Aire Comprimido** | $60 USD/año | $1,090 USD/año | Medio |

### El problema real no es la fuga — es la falta de visibilidad

- ❌ Las fugas se detectan tarde o nunca se documentan
- ❌ No hay registro histórico de dónde están ni cuánto cuestan
- ❌ Las decisiones de reparación no se basan en impacto económico
- ❌ La gerencia no tiene datos para justificar inversión en mantenimiento

---

<!-- SLIDE 3 — LA SOLUCIÓN -->

## ✅ La Solución: Leak Hunter

**Plataforma integral de gestión de fugas industriales** — accesible desde cualquier dispositivo, en campo, en tiempo real.

---

### Una sola plataforma. Todos los módulos.

```
┌─────────────────────────────────────────────────────────┐
│                      LEAK HUNTER                        │
├──────────────┬──────────────┬──────────────┬────────────┤
│  🗺️ Mapa     │  💧 Gestión  │  📊 Reportes │ 👥 Admón   │
│  Interactivo │  de Fugas    │  y Analytics │ Usuarios   │
├──────────────┴──────────────┴──────────────┴────────────┤
│  📸 Evidencia fotográfica  │  🔍 Auditoría completa     │
├────────────────────────────┴────────────────────────────┤
│  💰 Cálculo económico en tiempo real (USD / MXN)        │
└─────────────────────────────────────────────────────────┘
```

### Acceso desde cualquier dispositivo

| Dispositivo | Uso típico |
|---|---|
| 📱 Celular | Inspector en campo registrando fugas |
| 📟 Tablet | Supervisor revisando el mapa de planta |
| 💻 Desktop | Gerencia consultando reportes y analítica |

> **No requiere instalación.** Se abre desde el navegador. Funciona en iOS, Android y Windows.

---

<!-- SLIDE 4 — FEATURES PRINCIPALES -->

## ⚙️ Features Principales

---

| Módulo | Descripción |
|---|---|
| 🗺️ **Mapa Interactivo** | Plano de planta de alta resolución (25,600×16,715 px) con marcadores de fugas por color, clustering y métricas en vivo |
| 💧 **Gestión de Fugas** | Registro con dos clics sobre el mapa, categorías A–E, severidad, estado, foto de detección y reparación |
| 💰 **Análisis Económico** | Costo acumulado al minuto exacto en USD y MXN desde la fecha de inicio de cada fuga |
| 📊 **Reportes** | Dashboard con 6 gráficas, top sectores críticos, mapa de calor, exportación Excel y PDF |
| 👥 **Roles y Permisos** | 3 niveles: Admin Principal, Supervisor, Inspector — cada uno con vistas y acciones controladas |
| 📸 **Evidencia Fotográfica** | Foto de detección + foto/video de reparación almacenados en la nube (Supabase Storage) |
| 📱 **PWA Multiplataforma** | Funciona sin instalación en celular, tablet y desktop — sin App Store |
| 🔍 **Auditoría Completa** | Línea de tiempo por fuga: quién registró, quién editó, quién cerró y cuándo |

---

<!-- SLIDE 5 — FLUJO DE USO -->

## 🔄 Flujo de Uso: De la Detección al Ahorro

---

```
 INSPECTOR                SISTEMA               SUPERVISOR / GERENCIA
─────────────────────────────────────────────────────────────────────

  1. Detecta una fuga
     en planta
          │
          ▼
  2. Abre Leak Hunter
     en su celular/tablet
          │
          ▼
  3. Toca el mapa en la        ──▶  Calcula costo anual
     ubicación exacta                automáticamente
          │                          ($182,500 – $1,095,000 USD)
          ▼
  4. Registra: tipo de
     fluido, categoría,
     foto de evidencia
          │
          ▼
                               ──▶  Notifica costo acumulado    ──▶  5. Supervisor ve
                                    en tiempo real                       en el mapa la fuga
                                                                         priorizada por costo
                                                                              │
                                                                              ▼
  6. Técnico recibe orden                                           Asigna reparación
     de reparación                                                  según impacto $$$
          │
          ▼
  7. Repara la fuga y
     sube foto de cierre
          │
          ▼
                               ──▶  Registra fecha/hora          ──▶  8. Gerencia descarga
                                    de cierre y calcula                   reporte PDF/Excel
                                    ahorro real generado                  con ROI del período
```

---

<!-- SLIDE 6 — IMPACTO ECONÓMICO -->

## 💰 Impacto Económico: Ejemplo Real

---

### Escenario: Planta con fugas activas sin gestionar

#### Fugas de Aire Comprimido

| Cantidad | Categoría | Costo unitario/año | Costo total/año |
|---|---|---|---|
| 50 fugas | C | $330 USD | **$16,500 USD** |

#### Fugas de Helio

| Cantidad | Categoría | Costo unitario/año | Costo total/año |
|---|---|---|---|
| 3 fugas | B | $365,000 USD | **$1,095,000 USD** |

---

### Resumen del potencial de recuperación anual

| Concepto | USD | MXN (×19) |
|---|---|---|
| Fugas de aire (50) | $16,500 | $313,500 |
| Fugas de helio (3) | $1,095,000 | $20,805,000 |
| **Total recuperable** | **$1,111,500 USD** | **$21,118,500 MXN** |

> 💡 **Con Leak Hunter, estas pérdidas se detectan, cuantifican y priorizan desde el primer día de uso.**

---

<!-- SLIDE 7 — TECNOLOGÍA -->

## 🛠️ Tecnología: Stack Técnico

---

### Arquitectura de la plataforma

```
┌─────────────────────────────────────────────────────────────┐
│                    USUARIO FINAL                            │
│         Celular · Tablet · Desktop (navegador)              │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTPS
┌─────────────────────▼───────────────────────────────────────┐
│                  FLUTTER WEB (Dart)                         │
│   flutter_map · Riverpod · fl_chart · pdf · excel           │
│           PWA — Sin instalación requerida                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
            ┌─────────▼──────────┐
            │   VERCEL CDN       │
            │  Hosting + Deploy  │
            └─────────┬──────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                    SUPABASE                                 │
│  PostgreSQL · Auth (email/contraseña) · Storage (fotos)     │
│  Realtime · RPC (SECURITY DEFINER) · Row Level Security     │
└─────────────────────────────────────────────────────────────┘
```

### Componentes técnicos destacados

| Componente | Tecnología | Detalle |
|---|---|---|
| **Mapa interactivo** | `flutter_map` | Tiles locales 25,600×16,715 px, zoom 2.5×–7× |
| **Estado global** | `Riverpod` | Providers reactivos por módulo |
| **Gráficas** | `fl_chart` | 6 tipos de gráficas en tiempo real |
| **Exportación** | `pdf` + `excel` | Descarga directa en web, compartir en móvil |
| **Autenticación** | `Supabase Auth` | JWT, roles en base de datos, RLS |
| **Almacenamiento** | `Supabase Storage` | Fotos y video de evidencia en la nube |
| **Tiles offline** | Assets locales | Mapa disponible sin internet |

---

<!-- SLIDE 8 — ROADMAP -->

## 🗺️ Roadmap: Lo que Viene

---

### Mejoras planificadas y sugeridas

#### Fase 2 — Conectividad e Integración

- 🌐 **API REST** para integración con SAP, ERP y sistemas CMMS
- 🔔 **Notificaciones push** para fugas críticas recién detectadas
- 📡 **Integración con sensores IoT** — detección automática de fugas sin inspector

#### Fase 3 — Inteligencia y Movilidad

- 🤖 **Machine Learning** para predicción de zonas con mayor probabilidad de fugas
- 📱 **App nativa iOS/Android** para acceso offline completo en campo
- 🔧 **Módulo de mantenimiento preventivo** — calendario de revisiones por equipo

#### Fase 4 — Gestión Avanzada

- 📋 **Módulo de órdenes de trabajo** integrado con la gestión de fugas
- 📊 **Reportes ejecutivos automáticos** — generación mensual con KPIs y ROI
- 🌍 **Multi-planta con consolidación** — reporte global de todas las instalaciones

> La plataforma está diseñada con arquitectura escalable. Cada fase puede activarse sin rediseño del sistema base.

---

<!-- SLIDE 9 — CIERRE -->

## 🎯 Adopta Leak Hunter en tu Planta

---

### El ROI habla por sí solo

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│   "Una fuga de helio sin detectar puede costar            │
│    más de $1,000,000 USD al año.                          │
│                                                            │
│    Leak Hunter lo detecta desde el primer día."           │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### ¿Por qué implementar Leak Hunter hoy?

- ✅ **Visibilidad inmediata** — mapa de fugas activas desde el día 1
- ✅ **ROI cuantificable** — costo acumulado calculado al minuto exacto
- ✅ **Sin inversión en hardware** — funciona en los dispositivos que ya tienen
- ✅ **Implementación rápida** — sin instalación, sin configuración compleja
- ✅ **Cumplimiento normativo** — trazabilidad completa para auditorías energéticas

---

### Próximos pasos

| Paso | Acción |
|---|---|
| 1️⃣ | Definir planta piloto y perfiles de usuario |
| 2️⃣ | Cargar plano de planta y configurar zonas de inspección |
| 3️⃣ | Capacitación de inspectores (2 horas) |
| 4️⃣ | Primera ronda de inspección con registro en Leak Hunter |
| 5️⃣ | Reporte ejecutivo de hallazgos al mes 1 |

---

**Contacto para implementación:**

> 📧 Área de Tecnología Industrial · FoxLabs
> 🌐 Plataforma disponible en: `https://leakhunter.vercel.app`

---

*Leak Hunter v1.0 — Desarrollado por FoxLabs · 2025*
