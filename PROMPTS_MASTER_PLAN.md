# 🎯 AT RÉSERVATIONS — PLAN MAÎTRE DES PROMPTS CLAUDE CODE

> **Soutenance** : Septembre 2026  
> **Prompts complétés** : #1 → #5  
> **Restant** : #6 → #50 (Web) + F1 → F15 (Flutter)  
> **Règle absolue** : 1 prompt = 1 fichier modifié

---

## ⚠️ AVANT DE COMMENCER

```bash
# 1. Lancer XAMPP (MySQL)
# 2. Migrer la table ticket_fields créée au prompt #5
cd backend && php artisan migrate
# 3. Lancer les serveurs
php artisan serve --port=8000
cd frontend && npm run dev
```

---

## 📋 LÉGENDE

- 🔴 = Sécurité critique
- 🟡 = Bug fonctionnel
- 🟢 = Amélioration UX
- 🔵 = Nouvelle feature
- 🟣 = Flutter mobile

---

# ═══════════════════════════════════════════════════
# PHASE 1 — SÉCURITÉ & BUGS CRITIQUES (#6 → #12)
# ═══════════════════════════════════════════════════

## PROMPT #6 🔴 — Sécurité IDOR dans MissionController.php

**Fichier** : `backend/app/Http/Controllers/Api/MissionController.php`

```
/caveman

CONTEXTE : Tu travailles sur AT Réservations (Laravel 12 + Sanctum). Le MissionController a des failles IDOR critiques : les méthodes submit(), cancel(), duplicate() et historique() ne vérifient PAS que l'utilisateur connecté a le droit d'agir sur la mission. N'importe quel utilisateur authentifié peut soumettre, annuler ou dupliquer la mission d'un autre.

FICHIER À MODIFIER (UN SEUL) : backend/app/Http/Controllers/Api/MissionController.php

RÈGLES MÉTIER :
- Le demandeur qui a créé la mission (user_id ou created_by) peut submit/cancel/duplicate SA mission
- Le validateur (directeur) peut voir les missions qu'il doit valider via circuitsValidation
- L'admin peut tout faire
- L'agent DML ne passe PAS par MissionController
- AUCUN utilisateur ne peut cancel/submit la mission d'un AUTRE demandeur

MODIFICATIONS EXACTES :
1. Dans submit($request, $id) — APRÈS $mission = Mission::findOrFail($id), AJOUTER :
   $user = $request->user();
   $isOwner = $mission->user_id === $user->id || $mission->created_by === $user->id;
   $isAdmin = strtolower($user->role->name ?? '') === 'admin';
   if (!$isOwner && !$isAdmin) {
       return \App\Helpers\ApiResponse::error('Non autorisé', 403);
   }

2. Dans cancel($request, $id) — MÊME vérification IDOR

3. Dans duplicate($request, $id) — MÊME vérification IDOR

4. Dans historique($request, $id) — vérification plus souple : owner OU validateur OU admin

NE PAS TOUCHER : index(), store(), show() (show a déjà $this->authorize), update() (a déjà authorize)

Après modification, lance : php artisan test --filter=Mission (si des tests existent)
Puis : npm run build dans frontend/
```

**Test Chrome MCP** : Se connecter comme demandeur@at.dz, noter l'ID d'une mission d'un AUTRE utilisateur, tenter POST /api/missions/{id}/submit → doit retourner 403.

---

## PROMPT #7 🔴 — Supprimer route test-email publique + fix changerRole

**Fichier** : `backend/routes/api.php`

```
/caveman

CONTEXTE : AT Réservations (Laravel 12). Le fichier routes/api.php a 3 problèmes de sécurité :

1. La route GET /test-email (lignes 32-42) est PUBLIQUE — n'importe qui peut envoyer des emails via le serveur. C'est une route de développement qui ne doit PAS exister en production.

2. La route GET /prestataires/{id} est enregistrée DEUX FOIS : une sous les routes publiques (ligne 153) et une sous admin (ligne 184). La version publique est correcte, supprimer le doublon admin.

3. La route /admin/utilisateurs/{id}/role appelle changerRole() mais dans AdminUserController, la validation exclut 'agent_dml' des rôles possibles — l'admin ne peut pas assigner ce rôle.

FICHIER À MODIFIER (UN SEUL) : backend/routes/api.php

MODIFICATIONS :
1. SUPPRIMER entièrement le bloc Route::get('/test-email', ...) (lignes 32-42 environ)
2. SUPPRIMER la ligne duplicate Route::get('/prestataires/{id}', ...) dans le groupe admin (garder celle dans le groupe principal)
3. Ajouter un commentaire rappelant que changerRole doit accepter agent_dml (le fix sera dans le prochain prompt)

NE RIEN AJOUTER de nouveau. Ne pas toucher la structure des groupes middleware.
Après : php artisan route:list | grep -i presta (vérifier pas de doublon)
```

---

## PROMPT #8 🔴 — Fix changerRole pour accepter agent_dml

**Fichier** : `backend/app/Http/Controllers/Api/AdminUserController.php`

```
/caveman

CONTEXTE : AT Réservations (Laravel 12). Dans AdminUserController::changerRole(), la validation du rôle est : 'role' => 'required|in:admin,validateur,demandeur,utilisateur'. Il MANQUE 'agent_dml'. L'admin ne peut donc pas assigner le rôle agent_dml à un utilisateur.

FICHIER À MODIFIER (UN SEUL) : backend/app/Http/Controllers/Api/AdminUserController.php

MODIFICATION :
- Dans changerRole(), changer la validation pour inclure 'agent_dml' :
  'role' => 'required|in:admin,validateur,demandeur,utilisateur,agent_dml'

- Vérifier aussi que la méthode charge la relation role correctement et que le retour inclut le nouveau rôle.

C'EST TOUT. Un seul changement dans un seul fichier. Ne rien casser d'autre.

Après : npm run build
```

---

## PROMPT #9 🟡 — Supprimer les données fictives du Dashboard

**Fichier** : `frontend/src/pages/dashboard/DashboardRoleViews.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18 + Recharts). Le fichier DashboardRoleViews.jsx contient des données FICTIVES hardcodées (DEFAULT_EVOLUTION et DEFAULT_DEPENSES) qui s'affichent quand le backend ne renvoie rien. C'est DANGEREUX pour une soutenance live : le jury voit des chiffres faux sans savoir que ce ne sont pas des vraies données.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/dashboard/DashboardRoleViews.jsx

⚠️ DÉFENSE ABSOLUE : NE PAS TOUCHER les animations Framer Motion existantes. Ne PAS modifier les transitions motion.div, AnimatePresence, ou les variants. Modifier UNIQUEMENT la logique de données.

MODIFICATIONS :
1. GARDER les constantes DEFAULT_EVOLUTION et DEFAULT_DEPENSES mais les renommer EXAMPLE_EVOLUTION et EXAMPLE_DEPENSES
2. PARTOUT où elles sont utilisées comme fallback (ex: graphMois ?? DEFAULT_EVOLUTION), REMPLACER par un empty state honnête :
   - Si evolutionIsEmpty(graphMois) → afficher un message "Aucune donnée pour cette période" avec une icône BarChart grayed out, PAS les fausses données
   - Si depensesIsEmpty(graphDir) → afficher "Aucune dépense enregistrée" avec une icône Wallet grayed out
3. Le message empty state doit être visuellement propre : icône 48px grisée, texte text-gray-400 dark:text-gray-500, centré dans le même espace que le graphique

RÉSULTAT ATTENDU : Quand il n'y a pas de données, on voit un placeholder honnête, pas des faux chiffres.

Ne PAS supprimer les fonctions evolutionIsEmpty() et depensesIsEmpty() — elles sont déjà correctes.
Ne PAS modifier les KPICard, BudgetCard, ValidationsCard, MissionsRecentes.
Ne PAS modifier ParticleBackground, WelcomeHeader, GlassCard.

Après : npm run build
```

**Test Chrome MCP** : Se connecter admin@at.dz, vérifier que le dashboard montre "Aucune donnée" au lieu de faux graphiques si la base est vide.

---

## PROMPT #10 🟡 — Fix exports dupliqués dans Rapports.jsx

**Fichier** : `frontend/src/pages/rapports/Rapports.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18). La page Rapports.jsx a des problèmes :
1. Des boutons d'export appellent des endpoints qui N'EXISTENT PAS (/rapports/missions, /rapports/budgets) — voir api.js exportAPI
2. D'autres boutons appellent les bons endpoints (/export/missions/excel, etc.) — ceux-là sont corrects
3. Il y a donc des paires de boutons qui font la même chose ou qui échouent silencieusement

Les VRAIS endpoints backend (dans routes/api.php) sont :
- GET /export/missions/excel → ExportController::exportMissionsExcel
- GET /export/missions/pdf → ExportController::exportMissionsPdf
- GET /export/depenses/excel → ExportController::exportDepensesExcel
- GET /export/prestataires/excel → ExportController::exportPrestatairesExcel

Les endpoints /rapports/* N'EXISTENT PAS dans le backend.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/rapports/Rapports.jsx

MODIFICATIONS :
1. Reconfigurer les boutons d'export pour utiliser UNIQUEMENT les vrais endpoints via exportAPI (missionsExcel, missionsPdf, depensesExcel, prestatairesExcel)
2. Supprimer les appels vers exportAPI.missions(), exportAPI.budgets(), exportAPI.auditLogs() qui pointent vers /rapports/* inexistants
3. Organiser les exports en 4 sections claires :
   - Missions (Excel + PDF)
   - Dépenses (Excel)
   - Prestataires (Excel)
4. Ajouter des filtres de période (date_debut, date_fin) passés en params
5. Ajouter un loading state par bouton (pas un loading global)
6. Dark mode : AJOUTER les classes dark: sur TOUS les éléments texte et background

Après : npm run build
```

---

## PROMPT #11 🟡 — Composant Pagination partagé

**Fichier** : `frontend/src/components/UI/Pagination.jsx` (NOUVEAU FICHIER)

```
/caveman

CONTEXTE : AT Réservations (React 18 + Tailwind). La pagination est dupliquée dans 4+ pages (MissionsList, Validations, AuditLogs, Prestataires). Chaque copie a ses propres bugs et inconsistances. Il faut un composant réutilisable.

FICHIER À CRÉER (UN SEUL) : frontend/src/components/UI/Pagination.jsx

Le composant doit :
1. Props : { currentPage, totalPages, totalItems, perPage, onPageChange, onPerPageChange, className }
2. Afficher : "Affichage X-Y sur Z résultats"
3. Boutons : Première | Précédent | [numéros] | Suivant | Dernière
4. Sélecteur de taille de page : 10, 15, 25, 50
5. Max 5 numéros de page visibles avec ellipsis (...)
6. Dark mode complet : dark:bg-gray-800 dark:text-gray-200 dark:border-gray-600
7. Couleur active = AT vert #00A650
8. Responsive : sur mobile, masquer les numéros, garder Précédent/Suivant
9. Exporter aussi depuis le barrel : ajouter Pagination dans frontend/src/components/UI/index.js

NE PAS modifier d'autres fichiers. L'intégration dans les pages sera faite dans les prompts suivants.

Après : npm run build
```

---

## PROMPT #12 🟡 — Intégrer Pagination dans MissionsList + AuditLogs

**Fichier** : `frontend/src/pages/missions/MissionsList.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18). Le composant Pagination partagé a été créé au prompt précédent dans frontend/src/components/UI/Pagination.jsx. Il faut maintenant l'intégrer dans MissionsList.jsx pour remplacer la pagination dupliquée.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/missions/MissionsList.jsx

MODIFICATIONS :
1. Importer { Pagination } depuis '../../components/UI'
2. Remplacer tout le bloc de pagination JSX existant par <Pagination ... />
3. Passer les props : currentPage, totalPages (depuis meta.last_page), totalItems (depuis meta.total), perPage, onPageChange, onPerPageChange
4. S'assurer que onPerPageChange remet la page à 1 et relance le fetch

NE PAS toucher la logique de fetch, les filtres, ou les cartes de missions.

Après : npm run build
```

---

# ═══════════════════════════════════════════════════
# PHASE 2 — DARK MODE SYSTÉMIQUE (#13 → #20)
# ═══════════════════════════════════════════════════

## PROMPT #13 🟢 — Dark mode Validations.jsx

**Fichier** : `frontend/src/pages/validations/Validations.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18 + Tailwind). La page Validations.jsx a un dark mode LARGEMENT MANQUANT. Les textes utilisent text-gray-900, text-gray-700, bg-white SANS classes dark:. Résultat : texte noir invisible sur fond sombre. Il y a aussi du dead code (bouton caché vide).

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/validations/Validations.jsx

MODIFICATIONS SYSTÉMATIQUES :
1. CHAQUE text-gray-900 → text-gray-900 dark:text-white
2. CHAQUE text-gray-700 → text-gray-700 dark:text-gray-300
3. CHAQUE text-gray-600 → text-gray-600 dark:text-gray-400
4. CHAQUE text-gray-500 → text-gray-500 dark:text-gray-400
5. CHAQUE bg-white → bg-white dark:bg-gray-800
6. CHAQUE bg-gray-50 → bg-gray-50 dark:bg-gray-900
7. CHAQUE bg-gray-100 → bg-gray-100 dark:bg-gray-700
8. CHAQUE border-gray-200 → border-gray-200 dark:border-gray-700
9. CHAQUE divide-gray-200 → divide-gray-200 dark:divide-gray-700
10. CHAQUE shadow-sm → shadow-sm dark:shadow-gray-900/30
11. Supprimer le bouton caché vide (dead code, visible en inspectant ~ligne 278-281)

⚠️ NE PAS toucher les animations Framer Motion (AnimatePresence, motion.div).
⚠️ NE PAS modifier la logique métier (fetch, approuver, rejeter, modifier).

Après : npm run build
```

**Test Chrome MCP** : Activer le mode sombre, naviguer vers /validations, vérifier qu'AUCUN texte n'est invisible.

---

## PROMPT #14 🟢 — Dark mode Prestataires.jsx

**Fichier** : `frontend/src/pages/admin/Prestataires.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18 + Tailwind). La page Prestataires.jsx (547 lignes) n'a AUCUN dark mode. Tous les bg-white, text-gray-*, border-gray-* sont sans classes dark:. C'est l'un des pires fichiers pour le dark mode.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/admin/Prestataires.jsx

APPLIQUER LE MÊME PATRON que le prompt #13 :
- Ajouter dark: variant à CHAQUE classe Tailwind de couleur
- bg-white → bg-white dark:bg-gray-800
- text-gray-900 → text-gray-900 dark:text-white
- etc. (même liste que prompt #13)

EN PLUS :
- Les modales de création/édition : bg-white → bg-white dark:bg-gray-800
- Les inputs dans les modales : ajouter dark:bg-gray-700 dark:text-white dark:border-gray-600
- Le StarRating : s'assurer que les étoiles sont visibles en dark mode
- Les badges de type (hôtel, restaurant, etc.) : garder les couleurs de badge, ajuster le ring/border

⚠️ NE PAS modifier la logique CRUD, les appels API, ou les animations.

Après : npm run build
```

---

## PROMPT #15 🟢 — Dark mode AuditLogs.jsx

**Fichier** : `frontend/src/pages/admin/AuditLogs.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18 + Tailwind). AuditLogs.jsx (339 lignes) a un dark mode PARTIEL — les textes du tableau sont invisibles en dark mode.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/admin/AuditLogs.jsx

MODIFICATIONS :
1. Dark mode systématique (même patron que prompts #13-14)
2. Ajouter un filtre par utilisateur (select avec la liste des users distincts depuis les logs)
3. Ajouter un bouton export CSV des logs affichés (côté client, pas API)
4. Ajouter un sélecteur de taille de page (10, 25, 50, 100)
5. Les cellules du tableau : texte lisible en dark mode
6. Les badges d'action (create, update, delete) : couleurs distinctes en dark aussi

Après : npm run build
```

---

## PROMPT #16 🟢 — Dark mode Statistiques.jsx (admin)

**Fichier** : `frontend/src/pages/admin/Statistiques.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18 + Tailwind + Recharts). Statistiques.jsx (501 lignes) utilise Recharts pour les graphiques admin. En dark mode :
- Les axes XAxis/YAxis sont noirs → illisibles sur fond sombre
- Les tooltips Recharts ont un fond blanc → clash
- Les KPI cards n'ont pas de classes dark:

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/admin/Statistiques.jsx

MODIFICATIONS :
1. Dark mode systématique sur tout le JSX (même patron que prompts précédents)
2. Pour CHAQUE composant Recharts :
   - XAxis/YAxis : ajouter tick={{ fill: darkMode ? '#9CA3AF' : '#374151' }} et stroke={darkMode ? '#4B5563' : '#E5E7EB'}
   - CartesianGrid : strokeDasharray="3 3" stroke={darkMode ? '#374151' : '#E5E7EB'}
   - Tooltip : contentStyle={{ backgroundColor: darkMode ? '#1F2937' : '#FFF', border: `1px solid ${darkMode ? '#374151' : '#E5E7EB'}`, borderRadius: '8px', color: darkMode ? '#F3F4F6' : '#111827' }}
3. Détecter le darkMode via : const darkMode = document.documentElement.classList.contains('dark') — ou mieux, utiliser un state synchronisé avec un MutationObserver sur document.documentElement

⚠️ Si un hook useDarkMode ou un contexte ThemeContext existe déjà, l'utiliser. Sinon, créer un simple hook local.

Après : npm run build
```

---

## PROMPT #17 🟢 — Dark mode Organigramme.jsx (refonte complète)

**Fichier** : `frontend/src/pages/Organigramme.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18 + Tailwind). Organigramme.jsx (838 lignes) est le PIRE fichier pour le dark mode : 100% inline styles, ZÉRO Tailwind. C'est aussi un fichier avec des données hardcodées fictives.

RÈGLE MÉTIER ENCADREUR : L'organigramme doit être visible par TOUS les utilisateurs avec un texte explicatif.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/Organigramme.jsx

MODIFICATIONS :
1. REMPLACER TOUS les inline styles par des classes Tailwind équivalentes avec dark: variants :
   - style={{ backgroundColor: '#003DA5' }} → className="bg-[#003DA5]"
   - style={{ color: 'white' }} → className="text-white"
   - style={{ border: '2px solid #ccc' }} → className="border-2 border-gray-300 dark:border-gray-600"
   - etc.

2. Ajouter un texte explicatif en haut de la page :
   "Organigramme de la Direction des Systèmes d'Information (DSI) — Algérie Télécom. Cet organigramme représente la structure organisationnelle du département concerné par la gestion des missions et déplacements."

3. Ajouter un skeleton loading pendant le chargement

4. Garder les données hardcodées (c'est voulu par l'encadreur — noms fictifs, structure réelle)

5. Rendre les cartes d'organigramme responsive : sur mobile, layout vertical au lieu d'horizontal

6. Ajouter zoom in/out avec des boutons + et - (simple scale CSS transform)

⚠️ NE PAS modifier la structure des données orgData.

Après : npm run build
```

---

## PROMPT #18 🟢 — Dark mode Messagerie.jsx

**Fichier** : `frontend/src/pages/messagerie/Messagerie.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18 + Tailwind). Messagerie.jsx (546 lignes) a un dark mode incomplet.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/messagerie/Messagerie.jsx

MODIFICATIONS :
1. Dark mode systématique (même patron que prompts #13-17)
2. Les bulles de messages : mes messages = bg-[#003DA5] text-white (pareil dark/light), les messages reçus = bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white
3. La sidebar conversations : bg-white dark:bg-gray-800, hover:bg-gray-50 dark:hover:bg-gray-700
4. L'input de message : dark:bg-gray-700 dark:text-white dark:border-gray-600
5. Le badge "non lu" : garder bg-[#00A650] en dark aussi
6. Supprimer le message "Bonjour" hardcodé lors de la création de conversation — envoyer le premier VRAI message que l'utilisateur tape

Après : npm run build
```

---

## PROMPT #19 🟢 — Dark mode DmlDashboard.jsx

**Fichier** : `frontend/src/pages/dml/DmlDashboard.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18 + Tailwind). DmlDashboard.jsx (469 lignes) a un dark mode partiel. Les KPI cards ne sont PAS responsive (grid-cols-3 sans breakpoints).

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/dml/DmlDashboard.jsx

MODIFICATIONS :
1. Dark mode systématique sur tout le fichier
2. KPI cards responsive : grid-cols-1 sm:grid-cols-2 lg:grid-cols-3
3. Les modales d'assignation (hôtel, véhicule) : dark:bg-gray-800
4. Les selects dans les modales : dark:bg-gray-700 dark:text-white
5. Les cartes de mission dans chaque onglet : dark:bg-gray-800 dark:border-gray-700
6. Le formulaire de scan de ticket : s'assurer que les champs ticket_number, transport_company, montant_transport ont les dark: classes

RÈGLE MÉTIER : Quand le DML assigne transport, il DOIT voir TOUS les détails de la mission (destination, dates, objectifs, exigences du demandeur, type de transport demandé). Vérifier que la carte mission affiche bien tout ça.

⚠️ NE PAS modifier les animations AnimatePresence/motion.div
⚠️ NE PAS modifier la logique des appels API

Après : npm run build
```

---

## PROMPT #20 🟢 — Dark mode Profil.jsx + Budgets.jsx + Utilisateurs.jsx

**Fichier** : `frontend/src/pages/profil/Profil.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18 + Tailwind). Profil.jsx a un dark mode incomplet.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/profil/Profil.jsx

MODIFICATIONS :
1. Dark mode systématique complet (même patron que tous les prompts dark mode précédents)
2. La section avatar : s'assurer que le cercle/cadre est visible en dark
3. Les champs de formulaire profil : dark:bg-gray-700 dark:text-white dark:border-gray-600
4. Les statistiques personnelles : dark:bg-gray-800
5. Le formulaire de changement de mot de passe : dark mode complet
6. Toute la page doit être cohérente visuellement en dark mode

Après : npm run build
```

---

# ═══════════════════════════════════════════════════
# PHASE 3 — FONCTIONNEL & UX (#21 → #30)
# ═══════════════════════════════════════════════════

## PROMPT #21 🟢 — Recherche globale frontend connectée au backend

**Fichier** : `frontend/src/components/Layout/Sidebar.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18). Le backend a déjà un SearchController (GET /api/search?q=...) qui fonctionne. Le frontend a searchAPI.global(q) dans api.js. Mais le champ de recherche dans la Sidebar n'est PAS connecté au backend — il fait un filtrage local basique ou rien.

FICHIER À MODIFIER (UN SEUL) : frontend/src/components/Layout/Sidebar.jsx

MODIFICATIONS :
1. Identifier le champ de recherche existant dans la Sidebar
2. Le connecter à searchAPI.global(q) avec un debounce de 300ms
3. Afficher les résultats dans un dropdown overlay positionné sous le champ :
   - Catégorisés : Missions | Utilisateurs | Prestataires
   - Chaque résultat est cliquable et navigue vers la page correspondante
   - Max 5 résultats par catégorie avec un lien "Voir tout"
4. Fermer le dropdown au clic extérieur (useRef + event listener)
5. Dark mode complet sur le dropdown
6. Touche Échap pour fermer

NE PAS toucher la navigation, les liens, le polling, ou les compteurs de notifications.

Après : npm run build
```

---

## PROMPT #22 🟢 — Système d'évaluation réel des prestataires

**Fichier** : `backend/app/Http/Controllers/Api/AdminPrestataireController.php`

```
/caveman

CONTEXTE : AT Réservations (Laravel 12). Le rating des prestataires (note_performance) est actuellement SAISI MANUELLEMENT par l'admin — c'est un simple champ numérique, pas un vrai système d'évaluation. Les routes /prestataires/{id}/evaluer et /prestataires/{id}/evaluations existent dans api.php.

FICHIER À MODIFIER (UN SEUL) : backend/app/Http/Controllers/Api/AdminPrestataireController.php

VÉRIFIER D'ABORD si evaluerPrestataire() et evaluationsPrestataire() existent déjà. Si oui, les enrichir. Sinon, les créer.

MODIFICATIONS :
1. evaluerPrestataire($request, $id) :
   - Validation : note (1-5, required), commentaire (string, nullable, max:500), mission_id (nullable, exists:missions,id)
   - Créer un enregistrement dans une table evaluations_prestataires (si elle n'existe pas, la migration sera dans le prochain prompt)
   - Recalculer la note_performance du prestataire : moyenne de toutes les évaluations
   - Un utilisateur ne peut évaluer un prestataire qu'UNE FOIS par mission

2. evaluationsPrestataire($request, $id) :
   - Retourner toutes les évaluations avec le user (nom, prenom) et la mission (titre)
   - Paginer par 10

3. Dans show() : ajouter le chargement des évaluations récentes (5 dernières)

NE PAS toucher listePrestataires(), prestaFavoris(), creerPrestataire(), etc.

Après : php artisan test
```

---

## PROMPT #23 🟢 — Migration table evaluations_prestataires

**Fichier** : `backend/database/migrations/xxxx_create_evaluations_prestataires_table.php` (NOUVEAU)

```
/caveman

CONTEXTE : AT Réservations (Laravel 12). Le prompt #22 a enrichi les méthodes d'évaluation dans AdminPrestataireController. Il faut maintenant la table.

FICHIER À CRÉER (UN SEUL) : Une migration Laravel

COMMANDE : php artisan make:migration create_evaluations_prestataires_table

SCHEMA :
Schema::create('evaluations_prestataires', function (Blueprint $table) {
    $table->id();
    $table->foreignId('prestataire_id')->constrained('prestataires')->cascadeOnDelete();
    $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
    $table->foreignId('mission_id')->nullable()->constrained('missions')->nullOnDelete();
    $table->unsignedTinyInteger('note'); // 1-5
    $table->text('commentaire')->nullable();
    $table->timestamps();
    
    // Un user ne peut évaluer qu'une fois par prestataire par mission
    $table->unique(['prestataire_id', 'user_id', 'mission_id'], 'eval_presta_user_mission_unique');
});

Après : php artisan migrate
```

---

## PROMPT #24 🟢 — Frontend évaluation prestataires (StarRating interactif)

**Fichier** : `frontend/src/pages/admin/Prestataires.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18). Le backend pour les évaluations est prêt (prompts #22-23). Il faut maintenant connecter le frontend.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/admin/Prestataires.jsx

MODIFICATIONS :
1. Ajouter un bouton "Évaluer" sur chaque carte de prestataire (icône Star)
2. Au clic → modale avec :
   - StarRating interactif (cliquable, pas juste affichage) de 1 à 5
   - Select de mission (optionnel, liste les missions de l'utilisateur)
   - Textarea pour commentaire (max 500 caractères avec compteur)
   - Bouton "Envoyer l'évaluation"
3. Appel POST /prestataires/{id}/evaluer via adminAPI.prestatairesCrud.evaluer(id, data)
4. Après succès : recharger la note_performance affichée (maintenant c'est une moyenne réelle)
5. Section "Avis récents" dans la modale détails du prestataire : GET /prestataires/{id}/evaluations
6. Afficher chaque avis avec : nom utilisateur, note (étoiles), commentaire, date

NE PAS modifier la logique CRUD existante (créer, modifier, supprimer prestataire).
Dark mode : la modale d'évaluation doit être en dark mode complet.

Après : npm run build
```

---

## PROMPT #25 🔵 — Composant Timeline/Historique mission enrichi

**Fichier** : `frontend/src/components/Missions/MissionTimeline.jsx` (NOUVEAU)

```
/caveman

CONTEXTE : AT Réservations (React 18). L'historique d'une mission existe dans le backend (GET /missions/{id}/historique) mais le frontend ne l'affiche pas de manière visuelle. Il faut un composant Timeline vertical élégant.

FICHIER À CRÉER (UN SEUL) : frontend/src/components/Missions/MissionTimeline.jsx

COMPOSANT :
- Props : { events = [], loading = false }
- Chaque event : { date, action, user_name, details, type }
- Types avec icônes et couleurs :
  - 'creation' → Plus (vert #00A650)
  - 'soumission' → Send (bleu #003DA5)
  - 'validation' → CheckCircle (vert)
  - 'rejet' → XCircle (rouge)
  - 'modification' → Edit (orange)
  - 'logistique' → Truck (violet)
  - 'commentaire' → MessageSquare (gris)
- Layout : ligne verticale à gauche, cercle coloré par type, contenu à droite
- Dark mode complet
- Animation : chaque entrée apparaît avec un fade-in staggered (motion.div de Framer Motion, delay index * 0.05)
- Loading : 4 skeleton items
- Empty state : "Aucun historique disponible"

Exporter dans frontend/src/components/Missions/index.js (créer le fichier barrel si inexistant)

Après : npm run build
```

---

## PROMPT #26 🔵 — Intégrer Timeline dans MissionDetail.jsx

**Fichier** : `frontend/src/pages/missions/MissionDetail.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18). Le composant MissionTimeline a été créé au prompt #25. Il faut l'intégrer dans la page de détail d'une mission.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/missions/MissionDetail.jsx

MODIFICATIONS :
1. Importer MissionTimeline depuis '../../components/Missions/MissionTimeline'
2. Ajouter un fetch de l'historique via missionsAPI.historique(id) au montage
3. Ajouter un onglet ou une section "Historique" dans la page détail
4. Afficher le MissionTimeline avec les événements
5. Afficher aussi : transport_type et budget_mode (ajoutés au prompt #1) dans les infos de la mission
6. Afficher created_at formaté en français (ajouté au prompt #3)
7. Dark mode sur toute la page (si pas déjà fait)

RÈGLE MÉTIER : La date de création (created_at) doit suivre la mission PARTOUT.

NE PAS modifier les sections existantes qui fonctionnent déjà.

Après : npm run build
```

---

## PROMPT #27 🔵 — Templates de missions récurrentes

**Fichier** : `backend/app/Http/Controllers/Api/MissionController.php`

```
/caveman

CONTEXTE : AT Réservations (Laravel 12). Pour les formations récurrentes ou missions fréquentes, les utilisateurs doivent re-remplir tout à chaque fois. On ajoute un système de templates.

FICHIER À MODIFIER (UN SEUL) : backend/app/Http/Controllers/Api/MissionController.php

AJOUTER ces méthodes (ne pas modifier les existantes) :

1. saveAsTemplate(Request $request, $id) :
   - Valider que la mission appartient à l'utilisateur (ou admin)
   - Créer un enregistrement dans mission_templates avec : user_id, nom_template, données de la mission (titre, destination, objectifs, transport_type, budget_mode, etc.)
   - Exclure : dates, statut, numéro_unique

2. getTemplates(Request $request) :
   - Retourner les templates de l'utilisateur connecté + les templates "publics" (is_public = true, créés par admin)
   - Paginer par 10

3. createFromTemplate(Request $request, $templateId) :
   - Charger le template
   - Créer une nouvelle mission brouillon pré-remplie avec les données du template
   - L'utilisateur n'a plus qu'à ajouter les dates et soumettre

NE PAS toucher : index(), store(), show(), update(), destroy(), submit(), cancel(), etc.

ROUTES À AJOUTER (sera fait au prochain prompt quand on touchera api.php) :
- POST /missions/{id}/save-template
- GET /missions/templates
- POST /missions/templates/{templateId}/create

Après : php artisan test
```

---

## PROMPT #28 🔵 — Routes templates + migration

**Fichier** : `backend/routes/api.php`

```
/caveman

CONTEXTE : AT Réservations (Laravel 12). Les méthodes de templates ont été ajoutées au MissionController (prompt #27). Il faut les routes et la migration.

FICHIER À MODIFIER (UN SEUL) : backend/routes/api.php

AJOUTER dans le groupe auth:sanctum, APRÈS les routes MISSIONS existantes :
    // TEMPLATES MISSIONS
    Route::post('/missions/{id}/save-template', [MissionController::class, 'saveAsTemplate']);
    Route::get('/missions/templates', [MissionController::class, 'getTemplates']);
    Route::post('/missions/templates/{templateId}/create', [MissionController::class, 'createFromTemplate']);

⚠️ ATTENTION : placer Route::get('/missions/templates') AVANT Route::get('/missions/{id}') sinon Laravel interprétera "templates" comme un {id}.

NE RIEN MODIFIER d'autre dans ce fichier.

AUSSI : lancer la commande artisan pour créer la migration :
php artisan make:migration create_mission_templates_table

Après : php artisan migrate
```

---

## PROMPT #29 🔵 — Frontend templates missions

**Fichier** : `frontend/src/pages/missions/NewMission/Step1Informations.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18). Les templates sont prêts côté backend. Il faut ajouter un bouton "Charger un template" dans Step1Informations.jsx.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/missions/NewMission/Step1Informations.jsx

MODIFICATIONS :
1. Ajouter en haut du formulaire (avant les champs) un bouton "📋 Charger depuis un template"
2. Au clic → modale listant les templates disponibles (GET /missions/templates via api)
3. Chaque template montre : nom, destination, type de transport, budget mode
4. Au clic sur un template → pré-remplir le formulaire avec les données du template
5. Le user peut ensuite modifier les champs et ajouter les dates
6. Ajouter aussi un bouton "Sauvegarder comme template" dans Step4Recap (mais ça c'est un autre fichier → prochain prompt)

RÈGLE MÉTIER :
- transport_type et budget_mode sont pré-remplis depuis le template
- Le demandeur ne fixe JAMAIS de montant
- Tous les rôles sauf admin peuvent créer des missions

Dark mode sur la modale de sélection de template.

Après : npm run build
```

---

## PROMPT #30 🔵 — Délégation de pouvoir temporaire (backend)

**Fichier** : `backend/app/Http/Controllers/Api/ValidationController.php`

```
/caveman

CONTEXTE : AT Réservations (Laravel 12). Quand un directeur/validateur est en congé ou en mission, personne ne peut approuver les missions en attente. Il faut un système de délégation temporaire.

FICHIER À MODIFIER (UN SEUL) : backend/app/Http/Controllers/Api/ValidationController.php

AJOUTER ces méthodes :

1. deleguer(Request $request) :
   - Valider : delegue_id (exists:users,id), date_debut, date_fin, motif
   - Seul un validateur/admin peut déléguer
   - Le délégataire doit être dans la même direction OU admin
   - Créer un enregistrement dans delegations_validation
   - Notifier le délégataire

2. mesDelegations(Request $request) :
   - Retourner les délégations actives/passées de l'utilisateur (comme délégant et comme délégataire)

3. MODIFIER la logique d'approuver/rejeter existante :
   - AVANT de vérifier si l'utilisateur est le validateur assigné, vérifier s'il a une délégation active pour ce validateur
   - Si delegation active ET date du jour entre date_debut et date_fin → autoriser

NE PAS modifier la structure de réponse des méthodes existantes.

Après : php artisan test
```

---

# ═══════════════════════════════════════════════════
# PHASE 4 — FEATURES AVANCÉES WEB (#31 → #42)
# ═══════════════════════════════════════════════════

## PROMPT #31 🔵 — Migration délégation + routes

**Fichier** : Créer migration `create_delegations_validation_table`

```
/caveman

CONTEXTE : AT Réservations (Laravel 12). Suite du prompt #30 — il faut la migration et les routes.

COMMANDE : php artisan make:migration create_delegations_validation_table

SCHEMA :
Schema::create('delegations_validation', function (Blueprint $table) {
    $table->id();
    $table->foreignId('delegant_id')->constrained('users')->cascadeOnDelete();
    $table->foreignId('delegue_id')->constrained('users')->cascadeOnDelete();
    $table->date('date_debut');
    $table->date('date_fin');
    $table->string('motif', 500)->nullable();
    $table->boolean('active')->default(true);
    $table->timestamps();
    $table->index(['delegue_id', 'date_debut', 'date_fin']);
});

ROUTES à ajouter dans api.php dans le groupe auth:sanctum :
    Route::post('/validations/deleguer', [ValidationController::class, 'deleguer']);
    Route::get('/validations/mes-delegations', [ValidationController::class, 'mesDelegations']);

Après : php artisan migrate
```

---

## PROMPT #32 🔵 — Commentaires par mission (backend)

**Fichier** : `backend/app/Http/Controllers/Api/MissionController.php`

```
/caveman

CONTEXTE : AT Réservations (Laravel 12). Actuellement, la seule communication sur une mission passe par la messagerie générale. Il faut un fil de commentaires DIRECTEMENT SUR la mission, visible par le demandeur, le DML et le validateur.

FICHIER À MODIFIER (UN SEUL) : backend/app/Http/Controllers/Api/MissionController.php

AJOUTER ces méthodes :

1. commentaires(Request $request, $id) :
   - GET /missions/{id}/commentaires
   - Charger tous les commentaires de la mission avec user (nom, prenom, role)
   - Autoriser : owner, validateur assigné, agent_dml, admin

2. ajouterCommentaire(Request $request, $id) :
   - POST /missions/{id}/commentaires
   - Valider : contenu (required, string, max:2000)
   - Créer le commentaire avec user_id et mission_id
   - Notifier les autres participants de la mission

NE PAS toucher les méthodes existantes.

La migration pour mission_commentaires sera créée au prompt suivant.

Après : php artisan test
```

---

## PROMPT #33 🔵 — Migration commentaires + routes

**Fichier** : Migration + routes

```
/caveman

php artisan make:migration create_mission_commentaires_table

SCHEMA :
Schema::create('mission_commentaires', function (Blueprint $table) {
    $table->id();
    $table->foreignId('mission_id')->constrained('missions')->cascadeOnDelete();
    $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
    $table->text('contenu');
    $table->timestamps();
    $table->index('mission_id');
});

ROUTES dans api.php :
    Route::get('/missions/{id}/commentaires', [MissionController::class, 'commentaires']);
    Route::post('/missions/{id}/commentaires', [MissionController::class, 'ajouterCommentaire']);

Après : php artisan migrate
```

---

## PROMPT #34 🔵 — Frontend commentaires sur MissionDetail

**Fichier** : `frontend/src/pages/missions/MissionDetail.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18). Les commentaires backend sont prêts. Ajouter la section commentaires dans la page détail mission.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/missions/MissionDetail.jsx

MODIFICATIONS :
1. Ajouter une section "Commentaires" sous la Timeline
2. Fetch GET /missions/{id}/commentaires au montage
3. Afficher les commentaires en liste :
   - Avatar (initiales) + nom + rôle (badge coloré) + date relative ("il y a 2h")
   - Contenu du commentaire
4. Formulaire en bas : textarea + bouton "Commenter" (icône Send)
5. POST /missions/{id}/commentaires → ajouter le commentaire en temps réel (optimistic update)
6. Auto-scroll vers le nouveau commentaire
7. Dark mode complet

Ajouter dans api.js (mais c'est un autre fichier... alors plutôt utiliser api.get/api.post inline dans le composant)

Après : npm run build
```

---

## PROMPT #35 🔵 — Moteur de conformité (backend)

**Fichier** : `backend/app/Services/ConformiteService.php` (NOUVEAU)

```
/caveman

CONTEXTE : AT Réservations (Laravel 12). Pour que l'application soit enterprise-grade, il faut un moteur qui vérifie automatiquement les règles de conformité avant la soumission d'une mission.

FICHIER À CRÉER (UN SEUL) : backend/app/Services/ConformiteService.php

SERVICE :
namespace App\Services;

class ConformiteService {
    
    public function verifierMission(Mission $mission): array {
        $alertes = [];
        
        // 1. Délai minimum : mission soumise moins de 48h avant départ
        if ($mission->date_depart && $mission->date_depart->diffInHours(now()) < 48) {
            $alertes[] = ['type' => 'warning', 'code' => 'DELAI_COURT', 'message' => 'Mission soumise moins de 48h avant le départ'];
        }
        
        // 2. Durée excessive : mission de plus de 30 jours
        if ($mission->date_depart && $mission->date_retour) {
            $duree = $mission->date_depart->diffInDays($mission->date_retour);
            if ($duree > 30) {
                $alertes[] = ['type' => 'warning', 'code' => 'DUREE_LONGUE', 'message' => "Durée de {$duree} jours — justification requise"];
            }
        }
        
        // 3. Budget dépassé pour la direction
        // 4. Mission vers destination à risque (liste configurable)
        // 5. Doublon : mission similaire (même destination, même période) déjà soumise
        // 6. Week-end : dates incluent samedi/dimanche sans justification
        
        return $alertes;
    }
}

Intégrer dans MissionController::submit() : appeler ConformiteService avant de changer le statut, retourner les alertes dans la réponse (ne PAS bloquer, juste avertir).

Après : php artisan test
```

---

## PROMPT #36 🔵 — Dashboard exécutif DSI

**Fichier** : `frontend/src/pages/admin/DashboardExecutif.jsx` (NOUVEAU)

```
/caveman

CONTEXTE : AT Réservations (React 18 + Recharts). Pour la soutenance, un dashboard de niveau direction qui impressionne le jury.

FICHIER À CRÉER (UN SEUL) : frontend/src/pages/admin/DashboardExecutif.jsx

COMPOSANT PAGE :
1. KPIs en haut (4 cartes glass) :
   - Total missions ce mois / variation vs mois précédent (flèche ↑↓ colorée)
   - Taux d'approbation (% missions approuvées / soumises)
   - Budget consommé / alloué (progress bar circulaire)
   - Temps moyen de traitement (soumission → logistique_ok)

2. Graphique principal : évolution sur 12 mois (AreaChart Recharts)
   - Ligne missions soumises + ligne missions approuvées
   - Gradient vert AT sous la courbe approuvée

3. Répartition par direction (horizontal BarChart) :
   - Chaque direction avec son nombre de missions et budget

4. Top 5 destinations (pie chart ou treemap)

5. Alertes actives (missions en retard, budgets critiques)

Données : utiliser les endpoints dashboard existants (dashboardAPI.stats, etc.)
Dark mode complet avec Recharts adaptatif.
Couleurs AT : #00A650 (vert), #003DA5 (bleu).

NE PAS ajouter de route dans le router — ce sera fait au prompt suivant.

Après : npm run build
```

---

## PROMPT #37 🔵 — Route DashboardExecutif + lien sidebar

**Fichier** : `frontend/src/App.jsx` (ou le routeur principal)

```
/caveman

CONTEXTE : AT Réservations (React 18 + React Router). Le DashboardExecutif a été créé. Il faut l'ajouter au routeur et à la sidebar.

FICHIER À MODIFIER (UN SEUL) : identifier le fichier de routes (App.jsx ou un fichier routes.jsx)

MODIFICATIONS :
1. Importer DashboardExecutif (lazy loading)
2. Ajouter la route /admin/dashboard-executif protégée par rôle admin
3. Dans la Sidebar (prompt suivant) : ajouter le lien pour admin

Si le routeur est dans App.jsx, modifier App.jsx UNIQUEMENT.

Après : npm run build
```

---

## PROMPT #38 🔵 — Lien sidebar DashboardExecutif

**Fichier** : `frontend/src/components/Layout/Sidebar.jsx`

```
/caveman

CONTEXTE : AT Réservations. Ajouter le lien vers le Dashboard Exécutif dans la sidebar pour le rôle admin.

FICHIER À MODIFIER (UN SEUL) : frontend/src/components/Layout/Sidebar.jsx

MODIFICATION :
- Dans la liste des liens admin, ajouter :
  { to: '/admin/dashboard-executif', icon: BarChart3, label: 'Dashboard DSI' }
- Position : juste après le lien Dashboard principal
- Icône : BarChart3 de lucide-react

NE PAS toucher la recherche, le polling, ou les autres liens.

Après : npm run build
```

---

## PROMPT #39 🔵 — Simulateur budget prévisionnel

**Fichier** : `frontend/src/pages/admin/SimulateurBudget.jsx` (NOUVEAU)

```
/caveman

CONTEXTE : AT Réservations (React 18 + Recharts). Un outil pour l'admin qui simule les dépenses restantes vs budget par direction.

FICHIER À CRÉER (UN SEUL) : frontend/src/pages/admin/SimulateurBudget.jsx

COMPOSANT :
1. Tableau des directions avec : nom, budget alloué, budget consommé, reste, % consommé
2. Progress bars colorées : vert <50%, orange 50-80%, rouge >80%
3. Slider de simulation : "Si on approuve X missions supplémentaires pour cette direction..."
4. Graphique projection (LineChart) : courbe consommation actuelle + projection linéaire
5. Alerte si une direction risque de dépasser son budget avant fin d'année
6. Export CSV du tableau

Données : GET /admin/budgets/stats (adminAPI.budgetsCrud.stats())
Dark mode complet.

Après : npm run build
```

---

## PROMPT #40 🔵 — Amélioration Messagerie (pièces jointes)

**Fichier** : `frontend/src/pages/messagerie/Messagerie.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18). La messagerie actuelle ne supporte pas les pièces jointes, pas de recherche dans les conversations, et pas de suppression de message.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/messagerie/Messagerie.jsx

MODIFICATIONS :
1. Ajouter un bouton 📎 à côté de l'input pour joindre un fichier (image, PDF, max 5MB)
2. Envoi en multipart/form-data via messagesAPI.envoyer() avec le fichier
3. Affichage du fichier joint : preview image ou icône PDF avec nom du fichier
4. Ajouter un champ de recherche en haut de la liste des conversations (filtre local par nom)
5. Ajouter des indicateurs de frappe ("est en train d'écrire...")  — simulation côté client car pas de WebSocket
6. Améliorer le format des timestamps : "Aujourd'hui 14h30", "Hier 09:15", "12/07/2026"

Note : le backend MessageController doit supporter les fichiers. Si ce n'est pas le cas, un TODO sera ajouté.

Dark mode : s'assurer que tout est compatible (déjà fait au prompt #18).

Après : npm run build
```

---

## PROMPT #41 🔵 — Notifications enrichies avec actions

**Fichier** : `frontend/src/pages/notifications/Notifications.jsx`

```
/caveman

CONTEXTE : AT Réservations (React 18). Les notifications existent mais sont basiques : juste titre + message. Il faut les enrichir.

FICHIER À MODIFIER (UN SEUL) : frontend/src/pages/notifications/Notifications.jsx

MODIFICATIONS :
1. Catégoriser les notifications visuellement :
   - mission (icône Briefcase, bordure gauche bleue)
   - validation (icône CheckCircle, bordure verte)
   - logistique (icône Truck, bordure violette)
   - message (icône MessageSquare, bordure orange)
   - systeme (icône AlertTriangle, bordure rouge)
2. Ajouter un bouton d'action rapide si action_url existe :
   - "Voir la mission" / "Traiter" → navigation vers action_url
3. Grouper par date : "Aujourd'hui", "Hier", "Cette semaine", "Plus ancien"
4. Ajouter un filtre par catégorie (tabs en haut)
5. Marquer lu au clic (pas besoin d'un bouton séparé)
6. Animation : slide-in pour les nouvelles notifications
7. Dark mode complet

Après : npm run build
```

---

## PROMPT #42 🔵 — Composant CalendrierMissions

**Fichier** : `frontend/src/pages/missions/CalendrierMissions.jsx` (NOUVEAU)

```
/caveman

CONTEXTE : AT Réservations (React 18). Le backend a déjà GET /api/calendrier qui retourne les missions formatées pour un calendrier. Le frontend n'a pas de vue calendrier.

FICHIER À CRÉER (UN SEUL) : frontend/src/pages/missions/CalendrierMissions.jsx

COMPOSANT :
1. Vue mensuelle : grille 7 colonnes (Lun-Dim), cases par jour
2. Chaque mission apparaît comme une barre colorée couvrant date_depart → date_retour
3. Couleurs par statut : brouillon=gris, soumis=bleu, approuvé=vert, rejeté=rouge
4. Clic sur une mission → popup avec résumé + lien vers détail
5. Navigation mois précédent/suivant
6. Vue mobile : liste chronologique au lieu de grille
7. Filtres : par statut, par direction
8. Dark mode complet

NE PAS utiliser de librairie calendrier externe — construire en Tailwind pur.
Données via api.get('/calendrier').

Après : npm run build
```

---

# ═══════════════════════════════════════════════════
# PHASE 5 — FEATURES BONUS WEB (#43 → #50)
# ═══════════════════════════════════════════════════

## PROMPT #43 🔵 — Route Calendrier + Sidebar

**Fichier** : Routeur principal (App.jsx)

```
/caveman

Ajouter la route /missions/calendrier → CalendrierMissions (lazy import)
Accessible par tous les rôles.
Ajouter l'entrée dans la Sidebar : icône Calendar, label "Calendrier", après "Missions".
UN SEUL fichier modifié.

Après : npm run build
```

---

## PROMPT #44 🔵 — Empreinte carbone des déplacements

**Fichier** : `backend/app/Services/CarboneService.php` (NOUVEAU)

```
/caveman

CONTEXTE : AT Réservations. Calcul de l'empreinte carbone pour la RSE — très tendance pour impressionner le jury.

CRÉER : backend/app/Services/CarboneService.php

SERVICE :
- calculerEmpreinte(Mission $mission): array
  - Si transport_type = 'avion' : ~0.255 kg CO2/km/passager
  - Si transport_type = 'terrestre' : ~0.171 kg CO2/km (voiture), ~0.029 kg CO2/km (train)
  - Estimer distance depuis une table simple wilayas → distances approximatives
  - Retourner : { co2_kg, equivalent_arbres (1 arbre absorbe ~22kg/an), transport_type, distance_km }

Ajouter une méthode dans un controller existant (ou DashboardController) :
- GET /dashboard/empreinte-carbone → total CO2 ce mois, ce trimestre, cette année
- Top 5 directions les plus polluantes

Après : php artisan test
```

---

## PROMPT #45 🔵 — Widget empreinte carbone frontend

**Fichier** : `frontend/src/components/Dashboard/CarbonWidget.jsx` (NOUVEAU)

```
/caveman

Widget pour le dashboard admin montrant :
1. Total CO2 ce mois (gros chiffre + icône Leaf verte)
2. Équivalent arbres nécessaires
3. Tendance vs mois précédent (flèche ↑↓)
4. Mini chart donut : répartition avion vs terrestre
5. Suggestion : "X missions auraient pu être en transport terrestre (-Y kg CO2)"

Dark mode, responsive. Couleurs : vert pour bon, orange pour moyen, rouge pour élevé.

Après : npm run build
```

---

## PROMPT #46 🔵 — Bon de commande PDF amélioré

**Fichier** : `backend/resources/views/pdf/bon-commande.blade.php` (ou similaire)

```
/caveman

Améliorer le PDF de bon de commande / ordre de mission :
1. En-tête avec logo Algérie Télécom (si image existe dans storage) et info DSI
2. Numéro de mission, date de création
3. Section demandeur : nom, prénom, direction, téléphone
4. Section mission : destination, dates, objectifs, transport_type, budget_mode
5. Section logistique (si logistique_ok) : hôtel assigné, véhicule, ticket Air Algérie
6. Section signatures : lignes pour signature demandeur, directeur, DML
7. Pied de page : "Document généré le DD/MM/YYYY — AT Réservations v2.0"
8. QR Code contenant l'URL de la mission (pour vérification)

Après : php artisan test
```

---

## PROMPT #47 🔵 — Export audit logs

**Fichier** : `frontend/src/pages/admin/AuditLogs.jsx`

```
/caveman

Ajouter le bouton export CSV côté client dans AuditLogs.jsx :
1. Bouton "Exporter CSV" en haut à droite
2. Exporter les logs actuellement filtrés (pas tous les logs)
3. Colonnes : Date, Utilisateur, Action, Détails, IP
4. Utiliser Blob + URL.createObjectURL pour le téléchargement
5. Aussi ajouter le composant Pagination (créé au prompt #11) dans cette page

Après : npm run build
```

---

## PROMPT #48 🔵 — Page "À propos" de l'application

**Fichier** : `frontend/src/pages/About.jsx` (NOUVEAU)

```
/caveman

Page d'information sur l'application pour la soutenance :
1. Logo AT + nom "AT Réservations v2.0"
2. Description : "Plateforme de gestion des missions et déplacements — DSI Algérie Télécom"
3. Stack technique (avec icônes) : React, Laravel, MySQL, Tailwind
4. Crédits : "Développé par [ton nom] — Projet de fin de formation ISIL"
5. Statistiques live : nombre d'utilisateurs, missions totales, prestataires
6. Version, date de dernière mise à jour
7. Animation d'entrée élégante (fade-in)
8. Dark mode complet
9. Couleurs AT : vert #00A650, bleu #003DA5

Après : npm run build
```

---

## PROMPT #49 🔵 — Accessibilité globale

**Fichier** : `frontend/src/components/UI/index.js` (et les composants UI)

```
/caveman

Améliorer l'accessibilité de TOUS les composants UI :
1. Ajouter aria-label sur tous les boutons icône-seul
2. Ajouter role="alert" sur les messages d'erreur/succès
3. Ajouter aria-live="polite" sur les compteurs de notifications
4. Focus visible : outline-2 outline-offset-2 outline-[#003DA5]
5. Skip link : "Aller au contenu principal" en haut de la page
6. Contraste : vérifier que tous les textes ont un ratio ≥ 4.5:1

UN SEUL fichier modifié à la fois.

Après : npm run build
```

---

## PROMPT #50 🔵 — Page d'accueil guest (landing page)

**Fichier** : `frontend/src/pages/auth/Login.jsx`

```
/caveman

Enrichir la page de login avec une section d'information pour les visiteurs :
1. Panel gauche (desktop) : garder le ParticleBackground et le formulaire login
2. Panel droit : ajouter 3 slides auto-rotate (5s chaque) montrant les features :
   - "Gérez vos missions de déplacement en quelques clics"
   - "Suivez en temps réel l'état de vos réservations"
   - "Validez les demandes depuis votre bureau"
3. Indicateurs de slide (dots) en bas
4. Logo AT + texte "Direction des Systèmes d'Information"
5. Animation de transition entre les slides (fade + slide)

⚠️ NE PAS toucher ParticleBackground.jsx ni FloatingBubbles.jsx
⚠️ NE PAS modifier le formulaire de login existant

Après : npm run build
```

---

# ═══════════════════════════════════════════════════
# PHASE 6 — FLUTTER MOBILE (F1 → F15)
# ═══════════════════════════════════════════════════

## PROMPT F1 🟣 — Push Notifications Firebase

**Fichier** : `mobile/at_reservations_mobile/lib/services/notification_service.dart` (NOUVEAU ou modifier existant)

```
/caveman

CONTEXTE : Flutter app AT Réservations. L'app utilise du polling pour les notifications. Ajouter Firebase Cloud Messaging pour les push notifications en temps réel.

MODIFICATIONS :
1. Ajouter firebase_messaging et flutter_local_notifications dans pubspec.yaml
2. Créer/modifier NotificationService :
   - Initialisation FCM au démarrage
   - Demande de permission (iOS + Android 13+)
   - Enregistrement du token FCM → POST /api/user/fcm-token (backend)
   - Handler foreground : afficher notification locale
   - Handler background : traitement silencieux
   - Handler tap : navigation vers la page correspondante (mission, validation, message)
3. Catégories de notification avec icônes et couleurs différentes

L'app a déjà GoRouter et Provider.
```

---

## PROMPT F2 🟣 — Login biométrique

**Fichier** : `mobile/at_reservations_mobile/lib/screens/auth/login_screen.dart`

```
/caveman

Ajouter l'authentification biométrique (empreinte + Face ID) :
1. Package : local_auth
2. Au démarrage, vérifier si un token est stocké dans flutter_secure_storage
3. Si oui, proposer "Se connecter avec biométrie" (icône empreinte)
4. Si biométrie réussie → utiliser le token stocké pour /auth/me
5. Si biométrie échoue ou non disponible → formulaire classique
6. Option dans les paramètres pour activer/désactiver la biométrie
7. Animation fluide entre le mode biométrie et le formulaire
```

---

## PROMPT F3 🟣 — Scan QR Code billet Air Algérie

**Fichier** : `mobile/at_reservations_mobile/lib/screens/dml/scan_ticket_screen.dart` (NOUVEAU)

```
/caveman

CONTEXTE : Le DML scanne les billets d'avion Air Algérie. L'app doit utiliser la caméra pour scanner le QR code du billet et extraire les informations.

SCREEN :
1. Package : mobile_scanner (ou qr_code_scanner)
2. Vue caméra plein écran avec guide de cadrage (carré vert animé)
3. Au scan du QR → parser les données (numéro vol, date, passager, PNR)
4. Afficher les données extraites dans un formulaire pré-rempli
5. Bouton "Confirmer et enregistrer" → POST /dml/missions/{id}/assigner-vehicule avec les données du ticket
6. Si le QR n'est pas un billet valide → message d'erreur "QR code non reconnu"
7. Mode lampe torche (bouton flash)
8. Historique des derniers scans

RÈGLE MÉTIER : Le DML va au bureau Air Algérie INTERNE chez AT, récupère le billet, puis le scanne dans l'app.
```

---

## PROMPT F4 🟣 — OCR Scan justificatifs

**Fichier** : `mobile/at_reservations_mobile/lib/screens/missions/scan_justificatif_screen.dart` (NOUVEAU)

```
/caveman

CONTEXTE : Mode "remboursement" — l'employé ramène des factures/reçus. L'app doit scanner ces documents.

SCREEN :
1. Package : google_mlkit_text_recognition (ou flutter_tesseract_ocr)
2. Prise de photo avec cadrage automatique du document (edge detection si possible)
3. OCR sur l'image → extraction texte
4. Parser les données : montant (regex pour chiffres + "DA" ou "DZD"), date, nom prestataire
5. Formulaire pré-rempli avec les données extraites (modifiable par l'utilisateur)
6. Upload vers POST /missions/{id}/documents en multipart
7. Preview de l'image avant envoi
8. Compression automatique de l'image (max 2MB)
```

---

## PROMPT F5 🟣 — Mode hors-ligne + synchronisation

**Fichier** : `mobile/at_reservations_mobile/lib/services/offline_service.dart` (NOUVEAU)

```
/caveman

CONTEXTE : Les agents en mission n'ont pas toujours de réseau. L'app doit fonctionner hors-ligne.

SERVICE :
1. Package : connectivity_plus + sqflite (ou hive)
2. Cache local des données critiques :
   - Missions de l'utilisateur (dernière sync)
   - Conversations récentes
   - Notifications
3. File d'attente des actions hors-ligne :
   - Création de mission (brouillon)
   - Envoi de message
   - Upload de document (mis en queue)
4. Indicateur visuel : bannière "Mode hors-ligne" en haut de l'app (orange)
5. Sync automatique au retour du réseau :
   - Traiter la queue dans l'ordre chronologique
   - Notification "3 actions synchronisées" au retour en ligne
6. Conflit : si une mission a été modifiée entre-temps → alerter l'utilisateur
```

---

## PROMPT F6 🟣 — Géolocalisation pointage mission

**Fichier** : `mobile/at_reservations_mobile/lib/screens/missions/geolocation_screen.dart` (NOUVEAU)

```
/caveman

CONTEXTE : Preuve de présence — l'employé pointe son arrivée/départ de mission via GPS.

SCREEN :
1. Package : geolocator + geocoding
2. Bouton "J'y suis — Pointer mon arrivée" (visible uniquement pendant les dates de mission)
3. Au clic : capturer position GPS + timestamp
4. Reverse geocoding → afficher l'adresse lisible
5. Vérifier proximité avec la destination de la mission (tolérance 5km)
6. POST /missions/{id}/pointage avec { type: 'arrivee'|'depart', latitude, longitude, adresse, timestamp }
7. Historique des pointages sur la fiche mission
8. Carte mini avec marqueur de position
```

---

## PROMPT F7 🟣 — Swipe-to-approve pour validateur

**Fichier** : `mobile/at_reservations_mobile/lib/screens/validations/validation_list_screen.dart`

```
/caveman

CONTEXTE : Le directeur/validateur doit pouvoir approuver/rejeter rapidement les missions.

MODIFICATIONS :
1. Swipe droite → Approuver (fond vert + icône CheckCircle)
2. Swipe gauche → Rejeter (fond rouge + icône X) + popup pour motif obligatoire
3. Animation de confirmation (check mark animé vert)
4. Feedback haptique (vibration courte pour approuver, double vibration pour rejeter)
5. Bouton "Annuler" pendant 3 secondes après le swipe (undo)
6. Badge compteur sur l'onglet validations
```

---

## PROMPT F8 🟣 — Widget écran d'accueil

**Fichier** : `mobile/at_reservations_mobile/lib/widgets/home_widget.dart` (NOUVEAU)

```
/caveman

Widget Android pour l'écran d'accueil (Home Screen Widget) :
1. Package : home_widget
2. Affiche : nombre de validations en attente + prochaine mission
3. Mise à jour toutes les 15 minutes (WorkManager)
4. Tap → ouvre l'app sur la page correspondante
5. Design AT : fond blanc/sombre, accent vert #00A650
```

---

## PROMPT F9 🟣 — Partage natif PDF + Share sheet

**Fichier** : `mobile/at_reservations_mobile/lib/services/share_service.dart` (NOUVEAU)

```
/caveman

Partage natif des PDF générés :
1. Package : share_plus + path_provider
2. Télécharger le PDF de l'ordre de mission
3. Ouvrir la share sheet native (WhatsApp, Gmail, Telegram, etc.)
4. Aussi : partager un résumé texte de la mission
5. Bouton de partage sur la fiche mission détail
```

---

## PROMPT F10 🟣 — Check-list voyage actif

**Fichier** : `mobile/at_reservations_mobile/lib/screens/missions/checklist_screen.dart` (NOUVEAU)

```
/caveman

Pendant une mission active, une check-list interactive :
1. Éléments auto-générés selon la mission :
   - Billet d'avion (si transport_type = avion)
   - Réservation hôtel (si hébergement réservé)
   - Documents de mission (ordre de mission PDF)
   - Contacts urgence DML
   - Frais / justificatifs à ramener (si budget_mode = remboursement)
2. Cases à cocher avec progression (3/5 complétés)
3. Bouton appel direct DML (icône Phone)
4. Accès rapide aux documents téléchargés (hors-ligne)
5. Notification rappel la veille du départ
```

---

## PROMPT F11 🟣 — Dictée vocale

**Fichier** : `mobile/at_reservations_mobile/lib/widgets/voice_input.dart` (NOUVEAU)

```
/caveman

Widget réutilisable pour saisie vocale :
1. Package : speech_to_text
2. Bouton micro animé (pulse quand actif)
3. Langue : français (fr-FR)
4. Intégrer dans : champ objectif mission, commentaires, messagerie
5. Feedback visuel : texte apparaît en temps réel pendant la dictée
6. Bouton stop + confirmation avant insertion
```

---

## PROMPT F12 🟣 — Dark mode auto selon luminosité

**Fichier** : `mobile/at_reservations_mobile/lib/providers/theme_provider.dart`

```
/caveman

Améliorer le thème provider existant :
1. Mode auto : basé sur les paramètres système (MediaQuery.platformBrightnessOf)
2. Option dans les paramètres : Clair / Sombre / Automatique
3. Transition animée entre les thèmes (durée 300ms)
4. Sauvegarder le choix dans SharedPreferences
5. Appliquer immédiatement sans redémarrer l'app
```

---

## PROMPT F13 🟣 — Retours haptiques différenciés

**Fichier** : `mobile/at_reservations_mobile/lib/utils/haptics.dart` (NOUVEAU)

```
/caveman

Utilitaire pour retours haptiques :
1. Package : vibration ou HapticFeedback natif
2. Types :
   - success() → vibration courte (approval, save OK)
   - error() → double vibration (rejection, erreur)
   - warning() → vibration longue (alerte budget)
   - selection() → impact léger (tap menu, swipe)
3. Intégrer dans : swipe-to-approve, envoi message, changement de statut
4. Désactivable dans les paramètres
```

---

## PROMPT F14 🟣 — Bouton SOS DML

**Fichier** : `mobile/at_reservations_mobile/lib/widgets/sos_button.dart` (NOUVEAU)

```
/caveman

Bouton d'urgence pour contacter le DML pendant une mission :
1. FAB (Floating Action Button) rouge visible sur les écrans mission active
2. Au tap :
   - Option 1 : Appel direct téléphone DML (url_launcher tel:)
   - Option 2 : Message urgent prédéfini dans la messagerie
   - Option 3 : Envoyer position GPS + message "Besoin d'assistance"
3. Animation : pulse rouge quand une mission est en cours
4. Accessible uniquement quand une mission est entre date_depart et date_retour
```

---

## PROMPT F15 🟣 — Compression images auto

**Fichier** : `mobile/at_reservations_mobile/lib/utils/image_compressor.dart` (NOUVEAU)

```
/caveman

Utilitaire de compression pour les justificatifs :
1. Package : flutter_image_compress
2. Compression JPEG qualité 70% si > 2MB
3. Redimensionner à max 1920px largeur si plus grand
4. Conserver les métadonnées EXIF (date, GPS si disponible)
5. Retourner le fichier compressé + taille avant/après
6. Utiliser AVANT chaque upload de document/justificatif
7. Indicateur visuel : "Image compressée : 4.2MB → 890KB"
```

---

# ═══════════════════════════════════════════════════
# 📋 CHECKLIST FINALE AVANT SOUTENANCE
# ═══════════════════════════════════════════════════

```
□ Tous les prompts exécutés sans erreur
□ npm run build réussi (0 errors, 0 warnings)
□ php artisan migrate réussi
□ Dark mode vérifié sur CHAQUE page (Chrome DevTools toggle)
□ Test avec les 3 rôles : admin, validateur, demandeur + agent_dml
□ Mobile Flutter : build APK release réussi
□ GitHub repo PRIVÉ
□ .env pas dans le repo
□ Données de test cohérentes (ATUsersSeeder intact)
□ PDF ordre de mission généré correctement
□ Performance : Lighthouse score > 80
□ Pas de console.error dans le navigateur
```

---

**Total : 50 prompts Web + 15 prompts Flutter = 65 prompts**
**Estimation : ~3-4 sessions Claude Code de 4h chacune**
