# Guide setup — design AT, règle Cursor et skills (frontend)

## Rôle de chaque fichier

| Fichier | Emplacement | Rôle |
|--------|-------------|------|
| **DESIGN.md** | [DESIGN.md](DESIGN.md) à la racine **`frontend/`** | Bible design AT Réservations : couleurs, polices, espacements, animations. **Source de vérité** pour l’UI (éviter les couleurs inventées par l’agent). |
| **at-design-system.mdc** | [.cursor/rules/at-design-system.mdc](.cursor/rules/at-design-system.mdc) | Règle Cursor `alwaysApply` : avant tout fichier `.jsx` / `.tsx` / `.css`, appliquer `DESIGN.md` + contraintes AT, Framer Motion, un fichier par prompt, etc. |
| **Ce guide** | `GUIDE_SETUP_SKILLS.md` | Procédure d’installation des skills et **prompt de session** à réutiliser. |

## Installation des skills (`npx`)

Ouvrir un terminal dans **`frontend/`** et exécuter **une commande à la fois** :

```bash
cd frontend
npx skills add emilkowalski/skill -y
npx skills add pbakaus/impeccable -y
npx skills add https://github.com/leonxlnx/taste-skill -y
```

- **Sans `-y`** : un menu interactif s’affiche → cocher **Cursor** (Espace), puis Entrée.
- **Avec `-y`** : installation sans invite (recommandé en script / CI).

### Où les fichiers sont installés (CLI `skills` v1.x)

Le paquet installe les skills sous :

```text
frontend/.agents/skills/<nom-du-skill>/
```

et les associe aux agents listés (dont **Cursor**). Il n’y a pas forcément de dossier `frontend/.cursor/skills/` : c’est normal avec les versions récentes du CLI.

### Skills ciblés par ce projet (après installation)

| Dépôt / commande | Dossier principal à référencer | Apport |
|------------------|----------------------------------|--------|
| `emilkowalski/skill` | `.agents/skills/emil-design-eng` | Micro-interactions, polish UI, détails « invisibles » |
| `pbakaus/impeccable` | `.agents/skills/impeccable` (+ bundle de skills du même repo : `adapt`, `animate`, `typeset`, etc.) | Typographie, espacements, rigueur visuelle |
| `leonxlnx/taste-skill` | `.agents/skills/stitch-design-taste`, `design-taste-frontend`, etc. | Hiérarchie visuelle, goût éditorial |

> **Note :** `pbakaus/impeccable` installe **plusieurs** skills d’un coup (bundle). `taste-skill` installe **plusieurs** variantes (design taste). Pour une tâche précise, citer le sous-dossier le plus adapté dans le prompt.

## Structure réelle (résumé)

```text
frontend/
├── DESIGN.md
├── GUIDE_SETUP_SKILLS.md          ← ce fichier
├── .cursor/
│   └── rules/
│       └── at-design-system.mdc
└── .agents/
    └── skills/
        ├── emil-design-eng/
        ├── impeccable/
        ├── stitch-design-taste/
        ├── design-taste-frontend/
        └── … (autres skills du bundle impeccable / taste-skill)
```

## Prompt à coller en début de session Cursor

Copier-coller **une fois** au début d’une session (ou quand vous changez de branche / machine) :

```text
Avant de commencer, lis et applique ces fichiers de référence du projet :
- DESIGN.md (racine frontend/) → système de design AT Réservations complet
- .cursor/rules/at-design-system.mdc → règles automatiques du projet
- .agents/skills/emil-design-eng/ → philosophie polish UI (Emil Kowalski)
- .agents/skills/impeccable/ → rigueur typographique et espacements
- .agents/skills/stitch-design-taste/ ou design-taste-frontend/ → hiérarchie visuelle et goût éditorial

Règles absolues :
- Couleurs AT uniquement : #00A650 (vert) et #003DA5 (bleu) pour l’identité (voir DESIGN.md pour les dérivés)
- Ne jamais toucher database/seeders/ATUsersSeeder.php
- Un seul fichier modifié par prompt (sauf demande explicite contraire)
- animate={} Framer Motion = toujours état VISIBLE (opacity: 1)
- Après chaque modification frontend : npm run build

Maintenant [votre demande ici]
```

La règle `.mdc` avec `alwaysApply: true` s’applique aussi sans ce texte ; le coller **renforce** le contexte au début d’une session.

## Exemple de demande ciblée

Au lieu de : « corrige les statistiques », utiliser :

```text
[collez le prompt ci-dessus]

Maintenant corrige uniquement src/pages/admin/Statistiques.jsx : sécuriser les .map() sur des données potentiellement undefined — ne modifier aucun autre fichier.
```

## Vérification rapide

```powershell
# Depuis la racine du repo
Get-ChildItem frontend\.agents\skills -Name
```

Vous devez voir au minimum `emil-design-eng`, `impeccable`, et des dossiers issus de `taste-skill`.
