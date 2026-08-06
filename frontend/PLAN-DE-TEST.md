# Plan de Test E2E — AT Reservations

**Version** : 2.0
**Date** : 05/08/2026
**Auteur** : Claude Code (tests automatises + manuels)
**Application** : AT Reservations — Gestion des ordres de mission
**Stack** : React 18 + Vite + Tailwind CSS / Laravel 12 + Sanctum / MySQL

---

## 1. Perimetre

| Suite | Description | Nb tests |
|-------|-------------|----------|
| AUTH | Authentification multi-roles, logout, redirect | 11 |
| NAV | Navigation, sidebar, acces par role | 8 |
| FLUX-MISSION | Creation → validation → approbation/rejet | 5 |
| CRUD | Missions, prestataires, utilisateurs, notifications | 8 |
| RESPONSIVE | Mobile 375px, tablette 768px, desktop 1920px | 3 |
| ACCESSIBILITE | WCAG 2.1 AA via axe-core | 4 |
| PERFORMANCE | Temps de chargement, erreurs 500 | 4 |
| **TOTAL** | | **43** |

## 2. Environnement de test

| Element | Valeur |
|---------|--------|
| Frontend | http://127.0.0.1:5173 (Vite dev server) |
| Backend | http://127.0.0.1:8000 (Laravel artisan serve) |
| Database | MySQL 127.0.0.1:3306 via XAMPP |
| Navigateur | Chromium (Browser Pane intgre) |
| OS | Windows 11 Pro |
| Outil automatise | Playwright 1.52+ (fichiers crees, non executables — voir note) |

## 3. Comptes de test

| Role | Email | Mot de passe |
|------|-------|-------------|
| Admin | admin@at.dz | Password@123 |
| Validateur | nadia.khelifi@at.dz | Password@123 |
| Demandeur | demandeur@at.dz | Password@123 |

## 4. Suite AUTH — Authentification

| # | Cas de test | Precondition | Action | Resultat attendu |
|---|-------------|-------------|--------|-------------------|
| A1 | Login admin | Page /login | Saisir admin@at.dz / Password@123 | Redirect vers /, dashboard admin |
| A2 | Login validateur | Page /login | Saisir nadia.khelifi@at.dz / Password@123 | Redirect vers /, dashboard validateur |
| A3 | Login demandeur | Page /login | Saisir demandeur@at.dz / Password@123 | Redirect vers /, dashboard demandeur |
| A4 | Mauvais mot de passe | Page /login | admin@at.dz / wrongpassword | Message erreur, reste sur /login |
| A5 | Email inexistant | Page /login | fake@at.dz / Password@123 | Message erreur, reste sur /login |
| A6 | Champs vides | Page /login | Soumettre formulaire vide | Validation cote client |
| A7 | Logout | Connecte | Cliquer Deconnexion | Redirect vers /login, token supprime |
| A8 | Redirect non-auth | Non connecte | Naviguer vers /missions | Redirect vers /login |
| A9 | Dashboard admin | Connecte admin | Verifier contenu | Stats missions, taux, budget |
| A10 | Dashboard validateur | Connecte validateur | Verifier contenu | Missions a valider, compteurs |
| A11 | Dashboard demandeur | Connecte demandeur | Verifier contenu | Mes demandes, actions rapides |

## 5. Suite NAV — Navigation

| # | Cas de test | Action | Resultat attendu |
|---|-------------|--------|-------------------|
| N1 | Admin — toutes pages | Naviguer chaque lien sidebar | Toutes pages accessibles |
| N2 | Demandeur — pages autorisees | Naviguer missions, messagerie, profil | Pages accessibles |
| N3 | Demandeur — pages admin bloquees | Naviguer /admin/statistiques | Redirect vers /403 |
| N4 | Validateur — sidebar correcte | Verifier liens sidebar | Pas de pages admin |
| N5 | Admin — sidebar admin | Verifier liens sidebar | Pages admin visibles |
| N6 | Missions via sidebar | Cliquer "Mes missions" | Page /missions charge |
| N7 | Notifications via sidebar | Cliquer "Notifications" | Page /notifications charge |
| N8 | Messagerie via sidebar | Cliquer "Messagerie" | Page /messagerie charge |

## 6. Suite FLUX-MISSION — Workflow complet

| # | Cas de test | Action | Resultat attendu |
|---|-------------|--------|-------------------|
| F1 | Creer mission | Demandeur remplit wizard 4 etapes | Mission creee, visible dans liste |
| F2 | Mission dans liste | Admin/validateur consulte /missions | Mission visible avec statut "En attente" |
| F3 | Validateur voit mission | Validateur va sur /validations | Mission dans liste avec boutons |
| F4 | Approuver mission | Validateur clique "Approuver" | Statut change, notification envoyee |
| F5 | Rejeter mission | Validateur clique "Rejeter" | Statut change, motif requis |

## 7. Suite CRUD

| # | Cas de test | Action | Resultat attendu |
|---|-------------|--------|-------------------|
| C1 | Liste missions | Naviguer /missions | Liste avec filtres, pagination |
| C2 | Detail mission | Cliquer une mission | Page detail avec infos completes |
| C3 | Liste prestataires | Naviguer /admin/prestataires | Liste avec boutons CRUD |
| C4 | Creer prestataire | Cliquer "+ Nouveau" | Formulaire creation |
| C5 | Liste utilisateurs | Naviguer /admin/utilisateurs | Liste avec filtres role/direction/statut |
| C6 | Notifications | Naviguer /notifications | Liste notifications, compteur |
| C7 | Messagerie | Naviguer /messagerie | Conversations, messages |
| C8 | Audit Logs | Naviguer /admin/audit-logs | Journal filtrable, export CSV |

## 8. Suite RESPONSIVE

| # | Cas de test | Viewport | Resultat attendu |
|---|-------------|----------|-------------------|
| R1 | Mobile | 375x667 | Pas de scroll horizontal, menu hamburger |
| R2 | Tablette | 768x1024 | Layout adapte, sidebar repliable |
| R3 | Desktop | 1920x1080 | Layout complet, sidebar visible |

## 9. Suite ACCESSIBILITE

| # | Cas de test | Page | Resultat attendu |
|---|-------------|------|-------------------|
| AC1 | Login | /login | WCAG 2.1 AA conforme (axe-core) |
| AC2 | Dashboard | / | WCAG 2.1 AA conforme |
| AC3 | Missions | /missions | WCAG 2.1 AA conforme |
| AC4 | Nouvelle mission | /missions/new | WCAG 2.1 AA conforme |

## 10. Suite PERFORMANCE

| # | Cas de test | Seuil | Resultat attendu |
|---|-------------|-------|-------------------|
| P1 | Page login | < 5s | Formulaire visible en moins de 5s |
| P2 | Dashboard apres login | < 8s | Contenu charge en moins de 8s |
| P3 | Navigation entre pages | < 5s | Chaque page charge en moins de 5s |
| P4 | Erreurs 500 | 0 | Aucune reponse API en erreur 500 |

## 11. Fichiers Playwright (reference)

```
frontend/
  playwright.config.ts
  tests/
    helpers/
      auth.helper.ts
      test-data.ts
    auth.spec.ts
    navigation.spec.ts
    flux-mission.spec.ts
    crud.spec.ts
    responsive.spec.ts
    accessibility.spec.ts
    performance.spec.ts
```

## 12. Note technique

Les tests Playwright automatises ont ete entierement codes mais ne sont pas executables sur cet environnement en raison d'un probleme de connectivite reseau : le navigateur headless Chromium de Playwright ne parvient pas a joindre les services localhost (127.0.0.1:8000 et 127.0.0.1:5173) — timeout systematique malgre un fonctionnement normal via curl et le navigateur standard. Ce probleme est specifique a la configuration Windows 11 / Playwright headless sur cette machine.

Les tests ont donc ete executes **manuellement** via le navigateur integre avec verification systematique des erreurs console et des reponses API.
