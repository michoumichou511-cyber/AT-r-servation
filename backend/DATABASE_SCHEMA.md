# 📋 SCHÉMA COMPLET DES TABLES

*Généré le: 4 Mars 2026 - Après `php artisan migrate:fresh --seed`*

---

## 1️⃣ **USERS** (Utilisateurs)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK, unsigned, auto_increment | |
| nom | VARCHAR(255) | | Nom de l'utilisateur |
| prenom | VARCHAR(255) | | Prénom de l'utilisateur |
| email | VARCHAR(255) | unique | Email unique |
| password | VARCHAR(255) | | Hash Bcrypt |
| matricule | VARCHAR(255) | unique | Identifiant employé |
| service | VARCHAR(255) | nullable | Ex: IT, RH, Finances |
| direction | VARCHAR(255) | nullable | Division de l'organisation |
| poste | VARCHAR(255) | nullable | Titre du poste |
| telephone | VARCHAR(255) | nullable | Contact téléphonique |
| avatar | VARCHAR(255) | nullable | Chemin vers photo profil |
| role_id | BIGINT unsigned | FK → roles, nullable | Rôle utilisateur |
| is_active | BOOLEAN | default true | Désactiver sans supprimer |
| last_login_at | TIMESTAMP | nullable | Dernier accès |
| preferences | JSON | nullable | Thème, langue, notifications |
| created_at | TIMESTAMP | | Date création |
| updated_at | TIMESTAMP | | Dernière modification |
| email_verified_at | TIMESTAMP | nullable | Validation email |
| remember_token | VARCHAR(100) | nullable | Session token |

**Indexes:** 
- email (unique)
- matricule (unique)
- role_id

---

## 2️⃣ **ROLES** (Rôles d'Accès)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| name | VARCHAR(255) | | admin / validateur / utilisateur / demandeur |
| description | VARCHAR(255) | nullable | Description du rôle |
| permissions | JSON | nullable | Permissions encodées en JSON |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

**Valeurs enum:** admin, validateur, utilisateur, demandeur

---

## 3️⃣ **PRESTATAIRES** (Fournisseurs de Services)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| nom | VARCHAR(255) | | Nom de la compagnie |
| type | ENUM | compagnie_aerienne, hotel, catering, agence_voyage, transport | Type de service |
| email | VARCHAR(255) | nullable | Email contact |
| telephone | VARCHAR(255) | nullable | Téléphone |
| adresse | TEXT | nullable | Adresse complète |
| ville | VARCHAR(255) | nullable | |
| pays | VARCHAR(255) | nullable | |
| site_web | VARCHAR(255) | nullable | URL web |
| logo | VARCHAR(255) | nullable | Chemin logo |
| note_performance | DECIMAL(3,2) | default 0 | 0.00 à 5.00 |
| nombre_evaluations | INT | default 0 | Compteur |
| grille_tarifaire | JSON | nullable | Prix & tarifs |
| conditions_contrat | TEXT | nullable | Conditions commerciales |
| is_active | BOOLEAN | default true | |
| created_by | BIGINT unsigned | FK → users, nullable | Utilisateur créateur |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | nullable | Soft delete |

**Indexes:** created_by, is_active

---

## 4️⃣ **ORDRES_DE_MISSION** (Missions de Voyage)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| numero_unique | VARCHAR(255) | unique | Format: OM-2026-XXXXX |
| user_id | BIGINT unsigned | FK → users | Demandeur mission |
| titre | VARCHAR(255) | | Objet simple |
| description | TEXT | nullable | Détails |
| objet_mission | VARCHAR(255) | | Motif officiel |
| destination_ville | VARCHAR(255) | | Ville cible |
| destination_pays | VARCHAR(255) | | Pays cible |
| date_depart | DATE | | |
| date_retour | DATE | | |
| duree_jours | INT | generated → DATEDIFF | Jours (computed) |
| type_mission | ENUM | formation, conference, reunion, inspection, audit, autre | |
| priorite | ENUM | normale, urgente, tres_urgente | default normale |
| budget_previsionnel | DECIMAL(12,2) | nullable | Budget anticipé |
| budget_reel | DECIMAL(12,2) | nullable | Dépense réelle |
| statut | ENUM | brouillon, soumis, en_validation, approuve, rejete, annule, termine | default brouillon |
| motif_rejet | TEXT | nullable | Si rejet |
| soumis_le | TIMESTAMP | nullable | Date soumission |
| approuve_le | TIMESTAMP | nullable | Date approbation |
| approuve_par | BIGINT unsigned | FK → users, nullable | Approbateur |
| metadata | JSON | nullable | Infos supplémentaires |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | nullable | Soft delete |

**Indexes:** user_id, statut, date_depart

---

## 5️⃣ **CIRCUITS_VALIDATION** (Workflow de Validation)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| ordre_mission_id | BIGINT unsigned | FK → ordres_de_mission | |
| validateur_id | BIGINT unsigned | FK → users | Manager validateur |
| ordre_etape | INT | default 1 | Étape du workflow |
| statut | ENUM | en_attente, approuve, rejete, ignore | default en_attente |
| commentaire | TEXT | nullable | Feedback validateur |
| date_action | TIMESTAMP | nullable | Quand décision prise |
| delai_max_heures | INT | default 48 | Délai SLA |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

**Indexes:** ordre_mission_id, validateur_id

---

## 6️⃣ **RESERVATIONS** (Réservations Génériques)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| ordre_mission_id | BIGINT unsigned | FK → ordres_de_mission | |
| user_id | BIGINT unsigned | FK → users | Réservant |
| prestataire_id | BIGINT unsigned | FK → prestataires, nullable | Fournisseur |
| type | ENUM | billet_avion, hebergement, restauration, transport, autre | |
| statut | ENUM | en_attente, confirme, annule, modifie | default en_attente |
| date_reservation | DATE | nullable | Quand réservé |
| montant_estime | DECIMAL(12,2) | nullable | Coût estimé |
| montant_reel | DECIMAL(12,2) | nullable | Coût final |
| devise | VARCHAR(3) | default DZD | Code ISO (DZD, EUR, USD, etc) |
| numero_confirmation | VARCHAR(255) | nullable | Confirmation fournisseur |
| notes | TEXT | nullable | Remarques |
| metadata | JSON | nullable | Données additionnelles |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | nullable | Soft delete |

**Indexes:** ordre_mission_id, user_id, prestataire_id, type

---

## 7️⃣ **BILLETS_AVION** (Détails Billets Aériens)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| reservation_id | BIGINT unsigned | unique FK → reservations | 1:1 relation |
| compagnie_aerienne | VARCHAR(255) | | Ex: Air Algérie, Emirates |
| numero_vol | VARCHAR(255) | | Ex: AH001 |
| aeroport_depart | VARCHAR(255) | | Code IATA |
| ville_depart | VARCHAR(255) | | |
| pays_depart | VARCHAR(255) | | |
| aeroport_arrivee | VARCHAR(255) | | Code IATA |
| ville_arrivee | VARCHAR(255) | | |
| pays_arrivee | VARCHAR(255) | | |
| date_depart | DATETIME | | Heure exacte |
| date_arrivee | DATETIME | | Heure exacte |
| duree_vol | VARCHAR(255) | nullable | Ex: 2h30 |
| escales | INT | default 0 | Nombre |
| classe | ENUM | economique, affaires, premiere | default economique |
| numero_billet | VARCHAR(255) | nullable | |
| siege | VARCHAR(255) | nullable | Ex: 12A |
| bagages_inclus | BOOLEAN | default true | |
| repas_inclus | BOOLEAN | default false | |
| prix_aller | DECIMAL(10,2) | | Aller seul |
| prix_retour | DECIMAL(10,2) | nullable | Si aller-retour |
| prix_total | DECIMAL(10,2) | | Prix final |
| statut | ENUM | reserve, confirme, embarque, annule, rembourse | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

**Constraints:** reservation_id unique, FK cascade

---

## 8️⃣ **HEBERGEMENTS** (Réservations d'Hôtels)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| reservation_id | BIGINT unsigned | unique FK → reservations | 1:1 relation |
| nom_etablissement | VARCHAR(255) | | Nom hôtel/résidence |
| type_etablissement | ENUM | hotel, residence, auberge, autre | |
| adresse | TEXT | | |
| ville | VARCHAR(255) | | |
| pays | VARCHAR(255) | | |
| etoiles | INT | nullable | 1-5 stars |
| date_checkin | DATE | | |
| heure_checkin | TIME | default 14:00 | 2 PM |
| date_checkout | DATE | | |
| heure_checkout | TIME | default 12:00 | 12 PM |
| nombre_nuits | INT | generated → DATEDIFF | Computed |
| nombre_chambres | INT | default 1 | |
| type_chambre | ENUM | simple, double, suite, appartement | default simple |
| petit_dejeuner_inclus | BOOLEAN | default false | |
| prix_nuit | DECIMAL(10,2) | | Par nuit |
| prix_total | DECIMAL(10,2) | | Montant total |
| numero_reservation | VARCHAR(255) | nullable | Confirmation hôtel |
| contact_hotel | VARCHAR(255) | nullable | Téléphone contact |
| statut | ENUM | reserve, confirme, checkin, checkout, annule | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

**Constraints:** reservation_id unique, FK cascade

---

## 9️⃣ **RESTAURATIONS** (Réservations Restaurants)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| reservation_id | BIGINT unsigned | unique FK → reservations | 1:1 relation |
| prestataire_id | BIGINT unsigned | FK → prestataires, nullable | Resto partner |
| nom_restaurant | VARCHAR(255) | | Nom établissement |
| adresse | VARCHAR(255) | | |
| ville | VARCHAR(255) | | |
| date_repas | DATE | | |
| heure_repas | TIME | | Heure commande |
| type_repas | ENUM | petit_dejeuner, dejeuner, diner, cocktail, autre | |
| nombre_personnes | INT | default 1 | Couverts |
| menu_type | ENUM | standard, vegetarien, halal, special | default halal | 🕌 Algérie |
| preferences_alimentaires | TEXT | nullable | Détails régimes |
| prix_par_personne | DECIMAL(8,2) | | |
| prix_total | DECIMAL(10,2) | | |
| numero_reservation | VARCHAR(255) | nullable | Confirmation |
| statut | ENUM | reserve, confirme, consomme, annule | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

**Constraints:** reservation_id unique, FK cascade

---

## 🔟 **DOCUMENTS** (Gestion Documentaire)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| documentable_type | VARCHAR(255) | | Classe Model (polymorphe) |
| documentable_id | BIGINT unsigned | | ID du modèle (polymorphe) |
| uploaded_by | BIGINT unsigned | FK → users | Qui a uploadé |
| nom_original | VARCHAR(255) | | Nom fichier original |
| nom_stockage | VARCHAR(255) | | Nom généré |
| chemin | VARCHAR(255) | | Chemin complet |
| type_document | ENUM | ordre_mission, formulaire_reservation, autorisation, facture, billet, bon_commande, autre | |
| mime_type | VARCHAR(255) | | Ex: application/pdf |
| taille_ko | INT | | Taille en KB |
| is_validated | BOOLEAN | default false | Approuvé |
| validated_by | BIGINT unsigned | FK → users, nullable | Qui valide |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

**Indexes:** documentable_id, documentable_type

---

## 1️⃣1️⃣ **NOTIFICATIONS_CUSTOM** (Notifications)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| user_id | BIGINT unsigned | FK → users | Destinataire |
| titre | VARCHAR(255) | | Sujet |
| message | TEXT | | Contenu |
| type | ENUM | info, succes, warning, erreur, action_requise | |
| categorie | ENUM | mission, reservation, validation, budget, systeme | default systeme |
| notifiable_type | VARCHAR(255) | nullable | Classe liée (polymorphe) |
| notifiable_id | BIGINT unsigned | nullable | ID objet lié |
| action_url | VARCHAR(255) | nullable | Lien action |
| is_read | BOOLEAN | default false | Lue |
| read_at | TIMESTAMP | nullable | Quand lue |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

**Indexes:** user_id, is_read

---

## 1️⃣2️⃣ **BUDGETS** (Gestion Budgétaire)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| direction | VARCHAR(255) | | Division |
| service | VARCHAR(255) | nullable | Sous-service |
| annee | YEAR | | Ex: 2026 |
| trimestre | INT | nullable | 1-4 (NULL = annuel) |
| type_depense | ENUM | billetterie, hebergement, restauration, transport, total | default total |
| montant_alloue | DECIMAL(14,2) | default 0 | Budget initial |
| montant_engage | DECIMAL(14,2) | default 0 | Commits |
| montant_consomme | DECIMAL(14,2) | default 0 | Dépenses réelles |
| pourcentage_consomme | DECIMAL(5,2) | generated → (consomme/alloue)*100 | Stored |
| alerte_seuil | INT | default 80 | % pour alerte |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

**Constraints:** UNIQUE(direction, service, annee, trimestre, type_depense)
**Indexes:** direction, service, annee

---

## 1️⃣3️⃣ **AUDIT_LOGS** (Journalisation)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| user_id | BIGINT unsigned | FK → users, nullable | Qui a agi |
| action | ENUM | login, create, update, delete, approve, reject, export | Action effectuée |
| module | ENUM | mission, reservation, validation, user, budget | Sur quel module |
| description | TEXT | | Détail libre |
| ip_address | VARCHAR(255) | nullable | IP source |
| user_agent | VARCHAR(255) | nullable | Browser/app |
| old_values | JSON | nullable | Avant modification |
| new_values | JSON | nullable | Après modification |
| created_at | TIMESTAMP | | Sans updated_at |

**Indexes:** user_id, action, module, created_at

---

## 1️⃣4️⃣ **SESSIONS** (Framework Laravel)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | VARCHAR(255) | PK | |
| user_id | BIGINT unsigned | nullable | User authentifié |
| ip_address | VARCHAR(45) | nullable | IP session |
| user_agent | TEXT | nullable | Browser info |
| payload | LONGTEXT | | Données encodées |
| last_activity | INT | | Timestamp dernier accès |

---

## 1️⃣5️⃣ **PERSONAL_ACCESS_TOKENS** (Sanctum)

| Colonne | Type | Attributs | Notes |
|---------|------|----------|-------|
| id | BIGINT | PK | |
| tokenable_type | VARCHAR(255) | | Model classe |
| tokenable_id | BIGINT unsigned | | User ID |
| name | VARCHAR(255) | | Nom token |
| token | VARCHAR(80) | unique | Hash sécurisé |
| abilities | JSON | nullable | Permissions |
| last_used_at | TIMESTAMP | nullable | Dernier usage |
| expires_at | TIMESTAMP | nullable | Expiration |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

**Indexes:** tokenable_type, tokenable_id, token (unique)

---

## 📊 Résumé Statistics

| Métrique | Nombre |
|----------|--------|
| **Tables Totales** | 15 |
| **Colonnes Totales** | ~200+ |
| **Foreign Keys** | 15+ |
| **Unique Constraints** | 12+ |
| **Indexes** | 25+ |
| **Computed Columns** | 3 |
| **Enum Fields** | 12+ |
| **JSON Fields** | 6+ |
| **Soft Deletes Tables** | 3 |
| **Polymorphic Relations** | 2 |

---

**Généré pour:** Plateforme Gestion Réservations Algérie Télécom  
**Date:** 4 Mars 2026  
**Status:** ✅ PRODUCTION READY
