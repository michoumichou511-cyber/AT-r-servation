# MODIFICATIONS — AMELIORATIONS SUIVANTES

## Objectifs
1. Rendre `AuditLog.created_at` systématiquement rempli (robustesse dashboard).
2. Ajouter la confirmation manquante pour `Restauration` afin que le workflow d’évaluation soit cohérent.

## Changements
1. `app/Models/AuditLog.php`
   - Remplir `created_at` dans `creating` si null (même si `$timestamps = false`).
2. `app/Http/Controllers/Api/RestaurationController.php`
   - Ajouter méthode `confirmer()` (admin uniquement) : passe `restaurations.statut` à `confirme`, notifie le demandeur, et écrit un `AuditLog` avec des valeurs compatibles avec les ENUM.
3. `routes/api.php`
   - Ajouter route `POST /restaurations/{id}/confirmer`.

## Vérification
- `php test_routes.php` doit rester OK (200/201).

