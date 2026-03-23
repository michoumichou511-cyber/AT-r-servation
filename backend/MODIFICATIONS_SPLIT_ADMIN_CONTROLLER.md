# MODIFICATIONS — SPLIT ADMIN CONTROLLER

## Objectif
Découper `AdminController` pour améliorer la séparation des responsabilités sans casser les routes existantes.

## Nouveaux contrôleurs
1. `app/Http/Controllers/Api/AdminUserController.php`
   - `listeUtilisateurs`, `activerDesactiver`, `changerRole`
2. `app/Http/Controllers/Api/AdminPrestataireController.php`
   - `listePrestataires`, `prestaFavoris`, `toggleFavori`, `evaluerPrestataire`, `evaluationsPrestataire`
   - `creerPrestataire`, `modifierPrestataire`, `supprimerPrestataire`
3. `app/Http/Controllers/Api/AdminBudgetController.php`
   - `gererBudgets`, `creerBudget`, `modifierBudget`
4. `app/Http/Controllers/Api/AdminAuditController.php`
   - `auditLogs`

## Routes migrées
- `routes/api.php` bascule les endpoints prestataires/admin vers les nouveaux contrôleurs.
- Les chemins et signatures d’API ne changent pas.

## Vérification
- `php test_routes.php`
- `php artisan test`

## Résultat vérification
- `php test_routes.php` : OK (routes admin/prestataires/export/évaluation)
- `php artisan test` : 20 tests passés

