# AT Réservation — Laravel API Skill

## Déclenchement automatique
Active cette skill quand tu travailles sur l'intégration API, les appels axios/fetch, ou la gestion d'authentification.

## Architecture API
- Base URL: variable d'env VITE_API_URL (Railway)
- Auth: Sanctum (tokens Bearer)
- Headers obligatoires: Authorization, Accept: application/json, X-Requested-With: XMLHttpRequest

## Endpoints principaux (structure Laravel)
- POST /api/login → { token, user }
- POST /api/logout → révoque le token
- GET /api/reservations → liste paginée
- POST /api/reservations → créer
- PUT /api/reservations/{id} → modifier
- DELETE /api/reservations/{id} → supprimer

## Gestion d'erreurs obligatoire
- 401 → rediriger vers /login, clear token
- 422 → afficher erreurs de validation inline sur le formulaire
- 500 → toast d'erreur générique, log en console

## Stores Zustand / React Query
- Utiliser React Query (TanStack Query) pour le cache et les mutations
- Zustand pour l'état auth uniquement (user, token, isAuthenticated)

