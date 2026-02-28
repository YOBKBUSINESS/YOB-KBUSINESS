# API Reference — YOB K Business

Base URL: `http://localhost:8080/api/v1`

## Authentication

All endpoints except `/auth/login` and `/auth/register` require a Bearer token:

```
Authorization: Bearer <jwt_token>
```

### Response format

All endpoints return:
```json
{
  "success": true|false,
  "data": { ... },
  "message": "Error description (on failure)"
}
```

### Paginated responses

List endpoints return:
```json
{
  "success": true,
  "data": {
    "items": [...],
    "total": 150,
    "page": 1,
    "limit": 20,
    "totalPages": 8
  }
}
```

---

## Auth

### POST /auth/login

Login with email and password.

**Body:**
```json
{
  "email": "admin@yobkbusiness.com",
  "password": "admin123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGci...",
    "refreshToken": "eyJhbGci...",
    "user": {
      "id": "uuid",
      "email": "admin@yobkbusiness.com",
      "full_name": "Admin",
      "role": "admin"
    }
  }
}
```

**Rate limit:** 10 requests/minute per IP.

### POST /auth/register

Register a new user.

**Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "full_name": "Nom Complet",
  "role": "superviseur"
}
```

### POST /auth/refresh

Refresh an expired access token.

**Body:**
```json
{
  "refresh_token": "eyJhbGci..."
}
```

### GET /auth/me

Get the authenticated user's profile. Requires auth token.

---

## Producers

### GET /producers

List producers with optional filters and pagination.

**Query parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | Page number |
| `limit` | int | 20 | Items per page (max 100) |
| `search` | string | — | Search by name, phone, or locality |
| `status` | string | — | Filter by status: `actif`, `en_formation`, `suspendu` |
| `locality` | string | — | Filter by locality |

### POST /producers

Create a new producer.

**Body:**
```json
{
  "full_name": "Kouassi Yao",
  "phone": "+225 0101020304",
  "locality": "Bouaké",
  "cultivated_area": 12.5,
  "status": "actif",
  "crop_history": ["cacao", "café"],
  "production_level": 8.5,
  "total_contributions": 0
}
```

**Required fields:** `full_name`, `locality`

### GET /producers/:id

Get a single producer by ID.

### PUT /producers/:id

Update a producer. Send only the fields to update.

### DELETE /producers/:id

Delete a producer by ID.

---

## Parcels

### GET /parcels

List parcels. Supports `page`, `limit`, `search`, `tenure_status`, `crop_type`.

### POST /parcels

```json
{
  "name": "Parcelle A1",
  "producer_id": "uuid",
  "area": 5.5,
  "crop_type": "cacao",
  "latitude": 6.8501,
  "longitude": -5.3064,
  "tenure_status": "titre_foncier"
}
```

### GET/PUT/DELETE /parcels/:id

Standard CRUD.

---

## Boreholes

### GET /boreholes

List boreholes. Supports `page`, `limit`, `status`, `locality`.

### POST /boreholes

```json
{
  "name": "Forage Bouaké Nord",
  "locality": "Bouaké",
  "cost": 5000000,
  "contractor": "Hydro CI",
  "status": "en_cours",
  "progress": 65,
  "start_date": "2025-01-15",
  "end_date": "2025-06-30"
}
```

### GET/PUT/DELETE /boreholes/:id

Standard CRUD.

---

## Kits

### GET /kits

List agricultural kits. Supports `page`, `limit`, `status`, `producer_id`.

### POST /kits

```json
{
  "kit_type": "semences_cacao",
  "producer_id": "uuid",
  "value": 150000,
  "status": "distribue",
  "distributed_at": "2025-03-01"
}
```

### GET/PUT/DELETE /kits/:id

Standard CRUD.

---

## Trainings

### GET /trainings

List training sessions. Supports `page`, `limit`, `status`.

### POST /trainings

```json
{
  "title": "Formation Bonnes Pratiques",
  "description": "Formation sur les techniques agricoles modernes",
  "date": "2025-04-15",
  "location": "Bouaké",
  "trainer": "Dr. Konaté",
  "max_participants": 30,
  "status": "planifiee"
}
```

### GET/PUT/DELETE /trainings/:id

Standard CRUD.

### POST /trainings/:id/attendees

Add attendee to a training session.

---

## Finances

### GET /finances/transactions

List transactions. Supports:
| Param | Type | Description |
|-------|------|-------------|
| `page` | int | Page number |
| `limit` | int | Items per page |
| `type` | string | `income` or `expense` |
| `category` | string | Category filter |
| `from` | date | Start date (YYYY-MM-DD) |
| `to` | date | End date |

### POST /finances/transactions

```json
{
  "type": "income",
  "amount": 250000,
  "description": "Cotisation mensuelle",
  "category": "cotisation",
  "date": "2025-03-15"
}
```

### GET /finances/summary

Financial summary: total income, total expenses, net balance, transaction count.

### GET /finances/treasury

Real-time treasury balance with alert level (`ok`, `warning`, `critical`).

### GET /finances/report

Monthly financial report with category breakdowns and top transactions.

Query params: `month` (1-12), `year` (YYYY)

---

## Investors

### GET /investors

List investors. Supports `page`, `limit`, `search`, `project_id`.

### POST /investors

```json
{
  "full_name": "Jean Dupont",
  "email": "jean@example.com",
  "company": "AgriInvest CI",
  "total_invested": 5000000,
  "project_id": "uuid",
  "project_name": "Projet Cacao Nord",
  "expected_return": 12.5
}
```

### GET /investors/portfolio

Aggregated portfolio stats across all investors.

### POST /investors/reports

Send automated email reports to investors.

**Body:**
```json
{
  "investor_ids": ["uuid1", "uuid2"],
  "report_type": "monthly"
}
```

---

## Dashboard

### GET /dashboard

Strategic dashboard statistics for the Director General.

**Response:**
```json
{
  "success": true,
  "data": {
    "total_producers": 45,
    "active_producers": 38,
    "total_hectares": 1230.5,
    "estimated_production": 856.2,
    "available_cash": 2500000,
    "active_projects": 3,
    "urgent_alerts": [
      {
        "id": "uuid",
        "title": "Trésorerie basse",
        "message": "Solde inférieur au seuil",
        "severity": "critical",
        "created_at": "2025-03-01T00:00:00"
      }
    ]
  }
}
```

---

## Error Codes

| Code | Description |
|------|-------------|
| 400 | Requête invalide (champs manquants, JSON malformé) |
| 401 | Non authentifié (token manquant ou expiré) |
| 403 | Accès refusé (rôle insuffisant) |
| 404 | Ressource non trouvée |
| 405 | Méthode HTTP non autorisée |
| 413 | Corps de requête trop volumineux (max 1 MB) |
| 429 | Trop de requêtes (rate limit) |
| 500 | Erreur serveur interne |

---

## Security Headers

All responses include:
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000`
- `Content-Security-Policy: default-src 'self'`
- `Referrer-Policy: strict-origin-when-cross-origin`

Rate limit headers:
- `X-RateLimit-Limit: 100`
- `X-RateLimit-Remaining: <n>`

Cache headers:
- `X-Cache: HIT|MISS`
