<div align="center">

# Leak Hunter

### Industrial Fluid Leak Detection & Economic Analysis Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-SDK%20%5E3.9.2-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-2.12-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Vercel](https://img.shields.io/badge/Vercel-Deploy-000000?logo=vercel&logoColor=white)](https://vercel.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](pubspec.yaml)

**A Progressive Web App (PWA) for industrial plants to detect, register, track, and economically analyze fluid leaks — from compressed air to helium — in real time.**

<!-- [screenshot: Leak Hunter app hero banner] -->

</div>

---

## Table of Contents

- [Overview](#overview)
- [Screenshots](#screenshots)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites & Installation](#prerequisites--installation)
- [Environment Variables](#environment-variables)
- [Build & Deploy](#build--deploy)
- [Roles & Permissions](#roles--permissions)
- [Database Schema](#database-schema)
- [Fluid Cost Reference](#fluid-cost-reference)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**Leak Hunter** is a PWA built with Flutter Web + Supabase, designed for use in industrial manufacturing plants. Field inspectors use the app on tablets or mobile devices to locate leaks on a high-resolution interactive plant map, log them with photographic evidence, and immediately see the real-time economic cost of each unrepaired leak.

Management teams use the analytics dashboard and reporting module to prioritize repairs by economic impact, track repair progress, and export professional Excel/PDF reports for energy efficiency programs.

### Key value proposition

- A single undetected helium leak can cost up to **$1,095,000 USD/year**
- Air leaks are common and typically overlooked, yet they accumulate to significant losses
- Leak Hunter calculates cost **to the minute** from the moment a leak is registered
- All data is role-gated, audited, and traceable end-to-end

---

## Screenshots

| Module | Preview |
|--------|---------|
| Interactive Plant Map | `[screenshot: interactive map with colored leak markers and zone overlays]` |
| Leak Registration Form | `[screenshot: leak form panel open over the map with fluid type selector]` |
| Leak Detail Panel | `[screenshot: detail panel showing cost counter, consumption stats, photo evidence, audit timeline]` |
| Analytics & Reports | `[screenshot: report screen with charts — severity distribution, monthly comparison, heatmap]` |
| User Management | `[screenshot: admin panel listing users with role badges and action buttons]` |

---

## Features

### Interactive Plant Map
- High-resolution plant floor plan (25,600 × 16,715 px) segmented into tiles and rendered with `flutter_map`
- Color-coded markers per fluid type: Air (blue), Natural Gas (orange), Water (cyan), Helium (purple), Oil (dark red), Inspection OK (green)
- Intelligent marker clustering to prevent visual saturation at low zoom levels
- Semi-transparent rectangular inspection zone overlays drawn directly on the map
- Zoom range: 2.5× to 7×
- Live overlay metrics: total active leaks, total accumulated cost (USD), total accumulated consumption — refreshed every minute
- Click any marker to open the detail panel

### Leak Management (Full CRUD)
- Register a leak by clicking two points on the map to define the leak area
- Fields: fluid type, leak category (A–E by liters/min), severity (High/Medium/Low), equipment ID, plant area, location type (Ground/Elevated), start date, end date, status, comments
- Automatic calculation of annual cost and liters/min from built-in reference tables
- Photographic evidence: detection photo and repair photo — images and video (mp4, mov, webm) uploaded to Supabase Storage
- Edit, delete, and relocate (drag) existing leaks
- Paginated leak list (20 records per page)
- ESC key cancels point selection on the map

### Real-Time Economic Calculations
- Accumulated cost calculated to the exact minute using annual cost prorated from start date to now (or close date for completed leaks)
- Accumulated consumption in liters, cubic meters (m³), and kWh equivalent
- Currency conversion: USD → MXN at 19.0 exchange rate; energy conversion at 2.4 MXN/kWh
- Inspection OK entries always show $0.00 cost

### Reports & Analytics
- Summary cards: total leaks, accumulated cost, total consumption
- Repair history chart (temporal line chart)
- Monthly comparison: Detections vs Repairs
- Five analytical charts: Severity Distribution, Status Distribution, Economic Impact by Type, Repair Efficiency, Inspection Coverage
- Top Critical Sectors (areas by economic impact)
- Leak heatmap visualization
- Export center: Excel (.xlsx) with professional column formatting, PDF with branded layout — works on web (direct download) and mobile (native share sheet)

### Global Filters
- Side drawer with filters applied simultaneously across Map, Management, and Reports modules
- Filter by: fluid type, status, plant area, date range, text search

### Authentication & Role System
- Email + password login via Supabase Auth
- Three roles: Admin Principal, Supervisor, Inspector
- Inspectors access Map and Leak Management only
- Supervisors and Admins additionally access Reports and User Administration
- User profile loaded from `public.users` table
- Real-time session change listener

### User Administration (Admin only)
- Full CRUD: create, edit, and delete employee accounts
- Role assignment (Admin Principal, Supervisor, Inspector)
- Secure management via Supabase RPC functions with `SECURITY DEFINER`
- Modal dialog interface

### Audit & Traceability
- Full change history timeline per leak
- Records who performed each action and when
- Audit log entries sourced from Supabase `audit_logs` table
- Visual timeline widget integrated in the leak detail panel

### Design & UX
- Professional dark theme: `#0d1117` / `#161a22` (GitHub Dark-inspired)
- Fully responsive: mobile (<600px), tablet (600–1200px), desktop (>1200px)
- Smooth fade + slide transition animations
- Draggable navigation panel
- Collapsible side panel to maximize map area
- Multi-plant support with plant selector
- QR code generation per leak linking to a Streamlit digital twin (2D visualization)

---

## Architecture

### Stack Diagram

```
┌─────────────────────────────────────────────────────┐
│                    CLIENT LAYER                     │
│                                                     │
│   Flutter Web (Dart)  ──  Vercel CDN (hosting)     │
│   ┌─────────────┐  ┌──────────┐  ┌─────────────┐  │
│   │ flutter_map │  │ fl_chart │  │  Riverpod   │  │
│   │ (tile map)  │  │ (charts) │  │   (state)   │  │
│   └─────────────┘  └──────────┘  └─────────────┘  │
└────────────────────────┬────────────────────────────┘
                         │ HTTPS / Realtime WS
┌────────────────────────▼────────────────────────────┐
│                   SUPABASE BACKEND                  │
│                                                     │
│  ┌────────────┐  ┌──────────┐  ┌────────────────┐  │
│  │ PostgreSQL │  │   Auth   │  │    Storage     │  │
│  │  (fugas,  │  │ (email + │  │ (photos/video) │  │
│  │  users,   │  │  roles)  │  │                │  │
│  │  audit)   │  │          │  │                │  │
│  └────────────┘  └──────────┘  └────────────────┘  │
│                                                     │
│  RPC Functions (SECURITY DEFINER) for admin ops    │
└─────────────────────────────────────────────────────┘
```

### Project Structure

```
lib/
├── config/
│   ├── constants.dart        # Fluid cost tables, color maps, severity config
│   ├── supabase_config.dart  # Supabase client initialization
│   └── theme.dart            # Dark theme definition (#0d1117, #161a22)
│
├── models/
│   ├── fuga.dart             # Leak model with cost/consumption computed getters
│   ├── app_user.dart         # User model with role management
│   └── audit_log.dart        # Audit log entry model
│
├── providers/
│   ├── fugas_provider.dart   # Leak list state (Riverpod)
│   ├── auth_provider.dart    # Authentication state
│   ├── filter_provider.dart  # Global filter state
│   ├── plant_provider.dart   # Active plant state
│   └── admin_users_provider.dart
│
├── services/
│   ├── supabase_service.dart # All Supabase DB/Auth/Storage calls
│   ├── export_service.dart   # Excel and PDF generation
│   └── web_download.dart     # Web-specific download helper
│
├── screens/
│   ├── login_screen.dart     # Auth screen
│   ├── main_screen.dart      # Shell with navigation
│   ├── map_screen.dart       # Interactive map (main module)
│   ├── management_screen.dart
│   ├── report_screen.dart
│   └── admin_users_screen.dart
│
└── widgets/                  # Reusable UI components
```

### Patterns & Libraries

| Concern | Solution |
|---------|----------|
| State management | `flutter_riverpod ^3.3.1` |
| Interactive map | `flutter_map ^8.2.2` with local tile assets |
| Marker clustering | `flutter_map_marker_cluster ^8.2.2` |
| Charts | `fl_chart ^1.2.0` |
| Excel export | `excel ^4.0.6` |
| PDF export | `pdf ^3.11.1` + `printing ^5.13.2` |
| File picking | `file_picker ^10.3.10` |
| Image picking | `image_picker ^1.1.2` |
| Date/number formatting | `intl ^0.20.2` |
| Deep links / QR | `url_launcher ^6.3.2` |
| Environment vars | `flutter_dotenv ^5.1.0` |

---

## Prerequisites & Installation

### Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) with Dart SDK `^3.9.2`
- [Supabase CLI](https://supabase.com/docs/guides/cli) (for local development or migrations)
- A Supabase project with the schema below applied
- [Vercel CLI](https://vercel.com/docs/cli) (for deployment)

### Local setup

```bash
# 1. Clone the repository
git clone <repository-url>
cd leakhunter-flutter

# 2. Install Flutter dependencies
flutter pub get

# 3. Copy the environment file and fill in your Supabase credentials
cp .env.example .env
# Edit .env with your SUPABASE_URL and SUPABASE_ANON_KEY

# 4. Run in Chrome (web target required)
flutter run -d chrome
```

---

## Environment Variables

Create a `.env` file at the project root (it is bundled as a Flutter asset):

```dotenv
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

| Variable | Description | Required |
|----------|-------------|----------|
| `SUPABASE_URL` | Full URL of your Supabase project | Yes |
| `SUPABASE_ANON_KEY` | Public anonymous key from Supabase dashboard | Yes |

> **Note:** The `.env` file is listed in `pubspec.yaml` under `flutter.assets` so `flutter_dotenv` can load it at runtime. Never commit real credentials — add `.env` to `.gitignore`.

---

## Build & Deploy

### Web build

```bash
# Install dependencies
flutter pub get

# Build optimized web release
flutter build web --release

# Output is in build/web/
```

### Deploy to Vercel

```bash
# From project root (after web build)
vercel --prod

# Or configure automatic deploys by linking the repo in the Vercel dashboard
# Every push to main triggers a production deploy
```

### Vercel configuration

A `vercel.json` is included at the project root to route all requests to `index.html` (required for Flutter web SPA routing):

```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

---

## Roles & Permissions

| Feature | Admin Principal | Supervisor | Inspector |
|---------|:-:|:-:|:-:|
| Interactive Map | Yes | Yes | Yes |
| Leak Management (CRUD) | Yes | Yes | Yes |
| Reports & Analytics | Yes | Yes | No |
| Export Excel / PDF | Yes | Yes | No |
| User Administration | Yes | No | No |
| View Audit Logs | Yes | Yes | No |

---

## Database Schema

### `fugas` (Leaks)

| Column | Type | Description |
|--------|------|-------------|
| `id` | `int8` | Primary key, auto-increment |
| `x1` | `float8` | Map coordinate — top-left X |
| `y1` | `float8` | Map coordinate — top-left Y |
| `x2` | `float8` | Map coordinate — bottom-right X |
| `y2` | `float8` | Map coordinate — bottom-right Y |
| `zona` | `text` | Date range string `DD/MM/YYYY - DD/MM/YYYY` (encodes start and end dates) |
| `tipo_fuga` | `text` | Fluid type: `Aire`, `Helio`, `Agua`, `Aceite`, `Gas Natural`, `Inspección (OK)` |
| `area` | `text` | Plant area / sector name |
| `ubicacion` | `text` | Location type: `Terrestre` or `Elevada` |
| `id_maquina` | `text` | Equipment or machine identifier |
| `severidad` | `text` | Severity: `Alta`, `Media`, `Baja` |
| `categoria` | `text` | Leak category: `Fuga A` through `Fuga E` (by liters/min range) |
| `l_min` | `float8` | Flow rate in liters per minute |
| `costo_anual` | `float8` | Annual cost in USD (from reference table) |
| `estado` | `text` | Status: `En proceso de reparar`, `Completada`, `Dañada`, `Inspección (OK)` |
| `comentarios` | `text` | Free-text notes |
| `foto_deteccion` | `text` | Supabase Storage URL — detection photo/video |
| `foto_reparacion` | `text` | Supabase Storage URL — repair photo/video |

### `users` (public schema)

| Column | Type | Description |
|--------|------|-------------|
| `id` | `uuid` | References `auth.users.id` |
| `email` | `text` | User email address |
| `name` | `text` | Full name (`full_name` in user metadata) |
| `role` | `text` | Role: `Admin Principal`, `Supervisor`, `Inspector` |
| `created_at` | `timestamptz` | Account creation timestamp |
| `last_sign_in_at` | `timestamptz` | Last login timestamp |

### `audit_logs`

| Column | Type | Description |
|--------|------|-------------|
| `id` | `uuid` | Primary key |
| `fuga_id` | `int8` | References `fugas.id` |
| `user_id` | `uuid` | References `auth.users.id` |
| `user_email` | `text` | Email snapshot at time of action |
| `accion` | `text` | Action performed (e.g., `CREATED`, `UPDATED`, `DELETED`) |
| `estado_anterior` | `text` | Status before the change |
| `estado_nuevo` | `text` | Status after the change |
| `detalles` | `text` | Human-readable description of the change |
| `fecha` | `timestamptz` | Timestamp of the action |

---

## Fluid Cost Reference

Annual costs (USD) used by the system to calculate real-time economic impact:

### Air (Compressed Air)

| Category | Flow Rate (L/min) | Annual Cost (USD) |
|----------|:-----------------:|:-----------------:|
| Fuga A | 0.1 – 10 | $60 |
| Fuga B | 10.1 – 20 | $300 |
| Fuga C | 20.1 – 30 | $680 |
| Fuga D | 30.1 – 40 | $890 |
| Fuga E | 40.1 – 50 | $1,090 |

### Helium

| Category | Flow Rate (L/min) | Annual Cost (USD) |
|----------|:-----------------:|:-----------------:|
| Fuga A | 1 – 10 | $182,500 |
| Fuga B | 10 – 20 | $365,000 |
| Fuga C | 20 – 40 | $730,000 |
| Fuga D | 40 – 60 | $1,095,000 |

### Water

| Category | Flow Rate (L/min) | Annual Cost (USD) |
|----------|:-----------------:|:-----------------:|
| Fuga A | 0.01 – 0.05 | $114 |
| Fuga B | 0.05 – 0.10 | $228 |
| Fuga C | 0.10 – 0.20 | $456 |
| Fuga D | 0.20 – 1.50 | $3,400 |
| Fuga E | 1.50 – 3.00 | $6,840 |

### Oil

| Category | Flow Rate (L/min) | Annual Cost (USD) |
|----------|:-----------------:|:-----------------:|
| Fuga A | 0.002 – 0.004 | $2,181 |
| Fuga B | 0.004 – 0.01 | $10,905 |
| Fuga C | 0.01 – 0.1 | $109,058 |

### Natural Gas

| Category | Flow Rate (L/min) | Annual Cost (USD) |
|----------|:-----------------:|:-----------------:|
| Fuga A | 1 – 50 | $450 |
| Fuga B | 51 – 150 | $1,800 |
| Fuga C | 151 – 500 | $5,200 |

> Costs are prorated to the **exact minute** from the leak start date. Exchange rate: 1 USD = 19 MXN. Energy equivalent: 2.4 MXN/kWh.

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature-name`
3. Commit your changes: `git commit -m "feat: description of change"`
4. Push to your branch: `git push origin feat/your-feature-name`
5. Open a Pull Request against `main`

### Guidelines

- Follow the existing Dart/Flutter code style and naming conventions
- Keep state management inside Riverpod providers — avoid local `setState` for shared state
- All Supabase calls must go through `supabase_service.dart`
- Test on both mobile breakpoint (<600px) and desktop before submitting a PR
- Do not commit `.env` or any file containing credentials

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

Built with Flutter Web · Powered by Supabase · Deployed on Vercel

</div>
