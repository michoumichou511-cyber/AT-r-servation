# Guide de soutenance — AT Réservations

## Démarrage en 1 clic

Double-clic sur `DEMARRER_SOUTENANCE.bat` à la racine du projet. Le script lance :

1. MySQL (XAMPP)
2. Laravel Backend (port 8000)
3. Frontend React Vite (port 5173)
4. Flutter Web (port 3000)
5. Tunnel ngrok (expose le backend sur Internet)

## URLs

### Démo en local (sans Internet — fallback)

| Composant | URL |
|-----------|-----|
| Frontend React | http://localhost:5173 |
| Backend Laravel | http://127.0.0.1:8000 |
| Mobile Web (Flutter) | http://localhost:3000 |
| Inspector ngrok | http://127.0.0.1:4040 |

### Démo en ligne (recommandée)

| Composant | URL |
|-----------|-----|
| **Frontend (Vercel)** | **https://at-reservations.vercel.app** |
| Backend (ngrok) | URL affichée dans la fenêtre ngrok ou Inspector |

## Comptes de démonstration (mot de passe : `Password@123`)

| Rôle | Email |
|------|-------|
| Administrateur | `admin@at.dz` |
| Validateur | `validateur@at.dz` |
| Demandeur | `demandeur@at.dz` |
| Agent DML | `agent.dml@at.dz` |

## Si l'URL ngrok change (redémarrage)

ngrok-free génère une nouvelle URL à chaque redémarrage. Pour la propager au frontend Vercel :

```powershell
# 1. Récupérer la nouvelle URL ngrok
$NgrokUrl = (Invoke-RestMethod -Uri "http://127.0.0.1:4040/api/tunnels").tunnels[0].public_url
Write-Host "Nouvelle URL ngrok : $NgrokUrl"

# 2. Mettre à jour le .env.production
"VITE_API_URL=$NgrokUrl/api" | Out-File -FilePath "C:\Users\loulou\ProjetFinFormation\frontend\.env.production" -Encoding ascii

# 3. Rebuild + redeploy Vercel
cd "C:\Users\loulou\ProjetFinFormation\frontend"
npm run build
npx vercel --prod --yes
```

Estimation : ~2 minutes pour le rebuild + redeploy.

## Architecture pour le jury

```
┌──────────────────────────┐         ┌──────────────────────────┐
│ Frontend React 18 + Vite │         │ Mobile Flutter           │
│ Vercel CDN (global)      │         │ at-reservations.apk      │
│ at-reservations.vercel.app│        │ localhost:3000 (web)     │
└────────────┬─────────────┘         └────────────┬─────────────┘
             │                                    │
             │  HTTPS + CORS                      │
             ▼                                    ▼
        ┌────────────────────────────────────────────┐
        │ ngrok tunnel (https://xxx.ngrok-free.dev)  │
        └────────────────────┬───────────────────────┘
                             │
                             ▼
        ┌────────────────────────────────────────────┐
        │ Laravel 12 + Sanctum (127.0.0.1:8000)      │
        │ - 60+ routes /api/*                        │
        │ - Roles : admin, validateur, demandeur, dml│
        └────────────────────┬───────────────────────┘
                             │
                             ▼
        ┌────────────────────────────────────────────┐
        │ MySQL 8 (XAMPP, port 3306)                 │
        │ - Users, Missions, Reservations,           │
        │   Validations, Documents, Notifications    │
        └────────────────────────────────────────────┘
```

## Scénarios de démo recommandés

### Scénario 1 — Demandeur crée et soumet une mission (5 min)

1. https://at-reservations.vercel.app/login
2. Cliquer "Demandeur" (autofill) + Se connecter
3. Dashboard : cartes KPI cliquables (29 demandes / 11 en attente / 9 rejetées)
4. "Nouvelle demande de mission"
5. Wizard 4 étapes :
   - Step 1 : Titre, ville départ/destination, dates, type
   - Step 2 : Réservation (filtre prestataire par type)
   - Step 3 : Documents (upload PJ)
   - Step 4 : Récapitulatif + Soumettre

### Scénario 2 — Validateur approuve (3 min)

1. Déconnexion → Login Validateur
2. /validations → liste des missions à valider
3. Cliquer "Approuver" → commentaire obligatoire (min 10 chars)
4. Vérifier statut changé

### Scénario 3 — Agent DML traite (3 min)

1. Déconnexion → Login Agent DML
2. /dml → KPIs corrects (À traiter / En cours / Terminées)
3. Cliquer mission → assigner hôtel + véhicule → "Logistique OK"
4. Toast "demandeur averti par email + notification"

### Scénario 4 — Admin gère (3 min)

1. Déconnexion → Login Admin
2. /admin/utilisateurs → 39 users, 7 rôles dans dropdown
3. Changer rôle d'un user → toast
4. /admin/statistiques → graphiques globaux
5. /admin/budgets → liste budgets + alertes

## Questions jury préparées

Voir `integration_test/jury_simulation_report.json` (section `questions_jury_preparees`).

## Documents annexes pour le mémoire

Dossier `captures_memoire/` :
- `figure13` à `figure19.png` : captures écran (login, dashboard 4 profils, etc.)
- `diagram1_architecture.png` : architecture 3-tiers
- `diagram2_workflow.png` : workflow validation
- `diagram3_erd.png` : base de données ERD
- `diagram4_roles.png` : matrice rôles/permissions

Organigramme Lucid (modifiable + exportable PNG HD) :
https://lucid.app/lucidchart/6f663a0f-9fe1-45db-bcfb-60eb9cb0216f/edit
