# Guide de Déploiement — YOB K Business

## Table des matières

1. [Prérequis](#prérequis)
2. [Déploiement local (développement)](#déploiement-local)
3. [Déploiement production (Docker)](#déploiement-production)
4. [Configuration SSL/HTTPS](#configuration-ssl)
5. [Déploiement Flutter Web](#déploiement-flutter-web)
6. [Déploiement mobile](#déploiement-mobile)
7. [Monitoring & maintenance](#monitoring)

---

## Prérequis

| Outil | Version min | Usage |
|-------|-------------|-------|
| Docker | 24+ | Conteneurisation |
| Docker Compose | 2.20+ | Orchestration |
| FVM | 3.0+ | Gestion Flutter |
| Flutter | 3.27.0 | Build frontend |
| Dart | 3.6.0 | Build backend |

---

## Déploiement local

### 1. Base de données

```bash
docker compose up -d
```

Vérifie la santé :
```bash
docker compose ps
# postgres devrait être "healthy"
```

### 2. API (mode développement)

```bash
cd packages/yob_api
fvm dart_frog dev
```

L'API sera disponible sur `http://localhost:8080`.

### 3. Application Flutter

```bash
cd apps/yob_app

# Web (développement)
fvm flutter run -d chrome

# Android
fvm flutter run -d <device_id>

# iOS
fvm flutter run -d <simulator_id>
```

---

## Déploiement production

### 1. Préparer l'environnement

```bash
# Copier le template d'environnement
cp .env.example .env
```

Éditer `.env` avec des valeurs sécurisées :
```env
DB_PASSWORD=VotreMotDePasseSecurise2025!
JWT_SECRET=$(openssl rand -hex 32)
API_PORT=8080
```

### 2. Lancer avec Docker Compose

```bash
# Build et démarrage
docker compose -f docker-compose.prod.yml up -d --build

# Vérifier le statut
docker compose -f docker-compose.prod.yml ps

# Voir les logs
docker compose -f docker-compose.prod.yml logs -f api
```

### 3. Avec Nginx (recommandé)

```bash
docker compose -f docker-compose.prod.yml --profile with-nginx up -d --build
```

### 4. Appliquer les migrations de performance

```bash
# Se connecter au container PostgreSQL
docker exec -it yob_postgres_prod psql -U yob_admin -d yob_kbusiness

# Appliquer les index de performance
\i /docker-entrypoint-initdb.d/002_performance_indexes.sql
```

### 5. Vérifier le déploiement

```bash
# Test de santé API
curl http://localhost:8080/

# Réponse attendue :
# {"name":"YOB K Business API","version":"0.1.0","status":"running"}
```

---

## Configuration SSL

### Option A : Let's Encrypt (recommandé)

```bash
# 1. Installer certbot
apt install certbot

# 2. Générer les certificats
certbot certonly --standalone -d votre-domaine.com

# 3. Copier dans le répertoire nginx
mkdir -p nginx/ssl
cp /etc/letsencrypt/live/votre-domaine.com/fullchain.pem nginx/ssl/
cp /etc/letsencrypt/live/votre-domaine.com/privkey.pem nginx/ssl/

# 4. Décommenter le bloc HTTPS dans nginx/nginx.conf
# 5. Relancer nginx
docker compose -f docker-compose.prod.yml --profile with-nginx restart nginx
```

### Option B : Certificat auto-signé (test)

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/privkey.pem \
  -out nginx/ssl/fullchain.pem \
  -subj "/CN=localhost"
```

---

## Déploiement Flutter Web

### Build statique

```bash
cd apps/yob_app
fvm flutter build web --release --no-tree-shake-icons
```

Le build se trouve dans `apps/yob_app/build/web/`.

### Hébergement

**Option 1 : Nginx (même serveur)**
```bash
# Copier le build web dans le container nginx
docker cp apps/yob_app/build/web/. yob_nginx:/usr/share/nginx/html/
```

**Option 2 : Firebase Hosting**
```bash
firebase init hosting
firebase deploy
```

**Option 3 : Vercel / Netlify**
- Pointer le répertoire de build vers `apps/yob_app/build/web`

### Configuration de l'URL API

Avant le build, configurer l'URL de l'API de production dans l'application :
```dart
// Dans lib/core/services/api_service.dart
// Modifier le baseUrl pour pointer vers l'API de production
final baseUrl = 'https://api.votre-domaine.com/api/v1';
```

---

## Déploiement mobile

### Android

```bash
cd apps/yob_app

# Build APK
fvm flutter build apk --release

# Build App Bundle (Play Store)
fvm flutter build appbundle --release
```

L'APK se trouve dans : `build/app/outputs/flutter-apk/app-release.apk`
L'AAB se trouve dans : `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
cd apps/yob_app

# Build
fvm flutter build ios --release

# Ouvrir dans Xcode pour archiver
open ios/Runner.xcworkspace
```

Puis dans Xcode : Product > Archive > Distribute App

---

## Monitoring

### Logs Docker

```bash
# Tous les services
docker compose -f docker-compose.prod.yml logs -f

# API uniquement
docker compose -f docker-compose.prod.yml logs -f api

# PostgreSQL
docker compose -f docker-compose.prod.yml logs -f postgres
```

### Santé des services

```bash
# Vérifier le statut des conteneurs
docker compose -f docker-compose.prod.yml ps

# Test API
curl -s http://localhost:8080/ | jq

# Test connexion DB
docker exec yob_postgres_prod pg_isready -U yob_admin
```

### Sauvegardes

```bash
# Backup de la base de données
docker exec yob_postgres_prod pg_dump -U yob_admin yob_kbusiness > backup_$(date +%Y%m%d).sql

# Restauration
cat backup.sql | docker exec -i yob_postgres_prod psql -U yob_admin yob_kbusiness
```

### Mise à jour

```bash
# 1. Pull des dernières modifications
git pull origin main

# 2. Rebuild et redéployer
docker compose -f docker-compose.prod.yml up -d --build

# 3. Appliquer les nouvelles migrations si nécessaire
docker exec -it yob_postgres_prod psql -U yob_admin -d yob_kbusiness -f /docker-entrypoint-initdb.d/new_migration.sql
```

---

## Ressources

| Ressource | Lien |
|-----------|------|
| Documentation API | [docs/api-reference.md](api-reference.md) |
| Spécifications | [docs/scope.md](scope.md) |
| Flutter | https://flutter.dev |
| Dart Frog | https://dartfrog.vgv.dev |
| PostgreSQL | https://www.postgresql.org/docs/16/ |
