# AT Réservations — Design System
> Inspiré de awesome-design-md (VoltAgent), adapté à la charte officielle Algérie Télécom.
> À placer à la racine de `ProjetFinFormation/frontend/` ou dans `docs/DESIGN.md`.

---

## 1. Brand Identity

| Token | Valeur |
|---|---|
| Nom produit | AT Réservations |
| Entreprise | Algérie Télécom |
| Slogan interne | *Gestion intelligente des missions* |
| Persona | Employé AT, validateur hiérarchique, administrateur DSI |

---

## 2. Colors

### Primary palette
```css
:root {
  --at-green:       #00A650;  /* vert AT — CTA principal, succès */
  --at-green-dark:  #007A3B;  /* hover, active */
  --at-green-light: #E6F9EE;  /* backgrounds success, badges */

  --at-blue:        #003DA5;  /* bleu AT — liens, info, header */
  --at-blue-dark:   #002A75;  /* hover */
  --at-blue-light:  #E6EEFF;  /* backgrounds info */

  --at-white:       #FFFFFF;
  --at-gray-50:     #F8FAFB;
  --at-gray-100:    #F1F4F7;
  --at-gray-200:    #E2E8EF;
  --at-gray-400:    #9AAAB8;
  --at-gray-600:    #5A6B7B;
  --at-gray-800:    #1E2D3D;
  --at-gray-900:    #0F1923;
}
```

### Dark mode
```css
[data-theme="dark"] {
  --bg-primary:   #0F1923;
  --bg-secondary: #1A2636;
  --bg-card:      #1E2D3D;
  --text-primary: #EFF4FA;
  --text-muted:   #9AAAB8;
  --border:       #2A3D54;
}
```

### Semantic colors
```css
:root {
  --color-success:  #00A650;
  --color-warning:  #F59E0B;
  --color-danger:   #EF4444;
  --color-info:     #003DA5;
  --color-pending:  #8B5CF6;
}
```

---

## 3. Typography

```css
/* Fonts : IBM Plex Sans (entreprise, lisible) + DM Sans (UI moderne) */
@import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600;700&family=DM+Sans:wght@400;500;700&family=IBM+Plex+Mono&display=swap');

:root {
  --font-display: 'IBM Plex Sans', sans-serif;  /* titres, headers */
  --font-body:    'DM Sans', sans-serif;         /* corps, UI */
  --font-mono:    'IBM Plex Mono', monospace;    /* codes, IDs */

  /* Scale */
  --text-xs:   0.75rem;   /* 12px — labels, captions */
  --text-sm:   0.875rem;  /* 14px — secondary text */
  --text-base: 1rem;      /* 16px — body */
  --text-lg:   1.125rem;  /* 18px — card titles */
  --text-xl:   1.25rem;   /* 20px — section headers */
  --text-2xl:  1.5rem;    /* 24px — page titles */
  --text-3xl:  1.875rem;  /* 30px — dashboard KPIs */
  --text-4xl:  2.25rem;   /* 36px — hero numbers */

  /* Weight */
  --font-normal:   400;
  --font-medium:   500;
  --font-semibold: 600;
  --font-bold:     700;
}
```

---

## 4. Spacing & Layout

```css
:root {
  /* Spacing scale (base 4px) */
  --space-1:  0.25rem;   /* 4px */
  --space-2:  0.5rem;    /* 8px */
  --space-3:  0.75rem;   /* 12px */
  --space-4:  1rem;      /* 16px */
  --space-5:  1.25rem;   /* 20px */
  --space-6:  1.5rem;    /* 24px */
  --space-8:  2rem;      /* 32px */
  --space-10: 2.5rem;    /* 40px */
  --space-12: 3rem;      /* 48px */
  --space-16: 4rem;      /* 64px */

  /* Border radius */
  --radius-sm:  4px;
  --radius-md:  8px;
  --radius-lg:  12px;
  --radius-xl:  16px;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm:  0 1px 3px rgba(0,0,0,0.08);
  --shadow-md:  0 4px 12px rgba(0,61,165,0.10);
  --shadow-lg:  0 8px 24px rgba(0,61,165,0.14);
  --shadow-glow-green: 0 0 20px rgba(0,166,80,0.25);
  --shadow-glow-blue:  0 0 20px rgba(0,61,165,0.25);
}
```

---

## 5. Component Design Patterns

### Cards
- Fond `var(--bg-card)`, border `1px solid var(--border)`
- Border-radius `var(--radius-lg)` (12px)
- Padding `var(--space-6)` (24px)
- Hover: `translateY(-2px)` + `var(--shadow-md)` — transition 200ms ease

### Buttons
```css
/* Primary */
.btn-primary {
  background: var(--at-green);
  color: white;
  border-radius: var(--radius-md);
  padding: var(--space-3) var(--space-6);
  font-weight: var(--font-semibold);
  transition: background 150ms, transform 100ms, box-shadow 150ms;
}
.btn-primary:hover {
  background: var(--at-green-dark);
  box-shadow: var(--shadow-glow-green);
  transform: translateY(-1px);
}

/* Secondary */
.btn-secondary {
  background: transparent;
  border: 1.5px solid var(--at-blue);
  color: var(--at-blue);
  border-radius: var(--radius-md);
}
.btn-secondary:hover { background: var(--at-blue-light); }
```

### Badges / Status
```
En attente   → bg: #EDE9FE, text: #7C3AED
Validé       → bg: var(--at-green-light), text: var(--at-green)
Refusé       → bg: #FEE2E2, text: #DC2626
En cours     → bg: #DBEAFE, text: #1D4ED8
Annulé       → bg: #F3F4F6, text: #6B7280
```

### Table rows
- Hover: `background: var(--at-gray-50)` (light) / `var(--bg-secondary)` (dark)
- Selected: border-left `3px solid var(--at-green)`
- Row height: 52px minimum

### Sidebar / Navigation
- Width: 240px (collapsed: 64px)
- Active item: fond `var(--at-green-light)`, texte `var(--at-green)`, border-left `3px solid var(--at-green)`
- Transitions: Framer Motion `staggerChildren` 0.05s sur les items

---

## 6. Motion & Animation

> **Principe :** Les animations doivent servir la navigation, pas décorer.

```js
// Framer Motion — variants standard AT Réservations
export const pageVariants = {
  initial: { opacity: 0, y: 12 },
  animate: { opacity: 1, y: 0, transition: { duration: 0.3, ease: 'easeOut' } },
  exit:    { opacity: 0, y: -8, transition: { duration: 0.2 } }
};

export const cardStagger = {
  animate: { transition: { staggerChildren: 0.07 } }
};

export const cardItem = {
  initial: { opacity: 0, y: 16, scale: 0.98 },
  animate: { opacity: 1, y: 0,  scale: 1, transition: { duration: 0.25 } }
};

// CountUp KPIs — toujours utiliser react-countup avec duration=1.5
```

**Règles :**
- Ne jamais mettre `animate={{ opacity: 0 }}` comme état final (cause disparition)
- Toujours vérifier que `animate` = état visible, `initial` = état caché
- Polling: messages 60s, notifications 30s — ne pas descendre

---

## 7. Icons

- Bibliothèque : **Lucide React** (déjà installé)
- Taille standard : 18px (sidebar), 20px (boutons), 24px (titres de section)
- Stroke-width : 1.75 (plus élégant que le défaut 2)
- Couleur : hériter du parent (`currentColor`)

---

## 8. Forms & Inputs

```css
.input {
  border: 1.5px solid var(--at-gray-200);
  border-radius: var(--radius-md);
  padding: var(--space-3) var(--space-4);
  font-family: var(--font-body);
  transition: border-color 150ms, box-shadow 150ms;
}
.input:focus {
  outline: none;
  border-color: var(--at-blue);
  box-shadow: 0 0 0 3px var(--at-blue-light);
}
```
- Labels toujours au-dessus du champ (pas placeholder-only)
- Erreurs : texte rouge `#EF4444`, icône `AlertCircle` Lucide

---

## 9. Dashboard Layout

```
┌─────────────────────────────────────────────┐
│  SIDEBAR 240px   │  MAIN CONTENT            │
│  Logo AT         │  Header (breadcrumb+user) │
│  Nav items       │  ─────────────────────── │
│  [active: green] │  KPI Cards (4 colonnes)  │
│                  │  ─────────────────────── │
│                  │  Charts / Tables          │
└─────────────────────────────────────────────┘
```

KPI Cards (4 obligatoires pour soutenance) :
1. **Missions cette semaine** — icône `Briefcase`
2. **En attente de validation** — icône `Clock`, badge violet
3. **Top destinations** — icône `MapPin`
4. **Alerte budget** — icône `AlertTriangle`, rouge si dépassé

---

## 10. DO / DON'T

| ✅ DO | ❌ DON'T |
|---|---|
| IBM Plex Sans pour les titres | Utiliser Arial, Roboto, Inter seul |
| `#00A650` et `#003DA5` comme accents | Ajouter des couleurs hors charte |
| Framer Motion avec `opacity: 1` en état final | `animate={{ opacity: 0 }}` |
| Un seul fichier par composant modifié (Cursor) | Prompts multi-fichiers dans Cursor |
| `127.0.0.1` pour DB_HOST dans .env | `localhost` (XAMPP MySQL bug) |
| `.env` dans `.gitignore` | Committer `.env` avec les credentials |
| Conserver `ATUsersSeeder` intact | Modifier le seeder des 37 employés AT |
