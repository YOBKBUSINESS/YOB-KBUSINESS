# YOB K BUSINESS – Integrated Agricultural Management System

## Project Overview

**YOB K BUSINESS** is a full-featured agricultural management platform for Côte d'Ivoire. It targets agricultural cooperatives/enterprises that manage producers, land parcels, boreholes/infrastructure, agricultural kits, training programs, finances, and investors — all from a single unified system.

The client wants this to serve as:
- A **credibility tool** for banks
- A **trust tool** for investors
- A **strategic piloting dashboard** for the Director General
- A **competitive advantage** in the Ivorian agricultural sector

---

## Target Platforms

| Platform | Purpose |
|----------|---------|
| **Web App** | Office/desktop use (management, reporting, accounting) |
| **Mobile App** | Field use (registration, GPS, photos, attendance) |

**Tech Stack:** Flutter (Web + Mobile) with a shared codebase.

---

## Role-Based Access Control (RBAC)

| Role | Access Level |
|------|-------------|
| **Direction (Admin/DG)** | Full access — strategic dashboard, all modules, reports |
| **Superviseur Terrain** | Field operations — producers, parcels, kits, formations, boreholes |
| **Comptable** | Financial module — entries, exits, treasury, monthly reports |
| **Partenaire/Investisseur** | Read-only — investment reports, project progress, automated email reports |

---

## Modules & Components to Build

### 1. Authentication & User Management
- Secure login (email/password)
- Role-based routing and permissions
- User profile management
- Session management & token-based auth

### 2. Module Producteurs (Producers)
- **Full producer registration:**
  - Name, Contact, Locality
  - Photo (camera/gallery upload)
  - ID document (scan/upload)
  - Cultivated surface area
- Crop history tracking
- Production level monitoring
- Status management: `Actif` / `En formation` / `Suspendu`
- Contributions (cotisations) tracking
- Signed contracts management
- **Dashboard KPIs:**
  - Total active producers count
  - Who produces what (crop breakdown)
  - Who is behind (late payments/production)

### 3. Module Parcelles & Foncier (Parcels & Land)
- Parcel registration
- **GPS location** (map integration)
- Surface area
- Crop type per parcel
- Land tenure status (statut foncier)
- Commodo/Incommodo survey tracking
- Scanned document attachments
- **Goal:** Secure land ownership documentation

### 4. Module Forages & Infrastructures (Boreholes & Infrastructure)
- List of completed/ongoing boreholes
- Cost tracking
- Contractor/service provider info
- Start date / End date
- **Progress percentage** (advancement tracker)
- Construction site photos
- Maintenance scheduling & history

### 5. Module Kits Agricoles (Agricultural Kits)
- Kit type distributed
- Distribution date
- Beneficiary (linked to producer)
- Kit monetary value
- Status: `Remboursé` (repaid) / `Subventionné` (subsidized)

### 6. Module Formation (Training)
- Training session listing
- Producer attendance tracking (presence)
- Evaluations & scoring
- Certifications issued
- Training schedule/planning

### 7. Module Finances (Critical Module)
- **Income tracking:** investors, contributions, sales
- **Expense tracking:** boreholes, salaries, equipment
- **Real-time treasury** balance
- **Low funds alerts**
- Simplified accounting/bookkeeping
- **Automatic monthly reports** generation
- **1-click financial health overview**

### 8. Module Investisseurs & Partenaires (Investors & Partners)
- Investor registry
- Amount invested per investor
- Associated project
- Expected return/yield
- **Automated report delivery via email**

### 9. Tableau de Bord Stratégique (Strategic Dashboard — DG View)
- Total number of producers
- Total hectares exploited
- Estimated production volume
- Available cash in treasury
- Active projects overview
- **Urgent alerts** panel
- Executive-level summary — "Director General cockpit"

---

## Technical Architecture (Proposed)

```
┌─────────────────────────────────────────────┐
│                  Frontend                    │
│         Flutter (Web + Mobile)               │
│  ┌─────────┐  ┌─────────┐  ┌─────────────┐  │
│  │  Auth    │  │ Modules │  │  Dashboard   │  │
│  │  Flow    │  │  CRUD   │  │  Analytics   │  │
│  └─────────┘  └─────────┘  └─────────────┘  │
└──────────────────┬──────────────────────────┘
                   │ REST API / GraphQL
┌──────────────────▼──────────────────────────┐
│                  Backend                     │
│        (Firebase / Supabase / Custom)        │
│  ┌─────────┐  ┌─────────┐  ┌─────────────┐  │
│  │  Auth   │  │  CRUD   │  │  Reports &   │  │
│  │  RBAC   │  │  APIs   │  │  Email Jobs  │  │
│  └─────────┘  └─────────┘  └─────────────┘  │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│              Database + Storage              │
│   Users, Producers, Parcels, Finances...     │
│   File Storage (photos, documents, scans)    │
└─────────────────────────────────────────────┘
```

---

## Cross-Cutting Concerns

| Concern | Details |
|---------|---------|
| **Offline Support** | Mobile must work in field with poor connectivity — sync when back online |
| **File Uploads** | Photos (producers, boreholes), ID scans, land documents |
| **GPS/Maps** | Parcel location mapping (Google Maps / OpenStreetMap) |
| **Notifications** | Push notifications for alerts, low funds, deadlines |
| **Email Reports** | Automated monthly reports to investors/partners |
| **Localization** | French primary (Côte d'Ivoire) |
| **Data Export** | PDF/Excel export for reports |

---

## TODO — Development Roadmap

### Phase 1: Foundation
- [x] Project setup — Flutter monorepo (web + mobile) with FVM + Melos
- [x] Choose & configure backend — dart_frog + PostgreSQL (Docker)
- [x] Database schema design (all modules)
- [x] Authentication system (login, registration, password reset)
- [x] Role-based access control (RBAC) implementation
- [x] Base UI/UX — app shell, navigation, theming
- [x] Responsive layout (mobile + web breakpoints)

### Phase 2: Core Modules
- [x] **Producers module** — CRUD, status management, search & filters, list/detail/form screens
- [x] **Parcels module** — CRUD, tenure status, crop type filters, responsive grid layout
- [x] **Boreholes module** — CRUD, progress tracking, cost display (FCFA), status filters
- [x] **Agricultural Kits module** — CRUD, distribution tracking, repayment status, beneficiary link
- [x] **Training module** — CRUD, attendance, certification filter, evaluation notes

### Phase 3: Financial Engine
- [x] **Finance module** — Income/expense tracking, transaction CRUD with search & filters
- [x] Real-time treasury balance calculation with alert system (critical/warning/ok)
- [x] Low funds alert system with configurable threshold
- [x] Simplified accounting views — transaction list with type/category filters
- [x] Monthly report generation with category breakdowns & top transactions
- [x] Financial dashboard (1-click health overview) with charts & summaries

### Phase 4: Investors & Reporting
- [ ] **Investors module** — Registry, investment tracking, project linking
- [ ] Expected return calculations
- [ ] Automated email report delivery to investors
- [ ] Partner portal (read-only access)

### Phase 5: Strategic Dashboard
- [ ] **DG Dashboard** — KPI widgets (producers, hectares, production, cash)
- [ ] Active projects overview
- [ ] Urgent alerts panel
- [ ] Charts & data visualization
- [ ] Quick action shortcuts

### Phase 6: Polish & Production
- [ ] Offline mode & data synchronization (mobile)
- [ ] Push notifications setup
- [ ] Data export (PDF + Excel)
- [ ] Full testing (unit, integration, E2E)
- [ ] Performance optimization
- [ ] Security audit
- [ ] Deployment (web hosting + app stores)
- [ ] User documentation / training

---

## Summary

| Item | Count |
|------|-------|
| **Modules** | 9 (Auth, Producers, Parcels, Boreholes, Kits, Training, Finance, Investors, Dashboard) |
| **Platforms** | 2 (Web + Mobile) |
| **User Roles** | 4 (Direction, Superviseur, Comptable, Partenaire) |
| **Phases** | 6 |
