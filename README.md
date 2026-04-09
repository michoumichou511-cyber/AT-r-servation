# AT-r-servation

Projet de formation : application web de réservation / gestion de missions (Laravel + React / Vite).

## Sécurité du dépôt

- **Visibilité GitHub** : si le dépôt doit rester confidentiel, ouvre le dépôt sur GitHub → **Settings** → tout en bas → **Danger zone** → **Change repository visibility** → **Private**.
- **Clé d’application Laravel** : après clonage ou déploiement, génère une clé unique et mets à jour le fichier `.env` réel (machine locale et serveur) :

  ```bash
  cd backend
  php artisan key:generate
  ```

  La commande écrit `APP_KEY` dans `backend/.env`. Ne commite jamais ce fichier.

- **Secrets déjà exposés** : si des fichiers `.env` ou des clés ont été poussés sur un dépôt public ou forké, considère comme **compromis** : régénère `APP_KEY`, mots de passe base de données, clés API, secrets mail, etc.

## Fichiers à ne jamais versionner (Laravel + React)

À garder **hors** du dépôt (et couverts par les `.gitignore` du projet) :

| Type | Exemples |
|------|----------|
| Environnement | `.env`, `.env.local`, `.env.production`, `.env.backup`, `frontend/.env`, `backend/.env` |
| Dépendances | `node_modules/`, `vendor/` |
| Build | `frontend/dist/`, caches Laravel |
| Logs / cache | `storage/logs/`, `storage/framework/`, `bootstrap/cache/` |
| Certificats / clés | `*.pem`, `*.key`, `id_rsa*`, certificats SSL, keystores |
| Bases locales | `*.sqlite`, dumps `.sql` avec données réelles |
| Auth Composer privé | `auth.json` (JetBrains Packagist, etc.) |
| Fichiers IDE sensibles | secrets dans `.vscode/` si tu y mets des tokens (le dépôt ignore `.vscode/` par défaut) |

Les seuls fichiers d’environnement **versionnés** doivent être des modèles : `.env.example` (racine, `backend/`, `frontend/`).

## Prérequis

- Node.js (LTS recommandé) pour le frontend
- PHP + Composer pour le backend
- MySQL ou PostgreSQL (selon ta configuration Laravel)

## Installation à partir des `.env.example`

### Backend (Laravel)

1. `cd backend`
2. `composer install`
3. Copie le modèle d’environnement :

   ```bash
   copy .env.example .env
   ```

   (Sous Linux/macOS : `cp .env.example .env`)

4. Édite `.env` : `APP_URL`, base de données (`DB_*`), mail, etc.
5. `php artisan key:generate`
6. `php artisan migrate` (et seeders si besoin)

### Frontend (Vite + React)

1. `cd frontend`
2. `npm install`
3. Copie le modèle :

   ```bash
   copy .env.example .env
   ```

   (Sous Linux/macOS : `cp .env.example .env`)

4. Ajuste les variables (ex. `VITE_API_URL` vers l’URL de ton API Laravel).
5. Développement : `npm run dev`  
   Production : `npm run build` puis sers les fichiers générés avec ton hébergeur / reverse proxy.

### Racine

Un fichier `.env.example` peut exister à la racine pour des scripts ou la doc ; adapte-le à ton usage. L’essentiel pour l’app est **`backend/.env`** et **`frontend/.env`**.

## Déploiement

- Backend : configure le serveur web (nginx, Apache, etc.) vers `backend/public`, variables d’environnement ou `.env` sur le serveur uniquement.
- Frontend : `npm run build` dans `frontend/`, puis hébergement des assets statiques ou intégration au pipeline CI/CD.
