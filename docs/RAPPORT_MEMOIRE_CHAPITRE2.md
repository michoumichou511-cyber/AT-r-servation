# Rapport de Présentation du Système AT Réservations
## Chapitre 2 : Analyse et Conception du Système

Ce rapport présente une analyse détaillée de l'application AT Réservations, structurée pour servir de base au second chapitre d'un mémoire de fin de formation.

---

### 1. LES ACTEURS DU SYSTÈME

L'application repose sur quatre profils utilisateurs distincts, chacun ayant des niveaux d'accès spécifiques définis dans le code (Middleware `role`, `RoleSeeder`, et `AuthContext.jsx`).

*   **Administrateur (`admin`)** :
    *   **Rôle** : Super-utilisateur gérant l'ensemble de la plateforme.
    *   **Accès** : Gestion complète des utilisateurs (création, activation/désactivation), modification des rôles, gestion des prestataires, configuration des budgets, consultation des journaux d'audit (`audit_logs`) et accès aux statistiques globales.
*   **Validateur (`validateur`)** :
    *   **Rôle** : Responsable de la revue et de l'approbation des demandes.
    *   **Accès** : Visualisation de toutes les missions du système, approbation, rejet ou demande de modification des missions en attente, accès aux rapports et statistiques de validation.
*   **Utilisateur (`utilisateur`)** :
    *   **Rôle** : Collaborateur standard de l'entreprise.
    *   **Accès** : Création et gestion de ses propres ordres de mission, gestion de ses réservations (vol, hôtel, repas), messagerie interne et notifications.
*   **Demandeur (`demandeur`)** :
    *   **Rôle** : Profil restreint focalisé sur l'initiation des demandes.
    *   **Accès** : Création de missions. Souvent utilisé pour des rôles de secrétariat ou d'appui administratif.

---

### 2. LES CAS D'UTILISATION (PAR ACTEUR)

#### **Pour l'Administrateur**
*   **Gérer les utilisateurs** : Lister, créer, modifier le rôle, et activer/désactiver les comptes.
*   **Gérer les prestataires** : Ajouter des hôtels, compagnies aériennes, ou agences, et évaluer leur performance.
*   **Gérer les budgets** : Définir les enveloppes budgétaires par direction et par année/trimestre.
*   **Auditer le système** : Consulter l'historique des actions critiques via les logs d'audit.

#### **Pour le Validateur**
*   **Traiter les demandes** : Approuver, rejeter avec motif, ou renvoyer pour correction une mission.
*   **Suivre l'activité** : Visualiser le tableau de bord des validations et exporter des rapports PDF/Excel.

#### **Pour l'Utilisateur / Demandeur**
*   **Gérer les missions** : Créer (via un assistant étape par étape), modifier, soumettre, annuler ou dupliquer une mission.
*   **Gérer les réservations** : Ajouter des détails de transport (billets), d'hébergement (hôtels) et de restauration à une mission.
*   **Gérer les documents** : Téléverser des pièces jointes (ordre de mission signé, factures, billets).
*   **Communiquer** : Envoyer des messages aux autres utilisateurs et recevoir des notifications en temps réel.

---

### 3. LES MODÈLES ET DIAGRAMME DE CLASSES

L'application utilise l'ORM Eloquent de Laravel. Voici les principaux modèles et leurs relations :

*   **User** :
    *   *Attributs* : `nom`, `prenom`, `email`, `matricule`, `service`, `direction`, `role_id`, `is_active`.
    *   *Relations* : `belongsTo(Role)`, `hasMany(Mission)`, `hasMany(Reservation)`.
*   **Mission** :
    *   *Attributs* : `numero_unique`, `titre`, `objet_mission`, `destination_ville`, `date_depart`, `date_retour`, `statut` (brouillon, soumis, approuvé, etc.).
    *   *Relations* : `belongsTo(User)`, `hasMany(Reservation)`, `hasMany(CircuitValidation)`.
*   **Reservation** :
    *   *Attributs* : `type` (avion, hôtel, repas), `statut`, `montant_estime`, `montant_reel`.
    *   *Relations* : `belongsTo(Mission)`, `belongsTo(Prestataire)`, `hasOne(BilletAvion)`, `hasOne(Hebergement)`, `hasOne(Restauration)`.
*   **CircuitValidation** (Table `validations`) :
    *   *Attributs* : `mission_id`, `validateur_id`, `statut`, `commentaire`, `date_validation`.
    *   *Relations* : `belongsTo(Mission)`, `belongsTo(User, 'validateur_id')`.
*   **Prestataire** :
    *   *Attributs* : `nom`, `type`, `note_performance`, `is_active`.
    *   *Relations* : `hasMany(Reservation)`.
*   **Budget** :
    *   *Attributs* : `direction`, `annee`, `montant_alloue`, `montant_engage`, `montant_consomme`.

---

### 4. SCÉNARIO DE SÉQUENCE : AUTHENTIFICATION

Le processus d'authentification sécurisé suit ces étapes :

1.  **Frontend (`Login.jsx`)** : L'utilisateur saisit ses identifiants. La fonction `handleSubmit` appelle `authAPI.login(credentials)`.
2.  **Service API (`api.js`)** : Envoie une requête `POST /api/auth/login` au backend.
3.  **Backend (`AuthController.php`)** : La méthode `login` valide les données, vérifie les identifiants dans la table `users`.
4.  **Backend (Sanctum)** : Si valide, un Token API est généré et stocké dans la table `personal_access_tokens`.
5.  **Frontend (`AuthContext.jsx`)** : Reçoit le token, le stocke dans le `localStorage` (`at_token`), et récupère les informations du profil via `/auth/me` pour mettre à jour l'état global de l'application.

---

### 5. SCÉNARIO DE SÉQUENCE : CRÉER ET VALIDER UNE MISSION

Ce flux représente le cœur métier de l'application :

#### **Étape 1 : Création (Par le Demandeur)**
1.  **Frontend (`NewMissionWizard.jsx`)** : L'utilisateur remplit le formulaire multi-étapes.
2.  **API** : `POST /api/missions` crée l'entrée en base (table `missions`) avec le statut `brouillon`.
3.  **Frontend** : L'utilisateur ajoute des réservations (`POST /api/missions/{id}/reservations`).
4.  **Finalisation** : L'utilisateur clique sur "Soumettre". Le frontend appelle `POST /api/missions/{id}/submit`, ce qui change le statut en `soumis` ou `en_validation` et crée des entrées dans la table `validations`.

#### **Étape 2 : Validation (Par le Validateur)**
1.  **Frontend (`Validations.jsx`)** : Le validateur voit la mission dans sa liste "À valider".
2.  **Action** : Il clique sur "Approuver". Le frontend appelle `POST /api/validations/{id}/approuver`.
3.  **Backend (`ValidationController.php`)** : Met à jour la ligne dans la table `validations` (`statut = approuve`) et, si c'est la dernière étape, met à jour la `mission` (`statut = approuve`).
4.  **Notification** : Un système de notification (table `notifications_custom`) informe le demandeur du changement de statut.

---

### 6. LISTE DES PAGES FRONTEND

L'interface est découpée en modules logiques accessibles selon le rôle :

| Page | Rôle / Utilité | Accès |
| :--- | :--- | :--- |
| **Tableau de Bord** | Vue d'ensemble des stats et missions récentes. | Tous |
| **Liste des Missions** | Suivi et filtrage de ses propres missions. | Tous |
| **Nouvelle Mission** | Assistant de création (Wizard). | Tous |
| **Validations** | Interface de traitement des demandes en attente. | Validateur, Admin |
| **Messagerie** | Système de chat interne entre collaborateurs. | Tous |
| **Profil** | Gestion des informations personnelles et mot de passe. | Tous |
| **Administration** | Gestion des utilisateurs, budgets et prestataires. | Admin |
| **Rapports** | Génération de rapports et exports de données. | Validateur, Admin |
| **Audit Logs** | Consultation de l'historique technique du système. | Admin |

---

### 7. STRUCTURE DE LA BASE DE DONNÉES

Le système repose sur 15 tables MySQL principales. Voici les colonnes clés extraites des migrations :

*   **`users`** : `id`, `nom`, `prenom`, `email`, `password`, `matricule`, `role_id`, `is_active`.
*   **`roles`** : `id`, `name`, `permissions` (JSON).
*   **`missions`** : `id`, `numero_unique`, `user_id`, `titre`, `destination_ville`, `date_depart`, `statut`, `budget_previsionnel`.
*   **`reservations`** : `id`, `mission_id`, `prestataire_id`, `type` (ENUM), `statut`, `montant_estime`.
*   **`validations`** : `id`, `mission_id`, `validateur_id`, `ordre_etape`, `statut`, `commentaire`.
*   **`prestataires`** : `id`, `nom`, `type` (ENUM), `note_performance`, `is_active`.
*   **`budgets`** : `id`, `direction`, `annee`, `montant_alloue`, `montant_consomme`.
*   **`audit_logs`** : `id`, `user_id`, `action`, `module`, `description`, `created_at`.
*   **`documents`** : `id`, `documentable_id`, `documentable_type`, `chemin`, `type_document`.
*   **`notifications_custom`** : `id`, `user_id`, `titre`, `message`, `is_read`.
