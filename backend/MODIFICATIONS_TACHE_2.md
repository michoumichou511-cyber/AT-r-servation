# MODIFICATIONS TACHE 2 — EVALUATION PRESTATAIRES

## Changements
1. Migration : création table `evaluations_prestataires` (avec FK + `unique(user_id, reservation_id)`).
2. Nouveau modèle : `app/Models/EvaluationPrestataire.php` (fillable + casts + relations).
3. Modèle : ajout relation `Prestataire::evaluations()`.
4. Contrôleur : ajout de `AdminController::evaluerPrestataire()` et `AdminController::evaluationsPrestataire()`.
   - Ajustement : sélection Eloquent `user:id,prenom,nom,email` (car `users.name` n'existe pas chez toi).
   - Ajustement : valeurs `AuditLog.action/module` remplacées par des valeurs autorisées (ENUM) pour éviter une erreur SQL 500.
5. Routes : ajout des endpoints
   - `POST /api/prestataires/{id}/evaluer`
   - `GET /api/prestataires/{id}/evaluations`
6. Tests : mise à jour de `test_routes.php` pour vérifier les statuts `201`/`200` et la présence de `stats.note_globale`.

7. Correction SQL : ajout migration de la colonne manquante `prestataires.nombre_evaluations` (sinon 500).
8. Correction logging : ajustement de `AuditLog.action/module` dans `evaluerPrestataire()` pour respecter les ENUM de `audit_logs` (sinon 500).

## Vérification
- `php test_routes.php` : OK sur
  - `GET /api/export/missions/excel` (xlsx)
  - `POST /api/prestataires/{id}/evaluer` (201)
  - `GET /api/prestataires/{id}/evaluations` (200 avec `stats.note_globale`)

