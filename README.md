# AT-r-servation

Projet de formation : application web de réservation / gestion de missions.

## Prérequis
- Node.js (pour le frontend)
- PHP + Composer (pour le backend)
- Un serveur MySQL/PostgreSQL compatible avec ton backend

## Installation (rapide)
### Backend
1. `cd backend`
2. Installer les dépendances (ex: `composer install`)
3. Créer la configuration `.env` (souvent à partir de `.env.example`)
4. `php artisan key:generate`
5. Lancer les migrations si nécessaire

### Frontend
1. `cd frontend`
2. `npm install`
3. `npm run dev`

## Déploiement
- Tu peux utiliser `npm run build` pour générer le bundle de prod frontend, puis servir le backend.

