# Fonctionnalités — pages Admin & application

Ce document décrit **l’utilité**, le **contenu attendu**, les **droits d’accès**, et les raisons possibles d’un écran **vide** ou d’un **message d’erreur**.

## Rôles & accès (résumé)

- **Admin**: accès à tout + pages d’administration (`/admin/*`) + rapports.
- **Validateur**: accès aux validations + rapports (selon `PrivateRoute`), missions (lecture), messagerie, notifications, profil, organigramme.
- **Demandeur**: création/édition/soumission de missions, documents, messagerie, notifications, profil, organigramme.
- **Utilisateur**: lecture (selon règles du backend), messagerie, notifications, profil, organigramme.

> Les pages réellement visibles dépendent des `PrivateRoute` côté frontend **et** des middlewares backend (`auth:sanctum`, `role:admin`, etc.).

---

## 1) Tableau de bord (`/`)

- **Utilité**: vue synthèse (stats, alertes, raccourcis, états des missions).
- **Données**: dépend de missions/validations/réservations existantes. Si la base est vide → widgets souvent “0 / vide”.
- **Qui voit**: tous les rôles (contenu adapté côté API).

---

## 2) Mes missions (`/missions`)

- **Utilité**: liste des missions (filtrage, états: brouillon/soumis/approuvé/rejeté…).
- **Contenu attendu**: au moins les missions créées via seed/démo.
- **Vide pourquoi**:
  - aucune mission en DB pour l’utilisateur
  - filtre trop restrictif
  - API instable / erreur serveur

---

## 3) Détail mission (`/missions/:id`)

- **Utilité**: consulter infos + réservations + documents + historique.
- **Points clés**:
  - **Documents** et **Historique** dépendent d’endpoints dédiés; si endpoint 500 → risque de loader/skeleton.

---

## 4) Validations (`/validations`)

- **Utilité**: valider / rejeter les missions soumises.
- **Qui voit**: `validateur` + `admin`.
- **Vide pourquoi**:
  - aucune mission au statut “soumis” assignée / visible
  - règles métier: seules certaines missions remontent au validateur

---

## 5) Messagerie (`/messagerie`)

- **Utilité**: échanges internes entre comptes (admin ↔ demandeur, etc.).
- **Vide pourquoi**:
  - aucune conversation existante (il faut en démarrer une)
  - endpoint `/api/conversations` en erreur
- **Bug connu (reload/flicker)**:
  - si le polling remet `loading` à `true`, la liste peut “clignoter”.
  - correction: polling silencieux (ne pas écraser l’UI pendant le refresh).

---

## 6) Notifications (`/notifications`)

- **Utilité**: suivre événements (validation, changement de statut, actions admin…).
- **Vide pourquoi**:
  - aucune notification générée
  - DB seed sans événements

---

## 7) Mon profil (`/profil`)

- **Utilité**: infos compte, mot de passe, préférences, stats perso.
- **Qui voit**: tous les rôles.

---

## 8) Organigramme (`/organigramme`)

- **Utilité**: afficher structure AT + panel détail + recherche.
- **Données**:
  - structure: statique (document officiel) + noms fictifs
  - “utilisateurs affectés”: dynamique via `/api/users/by-structure`
- **Retour**:
  - quand on clique un nœud, un **panneau** s’ouvre; bouton retour/fermer doit permettre de revenir à la vue.

---

# Pages ADMIN

## A) Utilisateurs (`/admin/utilisateurs`)

- **Utilité**: gestion comptes (activer/désactiver, changer rôle, filtrer).
- **Qui voit**: admin uniquement.
- **Vide pourquoi**:
  - pagination/filtre
  - seed pas exécuté

---

## B) Prestataires (`/admin/prestataires`)

- **Utilité**: annuaire prestataires (hôtels, compagnies, etc.) + éventuellement stats/évaluations.
- **Qui voit**: admin uniquement.
- **Vide pourquoi**:
  - table `prestataires` vide (aucun seed/données)
  - c’est normal en environnement de démo si aucun prestataire n’a été créé.

---

## C) Budgets (`/admin/budgets`)

- **Utilité**: budgets par direction/service/année, suivi consommation.
- **Qui voit**: admin uniquement.
- **Vide pourquoi**:
  - table `budgets` vide (pas de seed)
  - aucun budget pour l’année sélectionnée

---

## D) Audit logs (`/admin/audit-logs`)

- **Utilité**: traçabilité (qui a fait quoi: login/create/update/delete/approve/reject/export).
- **Qui voit**: admin uniquement.
- **Vide pourquoi**:
  - aucun log n’a été créé (feature passive)
  - ou logs bloqués si `audit_logs.action/module` reçoivent une valeur non autorisée (ENUM) → erreurs serveur possibles.

---

## E) Statistiques (`/admin/statistiques`)

- **Utilité**: stats globales (missions par mois, budgets alloués/consommés, regroupements).
- **Qui voit**: admin uniquement.
- **Erreur “problème d’affichage”**:
  - survient si l’API `/api/admin/statistiques` renvoie une erreur (500/401/timeout) ou une forme inattendue.

---

## F) Rapports / Exports (`/rapports`)

- **Utilité**: exports (missions Excel/PDF, dépenses, prestataires, rapport direction).
- **Qui voit**: admin + validateur (selon frontend).
- **Erreurs typiques**:
  - **429**: throttling trop strict sur routes export.
  - **500**: bug backend (ex: écriture audit_logs avec module/action invalides; colonnes DB manquantes; requêtes SQL).

