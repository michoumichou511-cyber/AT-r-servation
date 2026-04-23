# Rapport d'audit application AT Réservations

Date: 2026-04-20
Auteur: Assistant Cursor
Périmètre: backend Laravel, frontend React, API, rôles, interface, performance.

## 1) Objectif demandé

Vérifier le fonctionnement global de l'application:
- exécution backend/frontend,
- fonctionnement des pages et boutons,
- appels frontend vers backend,
- profils/roles,
- anomalies de chargement et de statistiques,
- temps de réaction et risques de drop FPS,
- sans correction métier immédiate.

## 2) Démarrage et environnement vérifiés

- Repo détecté: `C:\Users\loulou\ProjetFinFormation`
- Backend: `php artisan serve --host=127.0.0.1 --port=8000`
- Frontend: `npm run dev -- --host 127.0.0.1 --port 5175`
- Frontend build: `npm run build` (succès, warnings non bloquants)
- API healthcheck: `GET /api/health` = 200
- Frontend index: `GET /` sur 5175 = 200

## 3) Vérifications fonctionnelles API effectuées

### Authentification

Comptes testés:
- `admin@at.dz` / `Password@123` -> OK
- `validateur@at.dz` / `Password@123` -> OK
- `demandeur@at.dz` / `Password@123` -> OK
- `utilisateur@at.dz` / `Password@123` -> KO (401)
- `user@at.dz` / `Password@123` -> OK (compte "utilisateur" réel dans seed)

Conclusion:
- Le compte utilisateur seedé est `user@at.dz` et non `utilisateur@at.dz`.

### Endpoints principaux

Vérifiés avec token (admin principalement):
- `/api/auth/me` -> OK
- `/api/dashboard/stats` -> OK
- `/api/dashboard/alertes` -> OK
- `/api/notifications/non-lues/count` -> OK
- `/api/notifications` -> OK
- `/api/conversations` -> OK
- `/api/missions` -> OK
- `/api/admin/utilisateurs` -> OK
- `/api/admin/budgets` -> OK
- `/api/admin/audit-logs` -> OK

Anomalies confirmées:
- `GET /api/admin/statistiques` -> 404
- `GET /api/admin/prestataires` -> 405 (route non exposée en GET sous `/admin`)

### Contrôle d'accès par rôle

Résultats mesurés:
- Validateur:
  - `/api/validations` -> 200
  - `/api/admin/utilisateurs` -> 403 (attendu)
  - `/api/dashboard/validateur` -> 200
- Demandeur:
  - `/api/missions` -> 200
  - `/api/validations` -> 403 (attendu)
  - `/api/admin/utilisateurs` -> 403 (attendu)
  - `/api/dashboard/validateur` -> 200 (non attendu)
- Utilisateur (`user@at.dz`):
  - `/api/missions` -> 200
  - `/api/validations` -> 403 (attendu)
  - `/api/admin/utilisateurs` -> 403 (attendu)
  - `/api/dashboard/validateur` -> 200 (non attendu)

Conclusion sécurité:
- L'endpoint `/api/dashboard/validateur` est trop permissif (accessible hors rôle validateur/admin).

## 4) Vérifications interface (UI) effectuées

Approche:
- Parcours automatisé Playwright des pages principales,
- surveillance des réponses API 4xx/5xx inattendues,
- vérification redirections login.

Pages parcourues:
- `/`
- `/missions`
- `/profil`
- `/notifications`
- `/messagerie`
- `/prestataires`
- `/validations`
- `/admin/utilisateurs`
- `/admin/budgets`
- `/admin/audit-logs`
- `/admin/prestataires`
- `/admin/statistiques`
- `/rapports`

Constats:
- Pour admin/demandeur/utilisateur: parcours UI globalement OK quand backend+DB répondent.
- Sur certains runs, login validateur/admin échoue non pas côté UI mais à cause d'une erreur backend DB (voir section 6).

## 5) Vérifications performance et fluidité (FPS/jank)

Méthode:
- Script Playwright de perf avec:
  - Navigation Timing (DCL/load),
  - Long Tasks API,
  - Heuristique RAF (gaps > 50 ms).

Résultats capturés (run sans login possible à cause DB):
- `/login`:
  - DCL ~ 282 ms, Load ~ 283 ms
  - long tasks: 1 (max ~ 60 ms)
  - raf jank count: 9, worst gap ~ 100 ms
- `/`:
  - DCL ~ 217 ms, Load ~ 243 ms
  - long tasks: 1 (max ~ 62 ms)
  - raf jank count: 8, worst gap ~ 167 ms
- `/missions`:
  - DCL ~ 263 ms, Load ~ 265 ms
  - long tasks: 1 (max ~ 57 ms)
  - raf jank count: 4, worst gap ~ 117 ms
- `/validations`:
  - DCL ~ 252 ms, Load ~ 255 ms
  - long tasks: 1 (max ~ 56 ms)
  - raf jank count: 6, worst gap ~ 133 ms
- `/admin/utilisateurs`:
  - DCL ~ 262 ms, Load ~ 262 ms
  - long tasks: 1 (max ~ 58 ms)
  - raf jank count: 5, worst gap ~ 150 ms

Interprétation:
- Réactivité initiale correcte.
- Présence de micro-jank à l'initialisation/montage.
- Mesure complète des pages connectées bloquée par indisponibilité DB intermittente.

Trace enregistrée:
- `frontend/test-results/perf-admin-trace.zip`

## 6) Blocage critique observé (infrastructure)

Erreur rencontrée en login UI et API:
- `SQLSTATE[HY000] [2002] Aucune connexion n’a pu être établie ... (Connection: mysql ...)`

Vérification réseau:
- Test TCP `127.0.0.1:3306` -> `TcpTestSucceeded: false`

Conclusion:
- MySQL indisponible/intermittent sur le port configuré.
- Ce point empêche une validation "100%" du parcours connecté en continu.

## 7) Incohérences et anomalies à suivre

1. `GET /api/admin/statistiques` introuvable (404)
- Impact: page admin statistiques non fonctionnelle.

2. Accès trop large à `/api/dashboard/validateur`
- Impact: fuite potentielle de données/écran non autorisé.

3. Compte démo utilisateur
- `user@at.dz` fonctionne, `utilisateur@at.dz` non.
- Impact: confusion de test.

4. Warnings build frontend
- Chunks volumineux > 500 kB.
- Warnings de perf à traiter ultérieurement (code splitting).

5. Warn console Vite relevé
- `THREE.THREE.Clock` déprécié (préférer `THREE.Timer`).

## 8) Fichiers inspectés pendant l'audit

Documentation / config:
- `README.md`
- `APPLICATION.md`
- `FRONTEND_STATUS.md`
- `backend/.env`
- `backend/.env.example`
- `frontend/.env`
- `frontend/.env.development`
- `frontend/package.json`
- `backend/composer.json`

Frontend (flux API/auth):
- `frontend/src/services/api.js`
- `frontend/src/contexts/AuthContext.jsx`
- `frontend/src/pages/auth/Login.jsx`

Backend (routes/seeds):
- `backend/routes/api.php`
- `backend/database/seeders/UserSeeder.php`

## 9) Fichiers ajoutés pour l'audit

Ajouts techniques effectués pour automatiser les vérifications:
- `frontend/tests/ui-smoke.spec.js`
- `frontend/tests/perf-audit.spec.js`

Note:
- Ces fichiers servent uniquement aux tests automatisés (Playwright).

## 10) Résumé exécutif

Etat général:
- L'application démarre.
- L'essentiel des routes critiques répond.
- Plusieurs parcours UI fonctionnent correctement.

Points bloquants majeurs:
- Instabilité/indisponibilité MySQL (bloque login et tests de bout en bout).
- Route admin statistiques absente (`/api/admin/statistiques`).
- Endpoint validateur trop permissif (`/api/dashboard/validateur`).

Etat de la vérification demandée:
- Vérification large effectuée (API, rôles, UI, perf).
- Validation exhaustive "tout partout en connecté" impossible tant que MySQL n'est pas stable.

