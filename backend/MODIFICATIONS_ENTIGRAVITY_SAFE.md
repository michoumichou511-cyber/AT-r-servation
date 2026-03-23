# MODIFICATIONS — AMÉLIORATIONS “ENTIGRAVITY” (SAFE)

## Objectifs
1. Corriger le bug `is_active` dans `AdminController::listeUtilisateurs()`.
2. Ajouter un guard `null` dans `MissionService::getTimeline()` pour éviter tout crash si `validateur` est absent.
3. Ajouter quelques tests pour sécuriser les améliorations (sans casser les endpoints).

## Changements effectués
1. `app/Http/Controllers/Api/AdminController.php`
   - `is_active`: remplacement de `if ($request->has('is_active') !== null)` par `if ($request->filled('is_active'))`.
2. `app/Services/MissionService.php`
   - `getTimeline()`: guard `null` sur `$step->validateur`.
3. Scripts de debug
   - déplacement de `check_users.php` et `verify_setup.php` de la racine vers `backend/scripts/` (aucun impact runtime).

## Vérification
- `php test_routes.php`
- `php artisan test`

