# AT Réservations — vue d’ensemble du projet

Document de référence pour comprendre le contenu du dépôt (frontend + backend). À partager avec un assistant (ex. Claude) pour contextualiser l’application sans parcourir tout le code.

---

## 1. Objectif métier

Application web de **gestion de missions** (déplacements professionnels) : création et suivi de missions, réservations (transport, hébergement, restauration), **circuit de validation**, messagerie interne, notifications, prestataires et budgets côté administration, exports et rapports.

---

## 2. Architecture du dépôt (monorepo)

| Partie | Chemin | Rôle |
|--------|--------|------|
| **Frontend** | `frontend/` | SPA React (Vite), consomme l’API REST |
| **Backend** | `backend/` | API Laravel 12, préfixe `/api` |
| **Déploiement Vercel** | `vercel.json` (racine) | Build du dossier `frontend/` → `frontend/dist` |

---

## 3. Stack technique

### Frontend (`frontend/package.json`)

- **React** 19, **Vite**, **React Router** 7
- **Axios** pour les appels HTTP
- **Bootstrap** 5, **Tailwind** (classes utilitaires dans les composants)
- UI / animation : **Framer Motion**, **GSAP**, **AOS**, **Lottie**, **react-hot-toast**
- Données / viz : **Chart.js**, **react-chartjs-2**, **Recharts**, **FullCalendar**
- Divers : **react-datepicker**, **react-dropzone**, **react-select**, **SweetAlert2**, **Splide**, etc.

### Backend (`backend/composer.json`)

- **PHP** ^8.2, **Laravel** ^12
- **Laravel Sanctum** — authentification API par token Bearer
- **barryvdh/laravel-dompdf** — PDF
- **maatwebsite/excel** — exports Excel
- **intervention/image** — traitement d’images (avatars, etc.)

### Base de données

- Développement local : souvent **SQLite** (voir `backend/.env.example`)
- Production typique : **PostgreSQL** (ex. Railway) — migrations compatibles multi-SGBD (dont index via `DetectsMigrationIndex`)

---

## 4. Authentification et rôles

- Connexion : `POST /api/auth/login` (throttle anti brute-force)
- Inscription : `POST /api/auth/register`
- Routes protégées : middleware `auth:sanctum`, `active`, throttle
- Token stocké côté client : `localStorage` clé `at_token` ; header `Authorization: Bearer …`
- **Rôles** (table `roles`, seed `RoleSeeder`) : `admin`, `validateur`, `utilisateur`, `demandeur` — permissions JSON (`can_validate`, `can_manage_users`, etc.)

**Comptes de démo** (à créer via seeders en local / après déploiement) : voir `UserSeeder` — emails du type `admin@at.dz`, `validateur@at.dz` avec mot de passe défini dans le seeder (ex. `Password@123` — **à changer en production**).

---

## 5. API REST (`backend/routes/api.php`)

Toutes les routes ci-dessous sont sous le préfixe **`/api`** (ex. `https://hôte/api/health`).

### Publiques

- `GET /health` — santé applicative
- `GET /test-email` — **test SMTP** (commentaire code : à retirer en production)
- `POST /auth/login`, `POST /auth/register` (throttle 5/min)

### Authentifiées (échantillon)

- **Auth / profil** : logout, me, mise à jour profil, changement mot de passe, avatar, statistiques profil
- **Missions** : CRUD, soumission, annulation, duplication, export PDF, historique, bons de commande liés, calendrier
- **Réservations** : par mission, CRUD billet / hébergement / restauration, confirmations
- **Validations** : file d’attente, mes validations, approuver / rejeter / demander modification
- **Notifications** : liste, compteur non lues, marquer lu / tout lire, suppression
- **Messagerie** : conversations, messages, envoi, non lus
- **Documents** : pièces jointes mission, téléchargement
- **Dashboard** : stats, missions du mois, dépenses par direction, alertes, vue validateur
- **Recherche** : `GET /search`
- **Prestataires** : liste, détail, favoris, évaluations
- **Exports** (throttle 10/h) : Excel/PDF missions, dépenses, prestataires

### Admin uniquement (`middleware role:admin`, préfixe `/api/admin/...`)

- Utilisateurs : liste, activer/désactiver, changer rôle
- Prestataires : CRUD complet
- Budgets : gestion
- Audit logs

---

## 6. Modèles Eloquent principaux (`backend/app/Models/`)

`User`, `Role`, `Mission`, `Reservation`, `Billet`, `BilletAvion`, `Hebergement`, `Restauration`, `BonCommande`, `Validation`, `CircuitValidation`, `Prestataire`, `EvaluationPrestataire`, `Document`, `NotificationCustom`, `Conversation`, `Message`, `Budget`, `AuditLog`.

---

## 7. Frontend — routes et pages (`frontend/src/App.jsx`)

| Route | Page / rôle |
|-------|----------------|
| `/login`, `/register` | Auth (redirige si déjà connecté) |
| `/` | Tableau de bord |
| `/missions`, `/missions/nouvelle`, `/missions/:id` | Liste, assistant création (étapes), détail |
| `/validations` | **validateur**, **admin** |
| `/messagerie`, `/notifications`, `/profil` | Tous utilisateurs connectés |
| `/rapports` | **admin**, **validateur** |
| `/admin/utilisateurs`, `/admin/prestataires`, `/admin/budgets`, `/admin/audit-logs`, `/admin/statistiques` | **admin** |
| `/403`, `*` | Accès refusé, 404 |

- **Lazy loading** des pages, **ErrorBoundary**, **AuthProvider**, gestion **401** via `setUnauthorizedHandler` (déconnexion + redirection login)
- **MainLayout** : sidebar, navbar, fond animé (`AnimatedBackground`, effets dashboard)

### Dossiers utiles

- `src/pages/` — écrans par domaine
- `src/components/` — layout, dashboard, UI réutilisable (`components/UI/`)
- `src/services/api.js` — client Axios et fonctions par domaine (auth, missions, etc.)
- `src/contexts/AuthContext.jsx` — session utilisateur

---

## 8. Client HTTP (`frontend/src/services/api.js`)

- `baseURL` : `import.meta.env.VITE_API_URL` si défini, sinon **URL de secours** codée en dur vers l’API Railway (à surcharger en production via variable Vercel)
- Intercepteurs : jeton Bearer, gestion globale des **401**

---

## 9. Déploiement

### Backend (Railway)

- **Dockerfile** : `php:8.2-cli`, extensions `gd`, `pdo_pgsql`, `zip`, etc.
- Entrée : `scripts/railway-entrypoint.sh` — serveur PHP intégré, `PORT` injecté par Railway
- Fichiers utiles : `public/railway-health.php`, health Laravel `/up`, route `/api/health`

### Frontend (Vercel)

- `vercel.json` : build `@vercel/static-build` sur `frontend/package.json`, sortie `frontend/dist`

---

## 10. Variables d’environnement (sans secrets)

### Backend — voir `backend/.env.example`

- `APP_*`, `DB_*` (connexion base)
- **`FRONTEND_URL`** — origine(s) CORS du frontend (plusieurs URLs séparées par des virgules si besoin)
- `MAIL_*` pour l’envoi d’e-mails (missions, tests, etc.)
- Session, cache, queue selon config Laravel

### Frontend

- **`VITE_API_URL`** — URL complète de l’API incluant `/api` (ex. `https://ton-backend.railway.app/api`)

Ne pas committer de fichiers `.env` contenant des secrets ; utiliser les variables du tableau de bord Vercel / Railway.

---

## 11. Tests backend

Répertoire `backend/tests/Feature/` : tests API (auth, missions, validations, rôles, audit, évaluations prestataires, etc.).

---

## 12. Emails (aperçu)

Templates Blade sous `backend/resources/views/emails/` : missions soumises, approuvées, rejetées — classes Mails associées dans `app/Mail/`.

---

## 13. Points d’attention pour la maintenance

- Retirer ou sécuriser **`/api/test-email`** en production
- Vérifier **CORS** (`FRONTEND_URL`) et **HTTPS** en prod
- Après déploiement : exécuter migrations + seeders si besoin de comptes initiaux
- Migrations d’index : logique **PostgreSQL / MySQL / SQLite** via `database/migrations/Concerns/DetectsMigrationIndex.php`

---

*Généré pour décrire l’état du dépôt ; mettre à jour ce fichier lors d’évolutions majeures (nouvelles routes, nouveaux rôles, changement d’hébergement).*
