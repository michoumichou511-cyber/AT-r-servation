# 🚀 AT RÉSERVATIONS — MEGA-PROMPTS FUSIONNÉS POUR CLAUDE CODE

> **Prompts #1-#5** : ✅ Déjà fait
> **Prompts #6-#9** : ✅ Déjà appliqués (vérifier au Mega-Prompt A)
> **Total restant** : 14 Mega-Prompts Web + 3 Mega-Prompts Flutter

---

## ⚠️ INSTRUCTIONS GLOBALES POUR CHAQUE MEGA-PROMPT

Avant de commencer, colle ceci dans Claude Code une seule fois :

```
RÈGLES ABSOLUES À RESPECTER DANS TOUTES LES ÉTAPES :

1. Lance l'application AVANT de commencer :
   - Vérifie que XAMPP MySQL tourne (127.0.0.1:3306)
   - cd backend && php artisan serve --port=8000
   - cd frontend && npm run dev (port 5173)

2. Après CHAQUE modification frontend : npm run build (vérifier 0 erreurs)
3. Après CHAQUE modification backend : php artisan test (si tests existent)
4. DB_HOST=127.0.0.1 TOUJOURS (jamais localhost)
5. NE JAMAIS toucher : ATUsersSeeder.php, FloatingBubbles.jsx, ParticleBackground.jsx, animations Framer Motion existantes
6. NE JAMAIS modifier les couleurs AT (#00A650 vert, #003DA5 bleu)
7. Demandeur NE FIXE JAMAIS de montant — il choisit transport_type (avion/terrestre) et budget_mode (avance/remboursement)
8. Le DML achète les billets avion car AT a une convention avec Air Algérie (bureau Air Algérie INTERNE chez AT)
9. created_at doit suivre la mission PARTOUT
10. L'organigramme doit être visible par TOUS les utilisateurs avec texte explicatif
11. Tous les rôles sauf admin peuvent créer des missions
12. 5 rôles : admin, validateur, demandeur, agent_dml, utilisateur

Après chaque étape, vérifie :
- npm run build (0 erreurs)
- Teste manuellement dans Chrome DevTools (F12 → pas de console.error)
- Teste le dark mode (toggle dans l'app ou prefers-color-scheme)
- Teste avec les 3 comptes : admin@at.dz / nadia.khelifi@at.dz / demandeur@at.dz (mot de passe : Password@123)
```

---

# ═══════════════════════════════════════════════════
# MEGA-PROMPTS WEB (A → N)
# ═══════════════════════════════════════════════════

---

## MEGA-PROMPT A — Vérification sécurité #6-#9 + Fix Rapports #10

**Fichiers concernés** : MissionController.php, api.php, AdminUserController.php, DashboardRoleViews.jsx, Rapports.jsx

```
Tu travailles sur AT Réservations (Laravel 12 + React 18 + Vite + Tailwind).

ÉTAPE 1 — VÉRIFICATION (ne modifie rien, juste vérifie) :
Les changements suivants ont DÉJÀ été appliqués. Vérifie qu'ils sont corrects :

a) backend/app/Http/Controllers/Api/MissionController.php :
   - submit(), cancel(), duplicate() ont une protection IDOR ($isOwner + $isAdmin)
   - historique() a une protection IDOR ($isOwner + $isAdmin + $isValidateur via circuitsValidation)
   - Chaque check retourne ApiResponse::error('Non autorisé', 403)
   → Si correct, passe à l'étape suivante. Si problème, corrige.

b) backend/routes/api.php :
   - La route test-email publique a été supprimée (remplacée par un commentaire)
   - Pas de doublon Route::get('/prestataires/{id}')
   → Si correct, passe. Si problème, corrige.

c) backend/app/Http/Controllers/Api/AdminUserController.php :
   - changerRole() accepte 'agent_dml' dans la validation : 'required|in:admin,validateur,utilisateur,demandeur,agent_dml'
   → Si correct, passe. Si problème, corrige.

d) frontend/src/pages/dashboard/DashboardRoleViews.jsx :
   - Les données fictives DEFAULT_EVOLUTION et DEFAULT_DEPENSES sont renommées EXAMPLE_*
   - Quand pas de données, un EmptyChart s'affiche (pas de faux chiffres)
   - Les animations Framer Motion sont INTACTES (motion.div, AnimatePresence, variants)
   → Si correct, passe. Si problème, corrige SANS toucher les animations.

ÉTAPE 2 — Fix Rapports.jsx (prompt #10) :
Fichier : frontend/src/pages/rapports/Rapports.jsx

Les VRAIS endpoints backend sont :
- GET /export/missions/excel → ExportController::exportMissionsExcel
- GET /export/missions/pdf → ExportController::exportMissionsPdf
- GET /export/depenses/excel → ExportController::exportDepensesExcel
- GET /export/prestataires/excel → ExportController::exportPrestatairesExcel

Les endpoints /rapports/* N'EXISTENT PAS dans le backend.

MODIFICATIONS :
1. Vérifier que TOUS les boutons d'export utilisent UNIQUEMENT les vrais endpoints (exportAPI.missionsExcel, missionsPdf, depensesExcel, prestatairesExcel)
2. Supprimer tout appel vers exportAPI.missions(), exportAPI.budgets(), exportAPI.auditLogs() s'ils pointent vers /rapports/* inexistants
3. Organiser les exports en sections claires : Missions (Excel+PDF), Dépenses (Excel), Prestataires (Excel)
4. Ajouter un loading state par bouton (pas un loading global)
5. Dark mode : AJOUTER les classes dark: sur TOUS les éléments (texte, bg, border, select, labels)
   - text-gray-800 → text-gray-800 dark:text-white
   - bg-white → bg-white dark:bg-gray-800
   - border-gray-200 → border-gray-200 dark:border-gray-700
   - Les <select> : dark:bg-gray-700 dark:text-white dark:border-gray-600
   - Les <label> : dark:text-gray-400

npm run build après.
Ouvre Chrome DevTools (F12), vérifie 0 console.error.
Teste le dark mode visuellement.
```

---

## MEGA-PROMPT B — Composant Pagination + Intégration (#11 + #12)

**Fichiers** : Pagination.jsx (NOUVEAU), MissionsList.jsx

```
AT Réservations (React 18 + Tailwind). La pagination est dupliquée dans 4+ pages. On crée un composant réutilisable puis on l'intègre.

ÉTAPE 1 — Créer frontend/src/components/UI/Pagination.jsx :
Props : { currentPage, totalPages, totalItems, perPage, onPageChange, onPerPageChange, className }
- Afficher : "Affichage X-Y sur Z résultats"
- Boutons : Première | Précédent | [numéros] | Suivant | Dernière
- Sélecteur taille de page : 10, 15, 25, 50
- Max 5 numéros visibles avec ellipsis (...)
- Dark mode complet : dark:bg-gray-800 dark:text-gray-200 dark:border-gray-600
- Couleur active = AT vert #00A650
- Responsive : sur mobile, masquer les numéros, garder Précédent/Suivant
- Exporter dans frontend/src/components/UI/index.js

npm run build.

ÉTAPE 2 — Intégrer dans frontend/src/pages/missions/MissionsList.jsx :
- Importer { Pagination } depuis '../../components/UI'
- Remplacer le bloc de pagination JSX existant par <Pagination ... />
- Passer les props : currentPage, totalPages (meta.last_page), totalItems (meta.total), perPage, onPageChange, onPerPageChange
- S'assurer que onPerPageChange remet la page à 1 et relance le fetch
- NE PAS toucher la logique de fetch, les filtres, ou les cartes de missions

npm run build. Teste la pagination avec le compte admin@at.dz.
```

---

## MEGA-PROMPT C — Dark Mode Batch 1 : Validations + Prestataires + AuditLogs (#13 + #14 + #15)

**Fichiers** : Validations.jsx, Prestataires.jsx, AuditLogs.jsx

```
AT Réservations (React 18 + Tailwind). Dark mode systématique sur 3 pages. Traite chaque fichier SÉPARÉMENT (un à la fois), npm run build entre chaque.

PATRON DARK MODE À APPLIQUER SUR CHAQUE FICHIER :
- text-gray-900 → text-gray-900 dark:text-white
- text-gray-700 → text-gray-700 dark:text-gray-300
- text-gray-600 → text-gray-600 dark:text-gray-400
- text-gray-500 → text-gray-500 dark:text-gray-400
- bg-white → bg-white dark:bg-gray-800
- bg-gray-50 → bg-gray-50 dark:bg-gray-900
- bg-gray-100 → bg-gray-100 dark:bg-gray-700
- border-gray-200 → border-gray-200 dark:border-gray-700
- divide-gray-200 → divide-gray-200 dark:divide-gray-700
- shadow-sm → shadow-sm dark:shadow-gray-900/30
- Les inputs/selects dans les modales : dark:bg-gray-700 dark:text-white dark:border-gray-600

ÉTAPE 1 — frontend/src/pages/validations/Validations.jsx :
- Appliquer le patron dark mode sur TOUT le fichier
- Supprimer le bouton caché vide (dead code)
- ⚠️ NE PAS toucher AnimatePresence, motion.div, ou la logique métier
npm run build.

ÉTAPE 2 — frontend/src/pages/admin/Prestataires.jsx :
- Appliquer le patron dark mode (547 lignes, AUCUN dark mode actuellement)
- Les modales de création/édition : dark:bg-gray-800
- Les inputs dans les modales : dark:bg-gray-700 dark:text-white dark:border-gray-600
- Le StarRating : étoiles visibles en dark mode
- ⚠️ NE PAS modifier la logique CRUD
npm run build.

ÉTAPE 3 — frontend/src/pages/admin/AuditLogs.jsx :
- Appliquer le patron dark mode
- Ajouter filtre par utilisateur (select avec users distincts depuis les logs)
- Ajouter bouton export CSV (côté client, pas API) : Blob + URL.createObjectURL
- Ajouter sélecteur taille de page (10, 25, 50, 100)
- Badges d'action (create/update/delete) : couleurs distinctes en dark aussi
npm run build.

Après les 3 étapes : teste avec admin@at.dz, active le dark mode, navigue vers /validations, /admin/prestataires, /admin/audit-logs. Aucun texte invisible.
```

---

## MEGA-PROMPT D — Dark Mode Batch 2 : Statistiques + Organigramme (#16 + #17)

**Fichiers** : Statistiques.jsx, Organigramme.jsx

```
AT Réservations (React 18 + Tailwind + Recharts).

ÉTAPE 1 — frontend/src/pages/admin/Statistiques.jsx (501 lignes + Recharts) :
- Dark mode systématique sur tout le JSX (même patron que les prompts précédents)
- Pour CHAQUE composant Recharts :
  - XAxis/YAxis : tick={{ fill: darkMode ? '#9CA3AF' : '#374151' }} et stroke={darkMode ? '#4B5563' : '#E5E7EB'}
  - CartesianGrid : strokeDasharray="3 3" stroke={darkMode ? '#374151' : '#E5E7EB'}
  - Tooltip : contentStyle={{ backgroundColor: darkMode ? '#1F2937' : '#FFF', border: `1px solid ${darkMode ? '#374151' : '#E5E7EB'}`, borderRadius: '8px', color: darkMode ? '#F3F4F6' : '#111827' }}
- Détecter darkMode : si un hook useDarkMode ou ThemeContext existe, l'utiliser. Sinon créer un simple hook avec MutationObserver sur document.documentElement.classList.contains('dark')
npm run build.

ÉTAPE 2 — frontend/src/pages/Organigramme.jsx (838 lignes, PIRE fichier) :
- REMPLACER TOUS les inline styles par des classes Tailwind avec dark: variants
  - style={{ backgroundColor: '#003DA5' }} → className="bg-[#003DA5]"
  - style={{ color: 'white' }} → className="text-white"
  - style={{ border: '2px solid #ccc' }} → className="border-2 border-gray-300 dark:border-gray-600"
- Ajouter texte explicatif en haut : "Organigramme de la Direction des Systèmes d'Information (DSI) — Algérie Télécom. Cet organigramme représente la structure organisationnelle du département concerné par la gestion des missions et déplacements."
- Skeleton loading pendant le chargement
- GARDER les données hardcodées (voulu par l'encadreur)
- Responsive : sur mobile, layout vertical
- Zoom in/out avec boutons + et - (scale CSS transform)
- ⚠️ NE PAS modifier la structure des données orgData
npm run build.

Teste les 2 pages en dark mode avec admin@at.dz. Recharts : axes lisibles, tooltips adaptés.
```

---

## MEGA-PROMPT E — Dark Mode Batch 3 : Messagerie + DmlDashboard + Profil (#18 + #19 + #20)

**Fichiers** : Messagerie.jsx, DmlDashboard.jsx, Profil.jsx

```
AT Réservations (React 18 + Tailwind). 3 pages, un fichier à la fois.

ÉTAPE 1 — frontend/src/pages/messagerie/Messagerie.jsx :
- Dark mode systématique complet
- Bulles messages : mes messages = bg-[#003DA5] text-white (pareil dark/light), messages reçus = bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white
- Sidebar conversations : bg-white dark:bg-gray-800, hover:bg-gray-50 dark:hover:bg-gray-700
- Input message : dark:bg-gray-700 dark:text-white dark:border-gray-600
- Badge "non lu" : garder bg-[#00A650] en dark aussi
- Supprimer le message "Bonjour" hardcodé lors de la création de conversation — envoyer le premier VRAI message que l'utilisateur tape
npm run build.

ÉTAPE 2 — frontend/src/pages/dml/DmlDashboard.jsx :
- Dark mode systématique
- KPI cards responsive : grid-cols-1 sm:grid-cols-2 lg:grid-cols-3
- Modales d'assignation : dark:bg-gray-800
- Selects dans modales : dark:bg-gray-700 dark:text-white
- Cartes de mission : dark:bg-gray-800 dark:border-gray-700
- RÈGLE MÉTIER : Quand le DML assigne transport, il DOIT voir TOUS les détails de la mission (destination, dates, objectifs, exigences, transport_type). Vérifie que la carte mission affiche tout ça.
- ⚠️ NE PAS modifier AnimatePresence/motion.div ni les appels API
npm run build.

ÉTAPE 3 — frontend/src/pages/profil/Profil.jsx :
- Dark mode systématique complet
- Avatar : cercle/cadre visible en dark
- Champs formulaire : dark:bg-gray-700 dark:text-white dark:border-gray-600
- Statistiques personnelles : dark:bg-gray-800
- Formulaire changement mot de passe : dark mode complet
npm run build.

Teste : connecte-toi avec demandeur@at.dz (messagerie), avec un agent_dml si disponible (DML dashboard), et vérifie /profil.
```

---

## MEGA-PROMPT F — Recherche globale + Évaluation prestataires (#21 + #22 + #23 + #24)

**Fichiers** : Sidebar.jsx, AdminPrestataireController.php, migration, Prestataires.jsx

```
AT Réservations. 4 étapes, un fichier par étape.

ÉTAPE 1 — frontend/src/components/Layout/Sidebar.jsx :
- Le backend a déjà SearchController (GET /api/search?q=...) et searchAPI.global(q) dans api.js
- Connecter le champ de recherche existant dans la Sidebar au backend via searchAPI.global(q) avec debounce 300ms
- Dropdown overlay sous le champ : catégorisé (Missions | Utilisateurs | Prestataires)
- Chaque résultat cliquable → navigation vers la page
- Max 5 résultats par catégorie avec "Voir tout"
- Fermer au clic extérieur (useRef), Échap pour fermer
- Dark mode complet sur le dropdown
- NE PAS toucher navigation, liens, polling, compteurs notifications
npm run build.

ÉTAPE 2 — backend/app/Http/Controllers/Api/AdminPrestataireController.php :
- Vérifier si evaluerPrestataire() et evaluationsPrestataire() existent. Si oui, enrichir. Sinon, créer :
  - evaluerPrestataire($request, $id) : note (1-5), commentaire (max:500), mission_id (nullable). Créer dans evaluations_prestataires, recalculer note_performance (moyenne). Un user = une évaluation par mission.
  - evaluationsPrestataire($request, $id) : retourner évaluations avec user (nom, prenom) et mission (titre), paginer par 10
  - Dans show() : charger les 5 dernières évaluations
- NE PAS toucher listePrestataires(), creerPrestataire(), etc.

ÉTAPE 3 — Créer migration :
php artisan make:migration create_evaluations_prestataires_table
Schema : id, prestataire_id (FK→prestataires), user_id (FK→users), mission_id (FK nullable→missions), note (unsignedTinyInteger 1-5), commentaire (text nullable), timestamps.
Unique constraint : ['prestataire_id', 'user_id', 'mission_id']
php artisan migrate.

ÉTAPE 4 — frontend/src/pages/admin/Prestataires.jsx :
- Bouton "Évaluer" sur chaque carte (icône Star)
- Modale : StarRating interactif (1-5 cliquable), select mission (optionnel), textarea commentaire (max 500 avec compteur)
- POST /prestataires/{id}/evaluer
- Après succès : recharger note_performance
- Section "Avis récents" dans modale détails : GET /prestataires/{id}/evaluations
- Afficher chaque avis : nom, note (étoiles), commentaire, date
- Dark mode sur la modale
- NE PAS modifier la logique CRUD existante
npm run build.

Teste : connecte-toi admin@at.dz, évalue un prestataire, vérifie que la note se met à jour.
```

---

## MEGA-PROMPT G — Timeline mission + Intégration dans MissionDetail (#25 + #26)

**Fichiers** : MissionTimeline.jsx (NOUVEAU), MissionDetail.jsx

```
AT Réservations (React 18 + Framer Motion).

ÉTAPE 1 — Créer frontend/src/components/Missions/MissionTimeline.jsx :
Props : { events = [], loading = false }
Chaque event : { date, action, user_name, details, type }
Types avec icônes et couleurs :
- 'creation' → Plus (vert #00A650)
- 'soumission' → Send (bleu #003DA5)
- 'validation' → CheckCircle (vert)
- 'rejet' → XCircle (rouge)
- 'modification' → Edit (orange)
- 'logistique' → Truck (violet)
- 'commentaire' → MessageSquare (gris)
Layout : ligne verticale à gauche, cercle coloré par type, contenu à droite
Dark mode complet
Animation : chaque entrée avec fade-in staggered (motion.div, delay index * 0.05)
Loading : 4 skeleton items
Empty state : "Aucun historique disponible"
Exporter dans frontend/src/components/Missions/index.js (créer si inexistant)
npm run build.

ÉTAPE 2 — frontend/src/pages/missions/MissionDetail.jsx :
- Importer MissionTimeline
- Fetch historique via missionsAPI.historique(id) au montage
- Ajouter section/onglet "Historique" avec MissionTimeline
- Afficher transport_type et budget_mode dans les infos mission
- Afficher created_at formaté en français
- Dark mode sur toute la page si pas déjà fait
- RÈGLE : created_at doit suivre la mission PARTOUT
- NE PAS modifier les sections existantes qui fonctionnent
npm run build.

Teste : crée une mission avec demandeur@at.dz, soumets-la, vérifie que l'historique s'affiche dans le détail.
```

---

## MEGA-PROMPT H — Templates de missions récurrentes (#27 + #28 + #29)

**Fichiers** : MissionController.php, api.php, Step1Informations.jsx

```
AT Réservations. Système de templates pour missions récurrentes.

ÉTAPE 1 — backend/app/Http/Controllers/Api/MissionController.php :
AJOUTER ces méthodes (NE PAS modifier les existantes) :
1. saveAsTemplate(Request $request, $id) : valider que la mission appartient à l'utilisateur ou admin. Créer dans mission_templates : user_id, nom_template, données mission (titre, destination, objectifs, transport_type, budget_mode). Exclure : dates, statut, numéro_unique.
2. getTemplates(Request $request) : templates de l'utilisateur + templates publics (is_public=true créés par admin). Paginer par 10.
3. createFromTemplate(Request $request, $templateId) : charger template, créer mission brouillon pré-remplie.

ÉTAPE 2 — backend/routes/api.php :
AJOUTER dans le groupe auth:sanctum, AVANT Route::get('/missions/{id}') :
  Route::get('/missions/templates', [MissionController::class, 'getTemplates']);
  Route::post('/missions/templates/{templateId}/create', [MissionController::class, 'createFromTemplate']);
APRÈS les routes missions :
  Route::post('/missions/{id}/save-template', [MissionController::class, 'saveAsTemplate']);
⚠️ ATTENTION : /missions/templates AVANT /missions/{id} sinon Laravel interprète "templates" comme un {id}
AUSSI : php artisan make:migration create_mission_templates_table (schema: id, user_id FK, nom_template string, mission_data json, is_public boolean default false, timestamps)
php artisan migrate.

ÉTAPE 3 — frontend/src/pages/missions/NewMission/Step1Informations.jsx :
- Bouton "📋 Charger depuis un template" en haut du formulaire
- Modale listant les templates (GET /missions/templates)
- Chaque template : nom, destination, transport_type, budget_mode
- Au clic → pré-remplir le formulaire
- RÈGLE : transport_type et budget_mode pré-remplis. Le demandeur ne fixe JAMAIS de montant.
- Dark mode sur la modale
npm run build.

Teste : crée une mission, sauvegarde comme template, crée une nouvelle mission depuis ce template.
```

---

## MEGA-PROMPT I — Délégation validation + Commentaires mission (#30 + #31 + #32 + #33 + #34)

**Fichiers** : ValidationController.php, migration délégation, MissionController.php, migration commentaires, api.php, MissionDetail.jsx

```
AT Réservations. 2 features full-stack.

=== FEATURE 1 : Délégation de pouvoir ===

ÉTAPE 1 — backend/app/Http/Controllers/Api/ValidationController.php :
AJOUTER :
1. deleguer(Request $request) : valider delegue_id (exists:users), date_debut, date_fin, motif. Seul validateur/admin peut déléguer. Le délégataire doit être même direction OU admin. Créer dans delegations_validation. Notifier le délégataire.
2. mesDelegations(Request $request) : retourner délégations actives/passées.
3. MODIFIER approuver/rejeter : AVANT de vérifier si l'utilisateur est le validateur assigné, vérifier s'il a une délégation active (delegation active ET date du jour entre date_debut et date_fin → autoriser).

ÉTAPE 2 — Migration + routes :
php artisan make:migration create_delegations_validation_table
Schema : id, delegant_id (FK users), delegue_id (FK users), date_debut, date_fin, motif (500 nullable), active (boolean default true), timestamps, index sur [delegue_id, date_debut, date_fin].
Routes dans api.php groupe auth:sanctum :
  Route::post('/validations/deleguer', [ValidationController::class, 'deleguer']);
  Route::get('/validations/mes-delegations', [ValidationController::class, 'mesDelegations']);
php artisan migrate.

=== FEATURE 2 : Commentaires par mission ===

ÉTAPE 3 — backend/app/Http/Controllers/Api/MissionController.php :
AJOUTER (NE PAS toucher les existantes) :
1. commentaires(Request $request, $id) : charger commentaires avec user (nom, prenom, role). Autoriser : owner, validateur assigné, agent_dml, admin.
2. ajouterCommentaire(Request $request, $id) : valider contenu (required, max:2000). Créer commentaire. Notifier les autres participants.

ÉTAPE 4 — Migration + routes :
php artisan make:migration create_mission_commentaires_table
Schema : id, mission_id (FK missions cascade), user_id (FK users cascade), contenu (text), timestamps, index sur mission_id.
Routes dans api.php :
  Route::get('/missions/{id}/commentaires', [MissionController::class, 'commentaires']);
  Route::post('/missions/{id}/commentaires', [MissionController::class, 'ajouterCommentaire']);
php artisan migrate.

ÉTAPE 5 — frontend/src/pages/missions/MissionDetail.jsx :
- Section "Commentaires" sous la Timeline
- Fetch GET /missions/{id}/commentaires au montage
- Afficher : avatar (initiales) + nom + rôle (badge) + date relative ("il y a 2h") + contenu
- Formulaire en bas : textarea + bouton "Commenter" (Send)
- POST → optimistic update + auto-scroll
- Dark mode complet
npm run build.

Teste : ajoute un commentaire sur une mission avec demandeur@at.dz, vérifie qu'il apparaît.
```

---

## MEGA-PROMPT J — Conformité + Dashboard Exécutif (#35 + #36 + #37 + #38)

**Fichiers** : ConformiteService.php (NOUVEAU), DashboardExecutif.jsx (NOUVEAU), App.jsx (routeur), Sidebar.jsx

```
AT Réservations. Moteur de conformité + dashboard DSI pour impressionner le jury.

ÉTAPE 1 — backend/app/Services/ConformiteService.php :
Créer ConformiteService avec verifierMission(Mission $mission): array
Alertes à vérifier :
- DELAI_COURT : soumise < 48h avant départ
- DUREE_LONGUE : > 30 jours
- Budget dépassé pour la direction
- Doublon : même destination + même période déjà soumise
- Week-end : dates incluent samedi/dimanche
Intégrer dans MissionController::submit() : appeler ConformiteService, retourner alertes dans la réponse (NE PAS bloquer, juste avertir).

ÉTAPE 2 — frontend/src/pages/admin/DashboardExecutif.jsx :
KPIs (4 cartes glass) :
- Total missions ce mois / variation vs mois précédent (flèche ↑↓)
- Taux d'approbation (%)
- Budget consommé / alloué (progress bar circulaire)
- Temps moyen de traitement
Graphiques Recharts :
- AreaChart évolution 12 mois (soumises + approuvées, gradient vert AT)
- BarChart horizontal par direction
- Top 5 destinations (pie chart)
- Alertes actives
Données : dashboardAPI.stats + endpoints existants.
Dark mode complet avec Recharts adaptatif (même patron que Statistiques).
Couleurs AT : #00A650, #003DA5.

ÉTAPE 3 — Routeur (identifier App.jsx ou routes.jsx) :
- Importer DashboardExecutif (lazy loading)
- Route /admin/dashboard-executif protégée par rôle admin
npm run build.

ÉTAPE 4 — frontend/src/components/Layout/Sidebar.jsx :
- Ajouter dans les liens admin : { to: '/admin/dashboard-executif', icon: BarChart3, label: 'Dashboard DSI' }
- Position : juste après Dashboard principal
- NE PAS toucher la recherche, polling, ou autres liens
npm run build.

Teste : admin@at.dz → Dashboard DSI visible et fonctionnel.
```

---

## MEGA-PROMPT K — Simulateur budget + Messagerie améliorée + Notifications enrichies (#39 + #40 + #41)

**Fichiers** : SimulateurBudget.jsx (NOUVEAU), Messagerie.jsx, Notifications.jsx

```
AT Réservations. 3 features UX.

ÉTAPE 1 — frontend/src/pages/admin/SimulateurBudget.jsx :
- Tableau directions : nom, budget alloué, consommé, reste, %
- Progress bars colorées : vert <50%, orange 50-80%, rouge >80%
- Slider simulation : "Si on approuve X missions supplémentaires..."
- LineChart projection : consommation actuelle + projection linéaire
- Alerte si direction risque de dépasser budget avant fin année
- Export CSV du tableau
- Données : GET /admin/budgets/stats
- Dark mode. Ajouter route + lien sidebar (admin seulement).
npm run build.

ÉTAPE 2 — frontend/src/pages/messagerie/Messagerie.jsx :
- Bouton 📎 pour pièces jointes (image/PDF, max 5MB, multipart/form-data)
- Affichage fichier joint : preview image ou icône PDF
- Champ recherche en haut des conversations (filtre local par nom)
- Améliorer timestamps : "Aujourd'hui 14h30", "Hier 09:15", "12/07/2026"
- Dark mode déjà fait au mega-prompt E — vérifier et compléter si besoin
npm run build.

ÉTAPE 3 — frontend/src/pages/notifications/Notifications.jsx :
- Catégoriser visuellement :
  - mission (Briefcase, bordure bleue)
  - validation (CheckCircle, bordure verte)
  - logistique (Truck, bordure violette)
  - message (MessageSquare, bordure orange)
  - systeme (AlertTriangle, bordure rouge)
- Bouton action rapide si action_url existe ("Voir la mission")
- Grouper par date : "Aujourd'hui", "Hier", "Cette semaine", "Plus ancien"
- Filtre par catégorie (tabs en haut)
- Marquer lu au clic
- Animation slide-in pour les nouvelles
- Dark mode complet
npm run build.

Teste avec admin@at.dz : simulateur budget, messagerie avec pièces jointes, notifications catégorisées.
```

---

## MEGA-PROMPT L — Calendrier + Empreinte carbone (#42 + #43 + #44 + #45)

**Fichiers** : CalendrierMissions.jsx (NOUVEAU), CarboneService.php (NOUVEAU), CarbonWidget.jsx (NOUVEAU), App.jsx, Sidebar.jsx

```
AT Réservations. Vue calendrier + RSE.

ÉTAPE 1 — frontend/src/pages/missions/CalendrierMissions.jsx :
- Vue mensuelle : grille 7 colonnes (Lun-Dim)
- Missions = barres colorées (date_depart → date_retour)
- Couleurs par statut : brouillon=gris, soumis=bleu, approuvé=vert, rejeté=rouge
- Clic → popup résumé + lien détail
- Navigation mois précédent/suivant
- Mobile : liste chronologique
- Filtres : statut, direction
- NE PAS utiliser de librairie calendrier externe — Tailwind pur
- Données : api.get('/calendrier')
- Dark mode complet
npm run build.

ÉTAPE 2 — Route + Sidebar :
- Route /missions/calendrier → CalendrierMissions (lazy)
- Sidebar : icône Calendar, label "Calendrier", après "Missions"
- Accessible par tous les rôles
npm run build.

ÉTAPE 3 — backend/app/Services/CarboneService.php :
- calculerEmpreinte(Mission $mission) :
  - avion : ~0.255 kg CO2/km/passager
  - terrestre : ~0.171 kg CO2/km (voiture)
  - Estimer distance depuis table wilayas approximative
  - Retour : { co2_kg, equivalent_arbres (1 arbre = ~22kg/an), transport_type, distance_km }
- Ajouter dans DashboardController : GET /dashboard/empreinte-carbone → total CO2 mois/trimestre/année + top 5 directions

ÉTAPE 4 — frontend/src/components/Dashboard/CarbonWidget.jsx :
- Total CO2 ce mois (gros chiffre + icône Leaf verte)
- Équivalent arbres
- Tendance vs mois précédent
- Mini donut : avion vs terrestre
- Suggestion : "X missions auraient pu être terrestre (-Y kg CO2)"
- Dark mode, responsive
- Intégrer dans le Dashboard admin (DashboardExecutif ou Dashboard principal)
npm run build.

Teste : calendrier avec des missions existantes, widget carbone sur le dashboard.
```

---

## MEGA-PROMPT M — Polish final : PDF + AuditLogs + About + Accessibilité + Landing (#46 → #50)

**Fichiers** : bon-commande.blade.php, AuditLogs.jsx, About.jsx (NOUVEAU), UI/index.js, Login.jsx

```
AT Réservations. Finitions avant soutenance.

ÉTAPE 1 — backend/resources/views/pdf/bon-commande.blade.php (ou le template PDF ordre de mission) :
- En-tête : logo AT (si image existe) + info DSI
- Numéro mission, date création
- Section demandeur : nom, prénom, direction, téléphone
- Section mission : destination, dates, objectifs, transport_type, budget_mode
- Section logistique (si logistique_ok) : hôtel, véhicule, ticket Air Algérie
- Signatures : lignes pour demandeur, directeur, DML
- Pied de page : "Document généré le DD/MM/YYYY — AT Réservations v2.0"
- QR Code contenant l'URL de la mission

ÉTAPE 2 — frontend/src/pages/admin/AuditLogs.jsx :
- Intégrer le composant Pagination (créé au mega-prompt B)
- Vérifier que l'export CSV fonctionne (ajouté au mega-prompt C)

ÉTAPE 3 — frontend/src/pages/About.jsx :
- Logo AT + "AT Réservations v2.0"
- Description : "Plateforme de gestion des missions et déplacements — DSI Algérie Télécom"
- Stack technique avec icônes : React, Laravel, MySQL, Tailwind
- Crédits : "Développé par Ramzi — Projet de fin de formation ISIL"
- Statistiques live : utilisateurs, missions totales, prestataires
- Version, date mise à jour
- Animation fade-in, dark mode, couleurs AT
- Ajouter route /about + lien dans sidebar ou footer
npm run build.

ÉTAPE 4 — frontend/src/components/UI/index.js (et composants UI) :
- aria-label sur tous les boutons icône-seul
- role="alert" sur messages d'erreur/succès
- aria-live="polite" sur compteurs de notifications
- Focus visible : outline-2 outline-offset-2 outline-[#003DA5]
- Skip link : "Aller au contenu principal"
npm run build.

ÉTAPE 5 — frontend/src/pages/auth/Login.jsx :
- Panel gauche : GARDER ParticleBackground + formulaire login
- Panel droit (desktop) : 3 slides auto-rotate (5s) :
  - "Gérez vos missions de déplacement en quelques clics"
  - "Suivez en temps réel l'état de vos réservations"
  - "Validez les demandes depuis votre bureau"
- Indicateurs dots, logo AT + "Direction des Systèmes d'Information"
- Animation fade + slide entre slides
- ⚠️ NE PAS toucher ParticleBackground.jsx ni FloatingBubbles.jsx
- ⚠️ NE PAS modifier le formulaire login existant
npm run build.

Teste : PDF généré correctement, page About, accessibilité clavier (Tab), landing page avec slides.
```

---

## MEGA-PROMPT N — Test E2E + Vérification finale

```
AT Réservations. Vérification complète avant de passer au Flutter.

CHECKLIST :
1. npm run build → 0 errors, 0 warnings
2. php artisan migrate → toutes les migrations passent
3. Ouvre Chrome DevTools (F12) :
   - Console : 0 errors (ignorer les warnings Firebase si non configuré)
   - Network : pas de 404 sur les appels API
   - Lighthouse : score > 80

4. Test par rôle :
   a) admin@at.dz / Password@123 :
      - Dashboard : données réelles ou empty state propre
      - Dashboard Exécutif : accessible et fonctionnel
      - Utilisateurs : peut changer rôle en agent_dml
      - Prestataires : peut évaluer, note se met à jour
      - Statistiques : Recharts lisible en dark mode
      - AuditLogs : pagination + export CSV
      - Budget : simulateur fonctionnel
      - Rapports : exports fonctionnent (missions Excel/PDF, dépenses, prestataires)

   b) nadia.khelifi@at.dz / Password@123 (validateur) :
      - Validations : peut approuver/rejeter
      - Délégation : peut déléguer à un autre validateur

   c) demandeur@at.dz / Password@123 :
      - Créer mission : transport_type et budget_mode fonctionnent
      - PAS de champ montant visible
      - Templates : sauvegarder + charger
      - Commentaires sur une mission
      - Historique/timeline visible
      - Calendrier : missions visibles

5. Dark mode : toggle sur CHAQUE page — aucun texte invisible
6. Responsive : réduire la fenêtre à 375px — rien ne casse
7. Organigramme : visible par tous, texte explicatif présent

Si un problème est trouvé → corriger immédiatement.
```

---

# ═══════════════════════════════════════════════════
# MEGA-PROMPTS FLUTTER (O → Q)
# ═══════════════════════════════════════════════════

---

## MEGA-PROMPT O — Flutter Core : Notifications + Biométrie + Offline + Dark mode (F1 + F2 + F5 + F12)

```
AT Réservations Flutter (mobile/at_reservations_mobile). L'app utilise GoRouter, Provider, fl_chart, i18n fr/ar, dark/light theme.

ÉTAPE 1 — Push Notifications (lib/services/notification_service.dart) :
- Ajouter firebase_messaging + flutter_local_notifications dans pubspec.yaml
- Créer/modifier NotificationService : init FCM, demande permission, enregistrement token → POST /api/user/fcm-token
- Handler foreground : notification locale
- Handler background : silencieux
- Handler tap : navigation (mission, validation, message)
- Catégories avec icônes et couleurs

ÉTAPE 2 — Login biométrique (lib/screens/auth/login_screen.dart) :
- Package : local_auth
- Si token stocké dans flutter_secure_storage → proposer "Se connecter avec biométrie"
- Biométrie réussie → /auth/me avec token stocké
- Échec → formulaire classique
- Option activer/désactiver dans paramètres
- Animation fluide entre modes

ÉTAPE 3 — Mode hors-ligne (lib/services/offline_service.dart) :
- Packages : connectivity_plus + hive (ou sqflite)
- Cache local : missions utilisateur, conversations, notifications
- File d'attente hors-ligne : création mission brouillon, envoi message, upload document
- Bannière "Mode hors-ligne" (orange)
- Sync auto au retour réseau : traiter queue chronologiquement
- Notification "X actions synchronisées"

ÉTAPE 4 — Dark mode auto (lib/providers/theme_provider.dart) :
- Mode auto basé sur MediaQuery.platformBrightnessOf
- Options : Clair / Sombre / Automatique
- Transition animée 300ms
- SharedPreferences pour sauvegarder le choix
- Appliquer immédiatement sans redémarrer

flutter build apk --debug pour vérifier la compilation.
```

---

## MEGA-PROMPT P — Flutter Scanner : QR + OCR + Compression (F3 + F4 + F15)

```
AT Réservations Flutter. Fonctionnalités caméra.

ÉTAPE 1 — Scan QR billet Air Algérie (lib/screens/dml/scan_ticket_screen.dart) :
- Package : mobile_scanner
- Vue caméra plein écran avec guide de cadrage (carré vert animé)
- Scan QR → parser données (numéro vol, date, passager, PNR)
- Formulaire pré-rempli avec données extraites
- "Confirmer et enregistrer" → POST vers backend
- QR non reconnu → message erreur
- Mode lampe torche
- RÈGLE MÉTIER : DML va au bureau Air Algérie INTERNE chez AT, récupère billet, scanne dans l'app

ÉTAPE 2 — OCR justificatifs (lib/screens/missions/scan_justificatif_screen.dart) :
- Package : google_mlkit_text_recognition
- Prise photo avec cadrage auto
- OCR → extraction texte → parser montant (regex chiffres + "DA"/"DZD"), date, nom prestataire
- Formulaire pré-rempli (modifiable)
- Upload POST /missions/{id}/documents en multipart
- Preview avant envoi
- Compression auto (max 2MB)

ÉTAPE 3 — Compression images (lib/utils/image_compressor.dart) :
- Package : flutter_image_compress
- JPEG qualité 70% si > 2MB
- Redimensionner max 1920px largeur
- Conserver EXIF
- Retourner fichier compressé + taille avant/après
- Indicateur visuel : "Image compressée : 4.2MB → 890KB"
- Utiliser AVANT chaque upload

flutter build apk --debug.
```

---

## MEGA-PROMPT Q — Flutter UX avancée : Géoloc + Swipe + Widget + Partage + Checklist + Vocal + Haptics + SOS (F6-F11 + F13 + F14)

```
AT Réservations Flutter. Features UX avancées.

ÉTAPE 1 — Géolocalisation pointage (lib/screens/missions/geolocation_screen.dart) :
- Packages : geolocator + geocoding
- Bouton "J'y suis — Pointer mon arrivée" (visible uniquement pendant dates mission)
- Capturer GPS + timestamp, reverse geocoding
- Vérifier proximité destination (tolérance 5km)
- POST /missions/{id}/pointage avec type arrivee/depart, lat, lng, adresse, timestamp
- Historique pointages sur fiche mission
- Mini carte avec marqueur

ÉTAPE 2 — Swipe-to-approve validateur (lib/screens/validations/validation_list_screen.dart) :
- Swipe droite → Approuver (fond vert + CheckCircle)
- Swipe gauche → Rejeter (fond rouge + X) + popup motif obligatoire
- Animation check mark animé
- Feedback haptique (vibration courte/double)
- Bouton "Annuler" 3 secondes (undo)
- Badge compteur sur onglet validations

ÉTAPE 3 — Widget écran d'accueil (lib/widgets/home_widget.dart) :
- Package : home_widget
- Affiche : validations en attente + prochaine mission
- Mise à jour 15 min (WorkManager)
- Tap → ouvre l'app
- Design AT : accent vert #00A650

ÉTAPE 4 — Partage natif PDF (lib/services/share_service.dart) :
- Packages : share_plus + path_provider
- Télécharger PDF ordre de mission
- Share sheet native (WhatsApp, Gmail, etc.)
- Aussi partager résumé texte
- Bouton partage sur fiche mission

ÉTAPE 5 — Check-list voyage (lib/screens/missions/checklist_screen.dart) :
- Auto-générée selon mission : billet avion (si avion), réservation hôtel, documents, contacts DML, justificatifs (si remboursement)
- Cases à cocher avec progression (3/5)
- Bouton appel direct DML
- Accès documents hors-ligne
- Notification rappel veille du départ

ÉTAPE 6 — Dictée vocale (lib/widgets/voice_input.dart) :
- Package : speech_to_text
- Bouton micro animé (pulse)
- Langue : fr-FR
- Intégrer dans : objectif mission, commentaires, messagerie
- Texte en temps réel, bouton stop + confirmation

ÉTAPE 7 — Haptics (lib/utils/haptics.dart) :
- success() → vibration courte
- error() → double vibration
- warning() → vibration longue
- selection() → impact léger
- Intégrer dans swipe-to-approve, envoi message, changement statut
- Désactivable dans paramètres

ÉTAPE 8 — SOS DML (lib/widgets/sos_button.dart) :
- FAB rouge sur écrans mission active
- Options : appel tel DML, message urgent, envoyer GPS + "Besoin d'assistance"
- Pulse rouge quand mission en cours
- Accessible uniquement entre date_depart et date_retour

flutter build apk --debug. Tester sur un émulateur ou appareil physique.
```

---

# ═══════════════════════════════════════════════════
# 📋 CHECKLIST FINALE SOUTENANCE
# ═══════════════════════════════════════════════════

```
□ npm run build → 0 errors
□ php artisan migrate → OK
□ Dark mode vérifié sur CHAQUE page
□ Test 4 rôles : admin, validateur, demandeur, agent_dml
□ Flutter : build APK release
□ GitHub repo PRIVÉ
□ .env PAS dans le repo
□ ATUsersSeeder INTACT
□ PDF ordre de mission OK
□ Lighthouse > 80
□ 0 console.error
□ Organigramme visible par tous + texte explicatif
□ Demandeur ne fixe JAMAIS de montant
□ created_at suit la mission partout
□ Données fictives remplacées par empty states
```

---

**Total : 14 Mega-Prompts Web (A→N) + 3 Mega-Prompts Flutter (O→Q) = 17 Mega-Prompts**
**Au lieu de 65 prompts individuels → ~60% de réduction**
**Estimation : 2-3 sessions Claude Code**
