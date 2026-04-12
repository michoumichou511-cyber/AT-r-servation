# AT Réservations — documentation de référence du projet

**Date de rédaction :** avril 2026  
**Périmètre :** dépôt `ProjetFinFormation` (frontend React + backend Laravel).

---

## 1. Ce que ce document est — et ce qu’il n’est pas

### 1.1 Limite honnête

Il est **impossible** de décrire **ligne par ligne** **chaque fichier** du dépôt dans un seul document lisible : le projet compte **des centaines de fichiers** et **des dizaines de milliers de lignes** (frontend, backend, migrations, tests, config, etc.). Une telle « bible ligne à ligne » serait gigantesque, impossible à maintenir à la main, et dépasserait les capacités pratiques de génération.

### 1.2 Ce que ce fichier fournit à la place

- Une **vue d’ensemble** du dépôt et des **dossiers importants**.
- Le **parcours par rôle** : ce que chaque type d’utilisateur **voit** et **peut faire** dans l’application (aligné sur les routes React et les garde-fous backend).
- Les **principes de sécurité** (auth, API, rôles).
- Les **choix de design** récurrents (marque AT, thème, composants).
- Une section **« travaux et évolutions récents »** (relecture des conversations / changements connus sur le dépôt).
- Une section **risques de sécurité, bugs possibles, risques futurs** et check-list avant production (section 7).
- Un **tableau de bord des améliorations** (backlog idées / prompts) avec indication **présent / partiel / absent** dans le dépôt (section 9).

Pour le détail **fichier par fichier**, la source de vérité reste le **code** ; ce document sert de **carte** et de **guide métier / technique**.

---

## 2. Structure du dépôt (vue rapide)

```
ProjetFinFormation/
├── frontend/          # SPA React (Vite), interface AT Réservations
├── backend/           # API Laravel (Sanctum), base de données, emails, PDF
└── docs/              # Documentation (dont ce fichier)
```

---

## 3. Frontend (`frontend/`)

### 3.1 Technologies

- **React 18**, **React Router**, **Vite**
- **Tailwind CSS** pour le style
- **Framer Motion** pour les animations (pages, sidebar, etc.)
- **Axios** (via `services/api.js`) pour appeler l’API Laravel
- **react-hot-toast** pour les notifications utilisateur

### 3.2 Point d’entrée et navigation

| Fichier | Rôle |
|--------|------|
| `src/main.jsx` | Monte l’app React sur le DOM |
| `src/App.jsx` | **Routes** : login, register, pages privées avec `MainLayout`, lazy loading, gestion 401 (session expirée → login), fond animé global hors `/login` et `/register` |
| `src/components/Common/PrivateRoute.jsx` | Protège les routes : token requis, optionnellement **liste de rôles** ; sinon redirection `/login` ou `/403` |
| `src/contexts/AuthContext.jsx` | **Session** : token `at_token` dans `localStorage`, appel `/auth/me`, `login` / `logout`, `hasRole`, mode sombre `at_dark` |

### 3.3 Routes utilisateur (ce que l’UI expose)

Défini dans `App.jsx` (synthèse) :

| Chemin | Contenu | Rôle côté UI |
|--------|---------|----------------|
| `/login` | Connexion | Public (si déjà connecté → `/`) |
| `/register` | Inscription | Public |
| `/` | Tableau de bord | Tout utilisateur connecté |
| `/organigramme` | Organigramme | Connecté |
| `/missions` | Liste des missions | Connecté |
| `/missions/nouvelle` | Assistant nouvelle mission | Connecté |
| `/missions/:id` | Détail mission | Connecté |
| `/validations` | File de validation | **validateur** ou **admin** |
| `/messagerie` | Messagerie | Connecté |
| `/notifications` | Notifications | Connecté |
| `/profil` | Profil / mot de passe / avatar | Connecté |
| `/rapports` | Rapports | **admin** ou **validateur** |
| `/admin/utilisateurs` | Gestion utilisateurs | **admin** |
| `/admin/prestataires` | Prestataires | **admin** |
| `/admin/budgets` | Budgets | **admin** |
| `/admin/audit-logs` | Journaux d’audit | **admin** |
| `/admin/statistiques` | Statistiques | **admin** |
| `*` | Page 404 | — |

La **barre latérale** (`components/Layout/Sidebar.jsx`) affiche les entrées selon `hasRole` (validateur, admin) : par exemple « Validations », « Rapports », bloc « Administration » uniquement pour **admin**.

### 3.4 Dossiers `src/` (à quoi ils servent)

| Dossier | Contenu typique |
|---------|------------------|
| `components/Common/` | Composants transverses : `ErrorBoundary`, `PrivateRoute`, `FloatingBubbles` (fond canvas particules + vagues), `PageHeader`, etc. |
| `components/Layout/` | `MainLayout`, `Sidebar`, `Navbar` — structure des pages authentifiées |
| `components/Dashboard/` | Éléments du tableau de bord (ex. `ParticleBackground`, `CustomCursor` sur le dashboard) |
| `components/UI/` | Boutons, inputs, cartes, en-têtes de page réutilisables |
| `components/auth/` | Décors liés à l’auth (ex. `LoginDecor3D` lazy-loadé sur la page login) |
| `pages/` | Une page = une route ou un sous-ensemble (missions, admin, erreurs 403/404) |
| `services/api.js` | Client HTTP : base URL, intercepteurs, modules `authAPI`, `missionsAPI`, etc. |
| `hooks/` | Hooks réutilisables (ex. polling pour badges messagerie / notifications) |

### 3.5 Design (identité Algérie Télécom)

- **Couleurs** récurrentes : vert `#00A650`, bleu `#003DA5` (bulles, focus, badges, réseau de particules dans `FloatingBubbles`).
- **Typographie** : IBM Plex Sans (toasts et parties de l’UI).
- **Login (desktop)** : colonne gauche (vidéo logo, dégradé, texte d’accueil, badge « espace employé », encadré « accès sécurisé ») ; colonne droite formulaire ; décor 3D optionnel si les animations ne sont pas réduites.
- **Login (mobile)** : mise en page adaptée (largeur &lt; 768px), canvas / animations dédiées dans le composant mobile du fichier Login.
- **Pages authentifiées** : `MainLayout` avec `FloatingBubbles` (fond fixe canvas) + pour le dashboard, curseur personnalisé et autres effets selon la page.
- **Mode sombre** : classe `dark` sur `<html>`, préférence stockée dans `localStorage` (`at_dark`).

### 3.6 Sécurité côté frontend (limites)

- Le **token** est stocké dans **`localStorage`** : pratique pour une SPA, mais exposé en cas de XSS — d’où l’importance de ne pas injecter du HTML non fiable, de valider les entrées, et de garder les dépendances à jour.
- Les **rôles** sur les routes React **ne suffisent pas** : l’API Laravel doit **toujours** revérifier les permissions (c’est le cas pour les routes `admin` avec middleware `role:admin`).
- En cas de **401**, le client peut déclencher `clearSession` et rediriger vers `/login` (`SessionExpiredNav` dans `App.jsx`).

---

## 4. Backend (`backend/`)

### 4.1 Technologies

- **Laravel**, API **REST** sous préfixe `/api` (selon configuration du serveur)
- **Laravel Sanctum** pour l’authentification par token
- **Middleware** : `auth:sanctum`, `active`, `throttle`, `role:admin` sur le groupe admin

### 4.2 Routes API (synthèse)

Fichier principal : `routes/api.php`.

- **Public + anti brute-force** : `POST /auth/login`, `POST /auth/register` avec `throttle:5,1` (5 tentatives par minute typiquement).
- **Authentifié** (`auth:sanctum`, `active`, `throttle:60,1`) : profil, missions, réservations, billets, hébergements, restaurations, validations, notifications, messagerie, documents, dashboard, recherche, calendrier, prestataires (lecture / favoris / évaluations), exports avec throttle renforcé sur certains exports.
- **Admin uniquement** (`middleware('role:admin')`, préfixe `admin/`) : liste utilisateurs, activer/désactiver, changer rôle, CRUD prestataires côté admin, budgets, audit logs.

**Note :** une route **`/test-email`** existe pour tester SMTP — le commentaire dans le code indique de la retirer en production.

### 4.3 Sécurité côté serveur

- **Sanctum** : les actions sensibles exigent un token valide.
- **Throttle** : limite les abus (login, exports).
- **Rôle admin** : appliqué côté serveur pour les opérations d’administration, pas seulement masquées dans le menu.

### 4.4 Données métier (aperçu)

Modèles et migrations couvrent notamment : **users**, **roles**, **missions**, **réservations**, **billets**, **hébergements**, **restaurations**, **notifications**, **messages**, **documents**, **audit**, **budgets**, **prestataires**, **évaluations**, etc. Le détail des champs est dans les migrations et les modèles `app/Models/`.

---

## 5. Utilisateurs : rôles et expérience (ce qu’ils voient / font)

Les noms de rôles utilisés dans le front (`hasRole`, `Sidebar`) incluent notamment : **admin**, **validateur**, **utilisateur**, **demandeur** (badges et couleurs dans la sidebar). Les **routes sensibles** sont surtout restreintes par **admin** et **validateur** comme indiqué dans `App.jsx`.

### 5.1 Utilisateur classique (ex. `utilisateur` / `demandeur`)

- Accès : tableau de bord, organigramme, **mes missions** (liste, création via assistant, détail), messagerie, notifications, profil.
- **Pas** d’accès menu Validations, Rapports (selon routes), ni section Administration.

### 5.2 Validateur (+ souvent les droits « utilisateur »)

- Tout ce que l’utilisateur classique peut faire **plus** :
  - Page **Validations** (file à traiter : approuver, rejeter, demander modification — selon implémentation API).
  - Page **Rapports** (si la route est ouverte aux validateurs dans `App.jsx`).

### 5.3 Administrateur

- Tout ce qui précède **plus** :
  - Section **Administration** dans la sidebar : Utilisateurs, Prestataires, Budgets, Audit logs, Statistiques.
  - Contrôle utilisateurs (activation, rôle) via API `admin/…` — **toujours** protégé par le middleware `role:admin` côté Laravel.

### 5.4 Visiteur non connecté

- Accès à `/login` et `/register` uniquement (les autres routes privées redirigent vers login).

---

## 6. Travaux et évolutions récents (contexte projet / sessions de dev)

Cette section résume des **changements discutés ou effectués** dans le cadre du développement (non exhaustive du dépôt entier sur toute l’histoire Git).

- **Page Login** : conservation / restauration d’une mise en page « desktop » riche (colonne gauche AT, formulaire à droite) ; variante mobile avec fond animé dédié ; décor 3D lazy-loadé (`LoginDecor3D`).
- **Fond global** : `AnimatedBackground` désactivé sur `/login` et `/register` dans `App.jsx` pour éviter la superposition avec le fond propre à la page d’auth ; fond animé conservé sur les pages authentifiées.
- **`FloatingBubbles`** : composant refondu en **canvas** (particules vertes/bleues, liaisons entre points proches, vagues en bas) ; utilisé dans `MainLayout` (`count={8}`) et sur la page Login desktop (`count={15}`) derrière le contenu en `position: fixed` / `z-index: 0`.
- **`MainLayout`** : layout principal avec sidebar, navbar, `Outlet`, bulles / curseur sur dashboard selon configuration actuelle.
- **`api.js`** : nettoyage / alignement des appels (URL de base via `VITE_API_URL`, gestion d’erreurs, suppression de références obsolètes à certains hébergeurs dans les messages — selon commits récents).
- **Session expirée** : navigation vers `/login` sans rechargement brutal de la SPA lors des 401.

---

## 7. Risques de sécurité, bugs possibles et dette technique

Cette section liste des **points d’attention** (non exhaustifs) : à vérifier dans le code au fil du temps, pas une liste de CVE officielles.

### 7.1 Faiblesses ou limites de sécurité (à traiter en production)

| Risque | Description | Mitigation typique |
|--------|-------------|-------------------|
| **Token dans `localStorage`** | Toute faille **XSS** (script injecté dans la page) peut lire le token et usurper l’utilisateur. | Réduire XSS : échapper les contenus, CSP, audits deps ; en alternative forte : cookies **HttpOnly** + SameSite (souvent avec BFF ou config Sanctum domain). |
| **Contrôle d’accès uniquement côté React** | Masquer un bouton ou une route ne suffit pas : un utilisateur peut appeler l’API directement (Postman, curl). | **Toujours** autoriser / refuser l’action dans Laravel (policies, middleware `role`, vérification `user_id` sur les ressources). |
| **IDOR / accès croisé** | Si un contrôleur ne vérifie pas que la mission / document / message appartient bien à l’utilisateur (ou à son rôle), fuite de données. | Tests d’intégration ; revue des `show` / `update` / `destroy` avec `$request->user()`. |
| **Route `/test-email` (ou similaire)** | Si laissée en prod, peut servir à du spam ou révéler la config mail. | **Supprimer** ou protéger par env `APP_DEBUG` + IP admin, ou feature flag. |
| **Inscription ouverte (`/auth/register`)** | Selon la politique métier, création de comptes sans validation = comptes fantômes ou abus. | Désactiver l’inscription publique, invitation uniquement, ou validation admin. |
| **Brute force login** | Le throttle `5,1` limite mais n’empêche pas la répartition sur plusieurs IP (botnets). | WAF, captcha après N échecs, surveillance des logs. |
| **Fichiers `.env` et secrets** | Fuite de `APP_KEY`, DB, clés SMTP si commitées ou mal partagées. | `.env` jamais versionné ; rotation des secrets ; revue des dépôts publics. |
| **CORS et origines** | Mauvaise config = soit blocage légitime, soit trop permissif. | Liste blanche d’origines côté Laravel ; pas de `*` avec credentials. |
| **Uploads (avatars, documents)** | Risque de fichiers malveillants si type MIME non vérifié côté serveur. | Validation stricte, stockage hors webroot ou noms non prévisibles, antivirus optionnel. |
| **Messagerie / contenu riche** | Si HTML affiché sans sanitization → XSS stocké. | Sanitizer (DOMPurify côté client si besoin ; échappement côté serveur pour les emails). |
| **Dépendances npm / Composer** | Vulnérabilités connues dans les librairies. | `npm audit`, `composer audit`, mises à jour régulières. |

### 7.2 Bugs possibles ou scénarios à risque (application)

| Zone | Problème potentiel | Piste |
|------|-------------------|--------|
| **Session / 401** | Déconnexion brutale si l’horloge client/serveur ou un proxy coupe les requêtes. | Gestion d’erreur réseau déjà partiellement gérée ; à tester hors ligne. |
| **`hasRole` par substring** | Si un rôle s’appelait `superadmin`, `admin` pourrait matcher selon l’implémentation (à vérifier dans `PrivateRoute` : `includes`). | Préférer une **égalité stricte** ou une liste blanche de rôles exacts. |
| **Canvas / animations** | `FloatingBubbles` + autres canvas = charge CPU sur machines faibles ou onglets multiples. | Respect `prefers-reduced-motion` (partiellement ailleurs) ; option « désactiver les effets ». |
| **Lazy loading** | Chunk manquant ou erreur réseau → écran blanc si ErrorBoundary ne couvre pas. | Surveiller les logs build et les rapports Sentry (si ajoutés). |
| **Polling (sidebar)** | Appels répétés messages / notifications : en cas d’API lente, accumulation de requêtes ou erreurs silencieuses. | Intervalles déjà espacés ; backoff en cas d’erreur possible. |
| **Mobile / responsive** | Seuil 768px : comportement différent login ; utilisateurs « entre deux » peuvent être surpris. | Tests sur vrais appareils. |
| **Données affichées** | Montants, dates, statuts : erreurs d’arrondi ou fuseaux horaires si non normalisés côté API. | Toujours traiter les dates en UTC côté backend, format local côté front. |

### 7.3 Risques « futurs » (évolution du projet)

- **Montée en charge** : throttle global `60,1` peut suffire au début ; sous forte charge, files d’attente, cache Redis, index SQL.
- **Conformité** : données personnelles (RGPD / lois locales) : durée de conservation, droit à l’effacement, registre des traitements — à documenter si mise en prod réelle.
- **Multi-tenant / multi-structure** : si le modèle évolue, risque de mélange de données si les requêtes ne filtrent pas par `structure_id` (ou équivalent).
- **Clés API / intégrations** : toute nouvelle intégration (SMS, paiement) ajoute des surfaces d’attaque.

### 7.4 Check-list avant mise en production (rappel)

1. `APP_DEBUG=false`, `APP_ENV=production`.
2. Retirer routes de test (`/test-email`, etc.).
3. HTTPS partout, cookies sécurisés si utilisés.
4. Sauvegardes base de données automatisées.
5. Logs d’audit consultés (`audit-logs` côté métier + logs serveur).
6. Revue des comptes admin et politique de mots de passe.

---

## 8. Comment aller plus loin (si vous voulez « tout » le détail technique)

1. **Par fonctionnalité** : ouvrir `App.jsx` → suivre la route → lire la page sous `pages/` → suivre les imports vers `components/` et `services/api.js` → croiser avec `routes/api.php` et le contrôleur Laravel correspondant.
2. **Par rôle** : vérifier `PrivateRoute` dans `App.jsx`, puis **toujours** les policies / middleware dans `app/Http` pour le même chemin API.
3. **Schéma base de données** : dossier `backend/database/migrations/`.
4. **Tests** : `backend/tests/` (ex. permissions, missions).

---

## 9. Tableau de bord des améliorations (backlog — idées organisées par catégorie)

Cette section reprend une **vision produit / soutenance** (type tableau de bord : complétude, bugs, widgets, features). Pour chaque ligne, un **indicateur** indique si l’idée est déjà **reflétée dans ce dépôt local** au moment de la rédaction, **sans modifier le code** — uniquement une lecture du projet.

**Légende :** **Oui** = présent ou largement couvert · **Partiel** = existe en partie ou risque connu · **Non** = absent ou non observable dans le repo · **Ops** = hors code (GitHub, serveur, secrets).

**Indicateurs globaux (exemple type soutenance, à ajuster selon l’avancement réel) :** complétude ~88 %, bugs actifs à traiter, widgets optionnels, features futures — les chiffres exacts dépendent des tests et du déploiement.

### 9.1 Bugs prioritaires

| Idée / sujet | Dans le projet (ce dépôt) | Commentaire rapide |
|--------------|---------------------------|---------------------|
| **Crash Statistiques** — `.map()` / données Recharts `undefined` | **Partiel** | La page `admin/Statistiques.jsx` utilise Recharts avec chargements et états ; un crash reste possible si l’API renvoie une forme inattendue — à sécuriser avec tableaux par défaut. |
| **Exports 500 SQL** — colonnes direction / montant | **Partiel / à valider** | Exports côté Laravel ; la correction dépend du schéma SQL et des requêtes d’export — à tester en conditions réelles. |
| **Rejet mission 400** — mismatch ENUM (`annule`, etc.) | **Partiel** | Le backend définit des statuts (ex. `annule` dans `MissionStatut` / migrations). Un 400 peut encore survenir si le front ou une ancienne migration envoie une valeur hors ENUM. |
| **Rôles affichés « Admin »** — mauvais champ | **Partiel** | Affichage basé sur `user.role?.name` / `role` dans Sidebar et Profil ; à vérifier si l’API renvoie toujours la même structure. |
| **Dark mode — texte noir** — styles inline | **Partiel** | Certaines pages (ex. Login) mélangent styles inline et classes ; le thème sombre peut être incohérent sur certains blocs. |
| **Missions en doublon** — nettoyage (tinker) | **Ops** | Pas de script versionné ici ; opération base de données au cas par cas. |

### 9.2 Sécurité

| Idée / sujet | Dans le projet (ce dépôt) | Commentaire rapide |
|--------------|---------------------------|---------------------|
| **Repos GitHub privés** | **Ops** | Non vérifiable depuis les fichiers ; à régler dans les paramètres GitHub du compte. |
| **Régénérer `APP_KEY`** | **Ops** | Commande `php artisan key:generate` sur l’environnement cible ; pas dans le dépôt. |
| **Validation API — Sanctum sur les endpoints** | **Oui** | `routes/api.php` : groupe `auth:sanctum`, `active`, throttle ; routes `admin` avec `role:admin`. |
| **Rotation mots de passe DB / SMTP** | **Ops** | Bonne pratique déploiement ; `.env` non versionné (voir `.gitignore`). |
| **`.gitignore` — `.env` ignoré** | **Oui** | `.env` et `.env.*` listés dans `.gitignore` à la racine du projet. |

### 9.3 Design et UI

| Idée / sujet | Dans le projet (ce dépôt) | Commentaire rapide |
|--------------|---------------------------|---------------------|
| **4 widgets dashboard** (semaine, pipeline, destinations, budget) | **Partiel** | Le `Dashboard` et les stats existent ; le détail « 4 widgets exacts » type soutenance peut nécessiter compléments selon maquette. |
| **Formulaire mission — stepper multi-étapes + validation** | **Oui** | `NewMissionWizard.jsx` + composant `Stepper` (`STEPS`, étapes 1–4). |
| **Circuit validation — timeline + badges animés** | **Partiel** | Validations et pages dédiées existent ; une timeline très visuelle peut être partielle selon les écrans. |
| **Logo 3D Spline (.glb) via React Three Fiber** | **Non / autre** | Le projet utilise plutôt `LoginDecor3D` (lazy) et canvas ; pas de `pubspec` / pas de dépendance Spline identifiée comme telle dans ce doc. |
| **Loader 3D dashboard non bloquant (R3F)** | **Non** | Non identifié comme composant dédié « loader 3D » dans la synthèse actuelle. |
| **Bibliothèques type Aceternity / Tremor** | **Non** | Stack actuelle : Tailwind, Framer Motion, Recharts, etc. ; pas de catalogue « premium » listé ici. |

### 9.4 Code et performance

| Idée / sujet | Dans le projet (ce dépôt) | Commentaire rapide |
|--------------|---------------------------|---------------------|
| **Polling optimisé** — 60 s messages / 30 s notifications | **Oui** | `Sidebar.jsx` : `usePolling` à **60000 ms** et **30000 ms** pour les compteurs. |
| **Admin crée une mission pour un demandeur** | **Non / à confirmer** | Délégation métier précise à vérifier dans les parcours et l’API ; pas documenté comme fonctionnalité dédiée ici. |
| **Exports Excel / PDF** — après fix SQL | **Partiel** | Routes et exports backend présents ; dépend des corrections de schéma / colonnes. |
| **RBAC frontend — garde par rôle** | **Oui** | `PrivateRoute` + `roles` dans `App.jsx` ; `hasRole` dans `AuthContext` et Sidebar. |
| **Checklist soutenance** (login → dashboard → orga → mission) | **Parcours manuel** | Les routes existent ; la checklist est un **processus de test**, pas un fichier automatisé dans le repo. |

### 9.5 Flutter mobile

| Idée / sujet | Dans le projet (ce dépôt) | Commentaire rapide |
|--------------|---------------------------|---------------------|
| **Initialiser un projet Flutter + auth Sanctum** | **Non** | Aucun `pubspec.yaml` à la racine du monorepo — pas d’app Flutter dans ce dépôt. |
| **Pages minimales MVP soutenance** | **Non** | Idem — prévu hors ce repository ou à créer. |
| **Thème AT Flutter** (`#00A650` / `#003DA5`) | **Non** | Cohérent avec la charte web si un jour un projet Flutter est ajouté. |

### 9.6 Prompts Cursor (utilisation)

Pour chaque ligne du tableau, vous pouvez copier une ligne dans Cursor sous la forme : *« Implémente / corrige : [description] en respectant le stack Laravel + React du projet AT Réservations. »* Les CSS ou fragments hors sujet collés par erreur dans un chat ne font pas partie du backlog.

---

## 10. Remerciement

Ce document est une **synthèse** pour équipe, reprise de projet ou soutenance. Pour toute évolution, **mettre à jour ce fichier** lors de changements majeurs de routes, rôles ou sécurité afin qu’il reste utile.

*Fin du document.*
