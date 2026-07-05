# Claude Code Configuration — AT Réservations

## Skills actifs — chargés automatiquement

Ces règles s'appliquent à **TOUTES les sessions** sans exception :

- `.claude/skills/security.md` — Bonnes pratiques sécurité Laravel/React
- `.claude/skills/frontend-design.md` — Règles design AT Réservations
- `.claude/skills/create-skill.md` — Comment créer un nouveau skill
- `.claude/skills/know-me.md` — Contexte projet AT Réservations
- `.claude/skills/self-improving-agent.md` — Règles d'amélioration itérative
- `.claude/skills/word-docx.md` — Génération documents Word
- `.claude/skills/humanizer.md` — Règles rédaction française
- `.claude/skills/mcp-chrome.md` — Testing avec Chrome MCP DevTools
- `.claude/skills/testing-at.md` — Checklist test avant livraison

## Règles absolues

### 1. Un prompt = un seul fichier modifié
- **JAMAIS** modifier 2+ fichiers dans une même étape
- Si besoin d'autres fichiers → découper en étapes successives
- Demander confirmation entre chaque étape

### 2. Build obligatoire après modification frontend
```bash
npm run build
```
- À faire systématiquement
- Avant tout commit
- Vérifier l'absence d'erreurs

### 3. Jamais toucher ATUsersSeeder.php
- Données de test fixes
- Structure des utilisateurs immuable
- Utiliser pour les identifiants de test uniquement

### 4. Jamais toucher les animations Framer Motion existantes
- FloatingBubbles.jsx — animations canvas
- ParticleBackground.jsx — réseau de particules
- DashboardRoleViews.jsx — transitions Framer Motion
- **DÉFENSE** : JAMAIS supprimer ou modifier sans demander

### 5. Diagnostiquer avant de modifier (mode lecture d'abord)
1. Lire le fichier (mode lecture seule)
2. Identifier le problème précis
3. Proposer la solution
4. Attendre confirmation
5. Modifier

### 6. DB_HOST=127.0.0.1 toujours (jamais localhost)
```
.env :
DB_HOST=127.0.0.1
```
- XAMPP localhost ne fonctionne pas
- Toujours utiliser 127.0.0.1
- Vérifier après chaque modification `.env.example`

## Ports & URLs de développement
```
Frontend  : http://127.0.0.1:5173
Backend   : http://127.0.0.1:8000
Database  : 127.0.0.1:3306
```

## Stack Technique
- **Frontend** : React 18 + Vite + Tailwind CSS
- **Backend** : Laravel 12 + Sanctum
- **Database** : MySQL via XAMPP
- **IDE** : VS Code + Claude Code extension

## Identifiants test
```
Admin     : admin@at.dz / Password@123
Validateur: nadia.khelifi@at.dz / Password@123
Demandeur : demandeur@at.dz / Password@123
```

## Commandes utiles
```bash
# Frontend
npm run dev      # Démarrer Vite
npm run build    # Build production
npm run preview  # Preview build

# Backend
php artisan serve --port=8000  # Démarrer Laravel
php artisan migrate            # Lancer migrations
php artisan tinker             # CLI interactif

# Database
# Accès XAMPP MySQL : 127.0.0.1:3306 (root/aucun pwd)
```

## Avant chaque commit
```bash
git status          # Vérifier fichiers stagés
git diff            # Vérifier qu'aucun .env en staged
git log --oneline   # Vérifier commit messages
```

---

**Version actuelle** : 2.0 (mai 2026)  
**Mise à jour** : Ajout skills + règles d'amélioration
