# AT Reservations — Gestion des Ordres de Mission

Application web et mobile de gestion des ordres de mission pour Algerie Telecom.

**Stack** : Laravel 12 + React 18 + Vite + Tailwind CSS + Flutter  
**Version** : 2.0 (aout 2026)

---

## Pre-requis a installer

Avant de commencer, installer ces logiciels sur le PC :

| Logiciel | Version minimum | Lien de telechargement |
|----------|----------------|----------------------|
| XAMPP | 8.2+ (PHP + MySQL) | https://www.apachefriends.org/download.html |
| Node.js | 18+ (LTS) | https://nodejs.org/ |
| Composer | 2.x | https://getcomposer.org/download/ |
| Git | 2.x | https://git-scm.com/downloads |
| Flutter | 3.10+ (pour le mobile) | https://docs.flutter.dev/get-started/install |
| Chrome | derniere version | https://www.google.com/chrome/ |

---

## Installation etape par etape

### Etape 1 — Cloner le projet

```bash
git clone https://github.com/michoumichou511-cyber/AT-r-servation.git
cd AT-r-servation
```

### Etape 2 — Demarrer MySQL (XAMPP)

1. Ouvrir **XAMPP Control Panel**
2. Cliquer **Start** sur **MySQL**
3. Verifier que le port **3306** est bien actif (vert)

### Etape 3 — Creer la base de donnees

Ouvrir un navigateur et aller sur `http://127.0.0.1/phpmyadmin` puis :
1. Cliquer **Nouvelle base de donnees** (ou **New**)
2. Nom : `at_reservations`
3. Interclassement : `utf8mb4_unicode_ci`
4. Cliquer **Creer**

### Etape 4 — Installer le Backend (Laravel)

```bash
cd backend
composer install
```

Copier le fichier d'environnement :
```bash
copy .env.example .env
```
*(Linux/macOS : `cp .env.example .env`)*

Editer le fichier `backend/.env` et verifier ces lignes :
```
APP_URL=http://127.0.0.1:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=at_reservations
DB_USERNAME=root
DB_PASSWORD=
```

> **IMPORTANT** : Toujours utiliser `DB_HOST=127.0.0.1` (jamais `localhost`)

Generer la cle et lancer les migrations :
```bash
php artisan key:generate
php artisan migrate
php artisan db:seed
```

Demarrer le serveur backend :
```bash
php artisan serve --port=8000
```

> Le backend tourne maintenant sur `http://127.0.0.1:8000`

### Etape 5 — Installer le Frontend (React)

Ouvrir un **nouveau terminal** (garder le backend ouvert) :

```bash
cd frontend
npm install
```

Demarrer le serveur frontend :
```bash
npm run dev
```

> Le frontend tourne maintenant sur `http://127.0.0.1:5173`

### Etape 6 — Ouvrir l'application

Ouvrir Chrome et aller sur : **http://127.0.0.1:5173**

Identifiants de test :

| Role | Email | Mot de passe |
|------|-------|-------------|
| Admin | admin@at.dz | Password@123 |
| Validateur | nadia.khelifi@at.dz | Password@123 |
| Demandeur | demandeur@at.dz | Password@123 |

---

## Installation de l'app mobile (optionnel)

```bash
cd mobile/at_reservations_mobile
flutter pub get
flutter run
```

> L'app mobile necessite un emulateur Android ou un telephone connecte en USB avec le mode developpeur active.

---

## Commandes utiles

| Commande | Description |
|----------|-------------|
| `php artisan serve --port=8000` | Demarrer le backend |
| `npm run dev` | Demarrer le frontend (dev) |
| `npm run build` | Build production du frontend |
| `php artisan migrate` | Lancer les migrations |
| `php artisan migrate:fresh --seed` | Reset complet de la BDD + donnees de test |
| `php artisan tinker` | Console interactive Laravel |
| `flutter run` | Lancer l'app mobile |

---

## Lancer les tests E2E (Playwright)

Les tests necessitent que le backend ET le frontend soient demarres.

**Terminal 1 :**
```bash
cd backend
php artisan serve --port=8000
```

**Terminal 2 :**
```bash
cd frontend
npm run dev
```

**Terminal 3 :**
```bash
cd frontend
npx playwright test
```

Resultats attendus : **43/43 tests PASS** (auth, navigation, CRUD, flux-mission, responsive, accessibilite, performance).

---

## Structure du projet

```
AT-r-servation/
├── backend/                 # API Laravel 12
│   ├── app/                 # Models, Controllers, Services
│   ├── database/            # Migrations, Seeders
│   ├── routes/api.php       # Routes API
│   └── .env.example         # Modele de configuration
│
├── frontend/                # React 18 + Vite + Tailwind
│   ├── src/
│   │   ├── components/      # Composants reutilisables
│   │   ├── pages/           # Pages de l'application
│   │   ├── contexts/        # AuthContext, etc.
│   │   └── services/        # Appels API
│   ├── tests/               # Tests Playwright E2E
│   └── package.json
│
├── mobile/                  # App Flutter
│   └── at_reservations_mobile/
│       ├── lib/             # Code Dart
│       └── pubspec.yaml     # Dependances Flutter
│
└── docs_soutenance/         # Documents pour la soutenance
```

---

## Fonctionnalites principales

- **Gestion des missions** : creation, soumission, validation, rejet, cloture
- **3 roles** : Admin, Validateur (DG/SG), Demandeur
- **Workflow complet** : Demandeur cree → Validateur approuve/rejette → DML traite la logistique
- **Dashboard** avec statistiques par role
- **Notifications** en temps reel
- **Messagerie** interne
- **Organigramme** de l'entreprise
- **Exports** Excel et PDF (ordre de mission)
- **Gestion DML** : reservations transport, hotel, per diem
- **Rapports** et audit logs
- **Responsive** : fonctionne sur mobile, tablette, desktop
- **Accessibilite** WCAG 2.1 AA

---

## Ports utilises

| Service | Port | URL |
|---------|------|-----|
| Frontend (Vite) | 5173 | http://127.0.0.1:5173 |
| Backend (Laravel) | 8000 | http://127.0.0.1:8000 |
| MySQL (XAMPP) | 3306 | 127.0.0.1:3306 |

---

## Securite du depot

- **Ne JAMAIS commiter** les fichiers `.env` (contiennent les secrets)
- Les fichiers `.env.example` sont les modeles sans secrets
- Apres clonage, toujours regenerer la cle : `php artisan key:generate`
- Si le depot doit rester prive : GitHub → Settings → Danger zone → Change visibility → Private

## Fichiers a ne jamais versionner

| Type | Exemples |
|------|----------|
| Environnement | `.env`, `.env.local`, `.env.production` |
| Dependances | `node_modules/`, `vendor/` |
| Build | `frontend/dist/`, caches Laravel |
| Logs | `storage/logs/`, `storage/framework/` |
| Certificats | `*.pem`, `*.key`, `id_rsa*` |

---

## En cas de probleme

| Probleme | Solution |
|----------|----------|
| "SQLSTATE connection refused" | Verifier que MySQL tourne dans XAMPP |
| "Email ou mot de passe incorrect" | Verifier que le backend tourne sur le port 8000 |
| Page blanche sur le frontend | Verifier que `npm run dev` est lance |
| "DB_HOST" erreur | Mettre `DB_HOST=127.0.0.1` (pas `localhost`) |
| Erreur `composer install` | Verifier que PHP 8.2+ est installe |
| Erreur `npm install` | Verifier que Node.js 18+ est installe |

---

**Projet realise par** : Michou — Formation Algerie Telecom 2026
