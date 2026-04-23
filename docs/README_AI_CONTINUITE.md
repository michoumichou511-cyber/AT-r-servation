# Guide de continuité IA (autre PC)

Ce document sert à reprendre rapidement le projet sur une autre machine avec Cursor + Agent.

## 1) Contexte projet

- Repo principal: `origin` (`AT-r-servation`)
- Frontend: `frontend/` (React + Vite)
- Backend: `backend/` (Laravel API)
- Base API locale attendue: `http://127.0.0.1:8000/api`
- Frontend local attendu: `http://127.0.0.1:5177`

## 2) Ce qui a été ajouté/amélioré

- Tests E2E Playwright intégrés au projet (pas Postman):
  - `frontend/playwright.config.js`
  - `frontend/tests/ui-smoke.spec.js`
  - `frontend/tests/perf-audit.spec.js`
  - `frontend/tests/e2e-full-app.spec.js`
- Scripts npm E2E ajoutés dans `frontend/package.json`:
  - `e2e`, `e2e:smoke`, `e2e:full`, `e2e:perf`, `e2e:headed`, `e2e:ui`, `e2e:report`
- Correctifs API/UX sur:
  - stats admin, exports, polling notifications/messages, messagerie, loaders mission detail
- Correctif anti-clignotement messagerie:
  - polling silencieux côté `Messagerie.jsx`

## 3) Installation rapide (autre PC)

### Backend

1. Aller dans `backend/`
2. Installer dépendances:
   - `composer install`
3. Configurer `.env` (DB, APP_KEY, etc.)
4. Migrations/seed:
   - `php artisan migrate --seed`
5. Lancer API:
   - `php artisan serve --host=127.0.0.1 --port=8000`

### Frontend

1. Aller dans `frontend/`
2. Installer dépendances:
   - `npm install`
3. Vérifier `frontend/.env.development`:
   - `VITE_API_URL=http://127.0.0.1:8000/api`
4. Installer navigateur Playwright:
   - `npx playwright install chromium`
5. Lancer frontend:
   - `npm run dev -- --host 127.0.0.1 --port 5177`

## 4) Lancer les tests

- Smoke multi-profils:
  - `npm run e2e:smoke`
- Full workflow:
  - `npm run e2e:full`
- Perf audit:
  - `npm run e2e:perf`
- Rapport HTML Playwright:
  - `npm run e2e:report`

## 5) MCP Chrome DevTools (Cursor)

Le projet contient `.cursor/mcp.json` avec:

- serveur MCP: `chrome-devtools`
- commande: `npx -y chrome-devtools-mcp@latest`

### Utilisation typique

Dans un prompt Cursor Agent, demander explicitement:

- "Utilise chrome-devtools-mcp pour tester le flow login"
- "Utilise chrome-devtools-mcp pour vérifier les requêtes réseau de /messagerie"

Si le MCP n’est pas exposé dans la session, redémarrer Cursor et vérifier que le serveur MCP est actif.

## 6) Skills Cursor présentes dans ce repo

- `.cursor/skills/at-reservation-brand/SKILL.md`
- `.cursor/skills/at-reservation-laravel/SKILL.md`

## 7) Points d’attention connus

- Instabilité intermittente login UI en test headless (selon run)
- Certains flows exports peuvent réussir côté API mais ne pas toujours lever l’event download Playwright selon timing UI
- En cas de 500 DB/API, prioriser:
  - `php artisan tinker --execute="DB::connection()->getPdo();"`
  - lecture logs Laravel

## 8) Prompt recommandé pour un agent sur autre PC

Utiliser un prompt de reprise comme:

"Lis `docs/README_AI_CONTINUITE.md`, exécute `npm run e2e:smoke`, puis donne-moi un rapport PASS/FAIL par rôle (admin, validateur, demandeur, utilisateur) et propose les corrections minimales."

