# YOB K BUSINESS

**Plateforme de gestion agricole intégrée pour la Côte d'Ivoire**

> *L'agriculture notre passion*

---

## Aperçu

YOB K BUSINESS est un système complet de gestion agricole conçu pour les coopératives et entreprises agricoles ivoiriennes. Il centralise la gestion des producteurs, parcelles, forages, kits agricoles, formations, finances et investisseurs en une seule application unifiée.

### Valeur créée

| Pour qui | Valeur |
|----------|--------|
| **Banques** | Outil de crédibilité — données financières fiables |
| **Investisseurs** | Outil de confiance — suivi de projet transparent |
| **Direction Générale** | Tableau de bord stratégique — pilotage en temps réel |
| **Opérations terrain** | Application mobile — enregistrement, GPS, photos |

---

## Stack technique

| Composant | Technologie |
|-----------|-------------|
| **Frontend** | Flutter 3.27.0 (Web + Mobile) |
| **State Management** | Riverpod 2.6 |
| **Routing** | GoRouter 14.8 |
| **Backend** | Dart Frog 1.1 (REST API) |
| **Base de données** | PostgreSQL 16 |
| **Auth** | JWT + bcrypt |
| **Conteneurisation** | Docker + Docker Compose |
| **CI/CD** | GitHub Actions |

### Structure du projet (Monorepo Melos)

```
YOB-KBUSINESS/
├── apps/
│   └── yob_app/              # Application Flutter (Web + Mobile)
├── packages/
│   ├── yob_core/             # Modèles, enums, constantes partagés
│   └── yob_api/              # Serveur Dart Frog (API REST)
├── docs/                     # Documentation & specs
├── nginx/                    # Configuration Nginx (production)
├── docker-compose.yml        # Développement local
├── docker-compose.prod.yml   # Déploiement production
└── melos.yaml                # Configuration du monorepo
```

---

## Prérequis

- **FVM** (Flutter Version Management) — [Installation](https://fvm.app/)
- **Docker** & **Docker Compose**
- **Melos** — `dart pub global activate melos`

---

## Installation rapide

### 1. Cloner le projet

```bash
git clone <repository-url>
cd YOB-KBUSINESS
```

### 2. Installer les dépendances

```bash
fvm use 3.27.0
melos bootstrap
```

### 3. Démarrer la base de données

```bash
docker compose up -d
```

### 4. Démarrer le serveur API

```bash
cd packages/yob_api
fvm dart_frog dev
```

Le serveur démarre sur `http://localhost:8080`.

### 5. Lancer l'application Flutter

```bash
cd apps/yob_app

# Web
fvm flutter run -d chrome

# Mobile (iOS / Android)
fvm flutter run
```

### Compte administrateur par défaut

| Champ | Valeur |
|-------|--------|
| Email | `admin@yobkbusiness.com` |
| Mot de passe | `admin123` |

> ⚠️ Changez ce mot de passe en production.

---

## Modules

### 1. Authentification & Gestion des utilisateurs
- Connexion sécurisée (email/mot de passe)
- Routage et permissions basés sur les rôles (RBAC)
- Tokens JWT avec refresh automatique

### 2. Producteurs
- Enregistrement complet (nom, contact, localité, photo, pièce d'identité)
- Surface cultivée, historique des cultures
- Suivi du niveau de production
- Gestion par statut : Actif / En formation / Suspendu

### 3. Parcelles & Foncier
- Enregistrement avec localisation GPS
- Surface, type de culture, statut foncier
- Suivi Commodo/Incommodo

### 4. Forages & Infrastructures
- Suivi des forages (coût, prestataire, avancement)
- Dates de début/fin, photos de chantier
- Programmation de maintenance

### 5. Kits Agricoles
- Distribution par bénéficiaire
- Valeur monétaire, statut (Remboursé / Subventionné)

### 6. Formations
- Listing des sessions, suivi de présence
- Évaluations, notes, certifications

### 7. Finances (Module critique)
- Suivi recettes/dépenses en FCFA
- Trésorerie en temps réel avec alertes de seuil
- Rapports mensuels automatiques
- Aperçu santé financière en 1 clic

### 8. Investisseurs & Partenaires
- Registre d'investisseurs
- Montant investi, projet associé, rendement attendu
- Envoi automatique de rapports par email

### 9. Tableau de Bord Stratégique (Vue DG)
- KPIs : producteurs, hectares, production, trésorerie
- Projets actifs avec barres de progression
- Panneau d'alertes urgentes
- Graphiques et activité récente

---

## Rôles utilisateur

| Rôle | Accès |
|------|-------|
| **Direction (Admin/DG)** | Accès complet — tableau de bord, tous les modules |
| **Superviseur Terrain** | Producteurs, parcelles, kits, formations, forages |
| **Comptable** | Module finances — écritures, trésorerie, rapports |
| **Partenaire/Investisseur** | Lecture seule — rapports d'investissement |

---

## API REST

Base URL : `http://localhost:8080/api/v1`

### Endpoints principaux

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/auth/login` | Connexion |
| `POST` | `/auth/register` | Inscription |
| `POST` | `/auth/refresh` | Rafraîchir le token |
| `GET` | `/auth/me` | Profil utilisateur |
| `GET/POST` | `/producers` | Liste / Créer producteur |
| `GET/PUT/DELETE` | `/producers/:id` | Détail / Modifier / Supprimer |
| `GET/POST` | `/parcels` | Liste / Créer parcelle |
| `GET/POST` | `/boreholes` | Liste / Créer forage |
| `GET/POST` | `/kits` | Liste / Créer kit |
| `GET/POST` | `/trainings` | Liste / Créer formation |
| `GET/POST` | `/finances/transactions` | Liste / Créer transaction |
| `GET` | `/finances/summary` | Résumé financier |
| `GET` | `/finances/treasury` | Trésorerie en temps réel |
| `GET` | `/finances/report` | Rapport mensuel |
| `GET/POST` | `/investors` | Liste / Créer investisseur |
| `GET` | `/investors/portfolio` | Portefeuille global |
| `POST` | `/investors/reports` | Envoyer rapport email |
| `GET` | `/dashboard` | Stats tableau de bord |

### Format de réponse

```json
{
  "success": true,
  "data": { ... }
}
```

### Authentification

Toutes les routes (sauf `/auth/login` et `/auth/register`) nécessitent un header :

```
Authorization: Bearer <jwt_token>
```

---

## Sécurité

- **Rate Limiting** — 100 requêtes/min (API), 10 requêtes/min (auth)
- **Security Headers** — HSTS, X-Frame-Options, CSP, X-Content-Type-Options
- **Input Validation** — Sanitisation des entrées, validation JSON
- **Request Size Limit** — Corps de requête limité à 1 MB
- **CORS** — Configuration Cross-Origin
- **JWT** — Tokens signés avec expiration, refresh tokens

---

## Fonctionnalités hors-ligne (Mobile)

- Détection automatique de la connectivité
- Cache local SQLite pour consultation hors-ligne
- File d'attente de synchronisation pour les opérations d'écriture
- Bannière visuelle indiquant le statut de connexion
- Synchronisation automatique au retour en ligne

---

## Export de données

- **PDF** — Rapports formatés avec branding YOB (tableaux, résumés financiers, rapports investisseurs)
- **CSV** — Export Excel compatible UTF-8 pour producteurs, transactions, investisseurs, parcelles
- **Partage** — Export via `Share` natif (mobile) ou téléchargement (web)

---

## Tests

```bash
# Tous les tests
melos run test

# Par package
cd packages/yob_core && fvm dart test
cd packages/yob_api && fvm dart test
cd apps/yob_app && fvm flutter test
```

**Couverture :**
- 52 tests unitaires (modèles, enums, JWT, notifications, export CSV)
- Tests de sérialisation JSON (fromJson/toJson round-trip)
- Tests de widgets Flutter

---

## Déploiement

### Développement local

```bash
docker compose up -d        # Base de données
cd packages/yob_api
fvm dart_frog dev            # API (port 8080)
```

### Production

```bash
# 1. Configurer l'environnement
cp .env.example .env
# Éditer .env avec les vrais mots de passe

# 2. Déployer avec Docker Compose
docker compose -f docker-compose.prod.yml up -d --build

# 3. (Optionnel) Avec Nginx reverse proxy
docker compose -f docker-compose.prod.yml --profile with-nginx up -d --build
```

### Build Flutter

```bash
# Web
cd apps/yob_app
fvm flutter build web --release

# Android APK
fvm flutter build apk --release

# iOS
fvm flutter build ios --release
```

### CI/CD (GitHub Actions)

Le pipeline CI s'exécute automatiquement sur push/PR vers `main` et `develop` :

1. **Analyze** — Lint et analyse statique
2. **Test** — Exécution de tous les tests unitaires
3. **Build Web** — Build de l'app web (sur `main`)
4. **Build Android** — Build de l'APK (sur `main`)
5. **Docker** — Build et push de l'image API vers GitHub Container Registry

---

## Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|--------|
| `DB_HOST` | Hôte PostgreSQL | `localhost` |
| `DB_PORT` | Port PostgreSQL | `5432` |
| `DB_NAME` | Nom de la base | `yob_kbusiness` |
| `DB_USER` | Utilisateur DB | `yob_admin` |
| `DB_PASSWORD` | Mot de passe DB | `yob_dev_password` |
| `DB_MAX_CONNECTIONS` | Pool de connexions max | `10` |
| `JWT_SECRET` | Secret JWT | (auto-généré en dev) |
| `API_PORT` | Port API exposé | `8080` |

---

## Licence

Projet propriétaire — YOB K BUSINESS © 2025
