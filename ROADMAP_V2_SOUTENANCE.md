# 🗺️ ROADMAP V2 — Préparation Soutenance AT Réservations

> **Date soutenance** : début septembre 2026
> **Démarrage** : 23 juin 2026
> **Durée totale** : ~10 semaines (70 jours)
> **Objectif score** : passer de **14-15/20** à **18-19/20**

---

## 🎯 Stratégie d'ordre des étapes

L'ordre est défini par **3 critères** :
1. **Risque technique** (le plus risqué en premier = plus de temps pour débugger)
2. **Dépendances** (les changements qui en bloquent d'autres = priorité)
3. **Gain points / effort** (impact jury)

```
Étape 1 │ 🔴 Sécurité Tokens         │ S1-S2 juillet │ HAUTE PRIORITÉ
Étape 2 │ 🟠 Tests Backend           │ S3-S4 juillet │ Sécurise les refacto suivants
Étape 3 │ 🔴 Validation Frontend     │ S1-S2 août    │ UX + cohérence
Étape 4 │ 🟠 Documentation Swagger   │ S3 août       │ Quand API est stable
Étape 5 │ 🟡 Policies + Exceptions   │ S4 août       │ Refacto authorization
Étape 6 │ 🟡 Refactor Frontend (DRY) │ S1 septembre  │ Custom hooks
Étape 7 │ 🎓 Polish + Soutenance     │ S2 septembre  │ Captures + slides
```

---

## ✅ Règle d'or : 100% validé avant l'étape suivante

**Pour CHAQUE étape** :
1. ✅ Code écrit et committé
2. ✅ Tests automatiques passent (npm test + php artisan test)
3. ✅ Build frontend OK (npm run build → exit 0)
4. ✅ Vérification fonctionnelle en navigateur
5. ✅ Push origin main + déploiement Vercel/Railway OK
6. ✅ Documentation mise à jour
7. ✅ Score audit Copilot recalculé

**Pas de passage à l'étape suivante sans ces 7 validations.**

---

# 📌 ÉTAPE 1 — Sécurité Tokens httpOnly (S1-S2 juillet)

## 🎯 Objectif
Éliminer la **vulnérabilité XSS** liée au stockage du token en `localStorage`. Migration vers cookies httpOnly + SameSite + Secure.

## 🛠 Outils/MCPs requis
- ✅ Claude Code (refactor multi-fichier)
- ✅ Bash/PowerShell (déploiement)
- ⚠️ **Sentry MCP** (à authentifier pour monitoring prod) → je te demanderai
- ⚠️ **GitHub MCP** (à authentifier pour gestion PR)

## 📋 Sous-tâches

### Backend Laravel
- [ ] Modifier `AuthController::login()` → retourner cookie httpOnly
- [ ] Modifier `AuthController::logout()` → supprimer cookie
- [ ] Configurer `config/cors.php` → `supports_credentials: true`
- [ ] Configurer `config/sanctum.php` → stateful domains
- [ ] Tester que `Bearer token` reste compatible (rétrocompat mobile Flutter)
- [ ] Ajouter middleware `EnsureFrontendRequestsAreStateful`

### Frontend React
- [ ] Modifier `services/api.js` → `withCredentials: true`
- [ ] Retirer `localStorage.setItem('at_token', ...)` partout
- [ ] Retirer interceptor Bearer (sauf si mobile coexistence)
- [ ] Modifier `AuthContext.jsx` (login/logout/me)
- [ ] Tester localStorage VIDE en DevTools

### Mobile Flutter
- [ ] Vérifier que mobile continue d'utiliser Bearer (cookies inutiles)
- [ ] Pas de breaking change mobile

### Refresh Tokens
- [ ] Token court 1h + refresh token 7j
- [ ] Endpoint `/api/auth/refresh`
- [ ] Auto-refresh côté Axios (interceptor 401)

### Déploiement
- [ ] Variables Vercel `VITE_API_URL` + CORS Railway
- [ ] Tester E2E login → mission → logout sur prod (ngrok)
- [ ] Configurer Sentry pour alertes erreurs 401/500

## ✅ Critères de validation
- ✅ DevTools → Application → Cookies → `auth_token` avec `HttpOnly: ✓`
- ✅ localStorage **VIDE** côté frontend (aucun `at_token`)
- ✅ Login fonctionne sur prod Vercel
- ✅ Auto-refresh marche après 1h
- ✅ Tests Playwright passent
- ✅ Sentry capture les 401 correctement

## ⏱ Estimation
**5-7 jours** (1.5 semaines) — risque cross-domain Vercel/Railway

## 📊 Gain score
**+3 à +4 points** : Sécurité 5/10 → 9/10

## 🚨 Risques
- Cross-domain cookies (Vercel + Railway) → SameSite=None obligatoire en prod
- Mobile Flutter à tester (peut casser si backend change comportement)
- CORS preflight à bien configurer

---

# 📌 ÉTAPE 2 — Tests Backend (S3-S4 juillet)

## 🎯 Objectif
Atteindre **40% coverage backend** minimum (vs ~2% actuel). Focus sur les chemins critiques.

## 🛠 Outils/MCPs requis
- ✅ Claude Code
- ✅ PHPUnit (déjà inclus dans Laravel)
- ✅ GitHub MCP (CI Actions)
- ⚠️ Skill `sparc:tdd` (TDD methodology)

## 📋 Sous-tâches

### Setup
- [ ] `composer require --dev pestphp/pest` (optionnel, plus fluide)
- [ ] Configuration `phpunit.xml` (coverage)
- [ ] Factory `UserFactory`, `MissionFactory`, `RoleFactory`

### Tests Auth (lié Étape 1)
- [ ] `AuthControllerTest::test_user_can_login_with_valid_credentials`
- [ ] `AuthControllerTest::test_user_cannot_login_with_invalid_password`
- [ ] `AuthControllerTest::test_authenticated_user_can_access_me`
- [ ] `AuthControllerTest::test_user_can_logout`
- [ ] `AuthControllerTest::test_login_sets_httponly_cookie` (validation Étape 1)
- [ ] `AuthControllerTest::test_refresh_token_works`

### Tests Mission
- [ ] `MissionControllerTest::test_user_can_create_mission`
- [ ] `MissionControllerTest::test_admin_can_list_all`
- [ ] `MissionControllerTest::test_user_cannot_update_submitted`
- [ ] `MissionControllerTest::test_validateur_can_approve`
- [ ] `MissionControllerTest::test_validateur_cannot_reject_without_motif` (lié FIX-2)

### Tests Service métier
- [ ] `MissionServiceTest::test_submit_creates_validation_circuit`
- [ ] `MissionServiceTest::test_submit_fails_without_reservations`
- [ ] `MissionServiceTest::test_cancel_works_only_on_draft`

### Tests Validation/Reservation
- [ ] `ValidationApiTest` (existe déjà → enrichir)
- [ ] `ReservationControllerTest`

### CI/CD
- [ ] GitHub Action `.github/workflows/tests.yml`
- [ ] Run tests on push + PR
- [ ] Badge coverage dans README

## ✅ Critères de validation
- ✅ `php artisan test` → tous verts
- ✅ Coverage ≥ 40% (`./vendor/bin/phpunit --coverage-text`)
- ✅ CI GitHub Action passe sur main
- ✅ Au moins 20 tests créés

## ⏱ Estimation
**6-8 jours** (1.5-2 semaines)

## 📊 Gain score
**+3 à +4 points** : Tests 2/10 → 6/10

## 🚨 Risques
- Tests fragiles si non-isolés (DB seeding)
- Mocking complexe (Mail::queue, Storage)

---

# 📌 ÉTAPE 3 — Validation Frontend React Hook Form (S1-S2 août)

## 🎯 Objectif
Validation **temps-réel** dans tous les formulaires. UX professionnelle.

## 🛠 Outils/MCPs requis
- ✅ Claude Code
- ✅ npm packages : `react-hook-form`, `zod`, `@hookform/resolvers`

## 📋 Sous-tâches

### Setup
- [ ] `npm install react-hook-form zod @hookform/resolvers`
- [ ] Créer `frontend/src/lib/schemas/` (dossier schemas Zod)
- [ ] Créer hook `useFormField` (helper)
- [ ] Créer composants `<FormInput>`, `<FormError>`, `<FormLabel>`

### Schemas Zod (typage centralisé)
- [ ] `missionSchema` (NewMissionWizard)
- [ ] `loginSchema` (Login)
- [ ] `registerSchema` (Register)
- [ ] `reservationSchema`
- [ ] `userSchema` (AdminUsers)
- [ ] `validationSchema` (commentaire reject obligatoire)

### Refacto formulaires
- [ ] `Login.jsx` → React Hook Form + zodResolver
- [ ] `Register.jsx`
- [ ] `NewMissionWizard.jsx` (5 étapes, le plus gros)
- [ ] `NewReservation.jsx`
- [ ] `AdminUsers.jsx`
- [ ] Forms validation (FIX-2 motif rejet)

### Messages d'erreur
- [ ] Messages FR custom (`min`, `max`, `email`, etc.)
- [ ] Toast d'erreur cohérent (`react-hot-toast`)
- [ ] Style inline rouge sous chaque champ

## ✅ Critères de validation
- ✅ Tous formulaires affichent erreurs temps-réel (onBlur ou onChange)
- ✅ Soumission bloquée si erreur
- ✅ Messages FR clairs
- ✅ Build OK (`npm run build`)
- ✅ E2E Playwright passe

## ⏱ Estimation
**6-8 jours**

## 📊 Gain score
**+3 à +5 points** : Validation 3/10 → 8/10

---

# 📌 ÉTAPE 4 — Documentation OpenAPI/Swagger (S3 août)

## 🎯 Objectif
Documentation auto-générée de l'API. UI Swagger interactive sur `/api/documentation`.

## 🛠 Outils/MCPs requis
- ✅ Claude Code
- ✅ `composer require darkaonline/l5-swagger`

## 📋 Sous-tâches

### Setup
- [ ] `composer require darkaonline/l5-swagger`
- [ ] `php artisan vendor:publish --provider "L5Swagger\L5SwaggerServiceProvider"`
- [ ] Configurer `config/l5-swagger.php`

### Annotations
- [ ] `AuthController` (login, logout, me, refresh)
- [ ] `MissionController` (CRUD + actions custom)
- [ ] `ValidationController`
- [ ] `ReservationController`
- [ ] `UserController` (admin)
- [ ] `DocumentController` (upload)
- [ ] `NotificationController`

### Schemas
- [ ] `Mission`, `User`, `Role`, `Reservation`, `Validation`, `Document`
- [ ] `LoginRequest`, `MissionStoreRequest`, etc.
- [ ] Responses standard (200, 401, 403, 404, 422, 429)

### Génération
- [ ] `php artisan l5-swagger:generate`
- [ ] Tester UI sur `/api/documentation`
- [ ] Authentification Swagger UI (Bearer token)

## ✅ Critères de validation
- ✅ UI Swagger accessible sur prod
- ✅ Tous endpoints annotés (~30 routes)
- ✅ Tester chaque endpoint depuis UI Swagger
- ✅ Export JSON OpenAPI 3.0

## ⏱ Estimation
**4-5 jours**

## 📊 Gain score
**+2 à +3 points** : Documentation 3/10 → 7/10

---

# 📌 ÉTAPE 5 — Policies Laravel + Custom Exceptions (S4 août)

## 🎯 Objectif
Remplacer authorization manuelle par Policies. Custom exceptions explicites.

## 🛠 Outils/MCPs requis
- ✅ Claude Code

## 📋 Sous-tâches

### Policies
- [ ] `MissionPolicy` (view, update, delete, submit, cancel)
- [ ] `ValidationPolicy` (view, approve, reject)
- [ ] `ReservationPolicy`
- [ ] `UserPolicy` (admin only)
- [ ] `DocumentPolicy`
- [ ] Enregistrer dans `AuthServiceProvider`
- [ ] Remplacer les `if ($user->role->name === 'admin')` par `$this->authorize('action', $model)`

### Custom Exceptions
- [ ] `InvalidMissionStatusException` (mission non modifiable)
- [ ] `BudgetExceededException`
- [ ] `ValidationRejectMotifRequiredException`
- [ ] `ReservationConflictException`
- [ ] Handler central dans `Exceptions/Handler.php`

### Logging
- [ ] Logger toutes les actions critiques (`AuditLog`)
- [ ] Niveaux info/warning/error cohérents
- [ ] Format JSON pour parsing (Logstash, Elastic, etc.)

## ✅ Critères de validation
- ✅ `$this->authorize()` utilisé dans tous controllers
- ✅ Logique de rôles centralisée dans Policies
- ✅ Tests Policies (PolicyTest)
- ✅ Exceptions custom avec codes HTTP appropriés

## ⏱ Estimation
**4-5 jours**

## 📊 Gain score
**+1 à +2 points** : Sécurité 9/10 → 9.5/10, Code quality 7/10 → 8/10

---

# 📌 ÉTAPE 6 — Refactor Frontend Custom Hooks (S1 septembre)

## 🎯 Objectif
Réduire duplication. Pages plus lisibles. DRY principle.

## 🛠 Outils/MCPs requis
- ✅ Claude Code

## 📋 Sous-tâches

### Custom Hooks
- [ ] `useAsyncData(apiFn, deps)` — fetch générique
- [ ] `useFormField(name)` — already in Étape 3
- [ ] `useDebounce(value, delay)` — déjà partiellement
- [ ] `usePagination(initial)` — pagination centralisée
- [ ] `useFilters(initial)` — filtres centralisés

### Components extraits
- [ ] `<DataTable>` (générique avec tri, pagination)
- [ ] `<FilterBar>` (search + dropdown)
- [ ] `<EmptyState>` (déjà partiel)
- [ ] `<LoadingState>`
- [ ] `<ErrorState>` (avec retry)

### Refacto pages
- [ ] `MissionsList.jsx` → utiliser hooks + components
- [ ] `ValidationsList.jsx`
- [ ] `Notifications.jsx`
- [ ] `Utilisateurs.jsx`
- [ ] Decompose `Dashboard.jsx` en sous-composants

## ✅ Critères de validation
- ✅ -30% LOC sur les pages refactorisées
- ✅ Pas de duplication fetch try/catch
- ✅ Build OK
- ✅ E2E Playwright passe

## ⏱ Estimation
**5-6 jours**

## 📊 Gain score
**+1 à +2 points** : Code quality 8/10 → 9/10

---

# 📌 ÉTAPE 7 — Polish + Soutenance (S2 septembre)

## 🎯 Objectif
Finaliser captures, mémoire PDF, slides, répétitions.

## 📋 Sous-tâches

### Captures nouvelle UI
- [ ] Re-capturer toutes les pages clés (Dashboard, Missions, Validations, Admin)
- [ ] Mode dark + light
- [ ] Mobile + desktop

### Mémoire PDF
- [ ] Mettre à jour avec nouveaux diagrammes (v2)
- [ ] Ajouter section "Perspectives" (déjà 80% faites)
- [ ] Annexes : Swagger spec, coverage report, security audit

### Slides PowerPoint
- [ ] Storyboard 15 slides max
- [ ] Vidéo cinematic 25s intégrée
- [ ] Démo live prévue + plan B (vidéo)

### Répétitions
- [ ] Soutenance blanche 1
- [ ] Soutenance blanche 2 (chronométrée)
- [ ] Q&A préparées (Annexe Copilot critique)

## ⏱ Estimation
**5-7 jours**

---

# 📊 MCPs requis (à valider/installer)

| MCP | Status | Action |
|---|---|---|
| ✅ Higgsfield | Installé, auth OK web | Pour visuels |
| ✅ Invideo | Connecté | Pour vidéo |
| ✅ Mermaid | Connecté | Diagrammes |
| ✅ drawio/uml-mcp | Connecté | Diagrammes |
| 🟡 Sentry | Installé, **needs auth** | Étape 1 — je te donnerai le lien OAuth |
| 🟡 GitHub | Installé, status à vérifier | Étape 2 (CI) — je te donnerai lien |
| ❓ **MySQL MCP** | Non installé | À installer en Étape 2 (debug DB) |
| ❓ **Playwright MCP** | Non installé | À installer en Étape 3 (E2E) |

---

# 🎯 Score final attendu

```
Étape 1 (Sécurité Tokens)         : +3 pts
Étape 2 (Tests Backend)            : +3 pts
Étape 3 (Validation Frontend)      : +4 pts
Étape 4 (Swagger Documentation)    : +2 pts
Étape 5 (Policies + Exceptions)    : +1 pt
Étape 6 (Refactor Frontend)        : +1 pt
─────────────────────────────────────
TOTAL GAIN                         : +14 pts

Score actuel       : 14-15/20 (70-75%)
Score après V2     : 18-19/20 (90-95%)
```

---

# 🚀 Process de validation par étape

À la fin de chaque étape :

```bash
# 1. Tests
cd backend && php artisan test
cd ../frontend && npm test

# 2. Build
cd ../frontend && npm run build

# 3. Lint (à ajouter)
npm run lint

# 4. Audit Copilot recalculé (manuel)
# 5. Commit + push
git add . && git commit -m "feat(étape-X): description" && git push

# 6. Vérification déploiement Vercel
# 7. Vérification déploiement Railway
# 8. Tests E2E sur prod
```

---

# ❓ Avant de commencer — Validation requise

1. **Tu valides cet ordre des 7 étapes ?**
2. **Tu acceptes que chaque étape soit committée + pushée séparément ?**
3. **MCPs nécessaires** :
   - Sentry MCP : tu veux que je relance l'auth OAuth ?
   - MySQL MCP : OK pour installer ?
   - Playwright MCP : OK pour installer ?

Si tout est OK, on démarre par **Étape 1 — Sécurité Tokens**.
