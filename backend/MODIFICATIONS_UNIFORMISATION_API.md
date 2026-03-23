# Uniformisation des réponses JSON — ApiResponse

**Date :** 2026-03-18  
**Objectif :** Remplacer tous les `response()->json()` directs par le helper `ApiResponse` afin d'avoir une structure JSON cohérente dans tout le backend.

---

## Contrôleurs mis à jour

| Contrôleur | Occurrences remplacées |
|---|---|
| `AdminUserController` | 9 |
| `AdminBudgetController` | 6 |
| `AdminAuditController` | 2 |
| `AdminPrestataireController` | 14 |
| `BilletController` | 7 |
| `HebergementController` | 7 |
| `RestaurationController` | 7 |
| `ReservationController` | 9 |

---

## Règles d'uniformisation appliquées

| Ancienne forme | Nouvelle forme |
|---|---|
| `response()->json(['error' => '...'], 403)` | `ApiResponse::forbidden()` |
| `response()->json(['error' => '...'], 400)` | `ApiResponse::error('...', 400)` |
| `response()->json(['error' => '...'], 409)` | `ApiResponse::error('...', 409)` |
| `response()->json(['message' => '...'], 201)` | `ApiResponse::created([...], '...')` |
| `response()->json(['message' => '...'])` | `ApiResponse::success([...], '...')` |
| `response()->json(['error' => '...'], 500)` | `ApiResponse::error('...', 500)` |

---

## Structure JSON unifiée

**Succès (200/201):**
```json
{
  "success": true,
  "message": "...",
  "data": { ... }
}
```

**Erreur (4xx/5xx):**
```json
{
  "success": false,
  "message": "...",
  "errors": { ... }
}
```

**Paginé:**
```json
{
  "success": true,
  "message": "...",
  "data": [ ... ],
  "pagination": { "total": ..., "per_page": ..., "current_page": ..., "last_page": ... }
}
```

---

## test_routes.php mis à jour

Les vérifications de la structure des réponses dans `test_routes.php` ont été adaptées au nouveau format `ApiResponse` (avec compatibilité ascendante pour l'ancien format).

---

## Vérification

- **`php artisan test` :** 20/20 tests PASSÉS ✅
- **`php test_routes.php` :** toutes les routes OK ✅

---

## Aucune fonctionnalité supprimée

Seule la forme des réponses JSON a changé. Toute la logique métier est intacte.

---

## Améliorations de performance — Backend AT Réservations

**Date :** 2026-03-18  
**Objectif :** Accélérer le backend en production, sans toucher aucune fonctionnalité.

### 1. Index de base de données manquants

**Migration :** `2026_03_18_200000_add_missing_performance_indexes.php`

| Table | Colonnes indexées | Utilité |
|---|---|---|
| `validations` | `validateur_id, statut` | Dashboard validateur (3+ COUNT queries) |
| `evaluations_prestataires` | `prestataire_id` | Calcul stats évaluations |
| `evaluations_prestataires` | `user_id, prestataire_id` | Contrôle anti-doublons |
| `notifications_custom` | `user_id, lue` | Compteur non-lues en temps réel |
| `missions` | `statut, date_depart` | Alertes missions urgentes |

### 2. Dashboard : 9 COUNT séparés → 1 requête

**Fichier :** `app/Services/DashboardService.php`

**Avant :** plusieurs requêtes SQL pour compter les statuts missions + 2 pour les réservations = **11 requêtes**.

**Après :** 1 seule requête avec `SUM(statut = '...')` pour les missions + 1 pour les réservations = **2 requêtes**.

### 3. Notifications admins : INSERT en masse

**Fichier :** `app/Http/Controllers/Api/MissionController.php`

**Avant :** pour chaque admin → 1 requête INSERT (N requêtes).

**Après :** `NotificationCustom::insert([...])` → 1 requête pour tous les admins.

### 4. Alertes budget : filtrage SQL

**Fichier :** `app/Http/Controllers/Api/DashboardController.php`

**Avant :** `Budget::all()` puis boucle PHP.

**Après :** requête SQL filtrée : `Budget::whereRaw(...)` pour ne charger que les budgets en alerte.

### 5. Cache dashboard : 60 secondes par utilisateur

**Fichier :** `app/Http/Controllers/Api/DashboardController.php`

Mise en cache 60s de `/api/dashboard/stats` par utilisateur (évite les recalculs continus).

### Vérification

- **`php artisan migrate` :** index appliqués ✅
- **`php test_routes.php` :** toutes les routes OK ✅

