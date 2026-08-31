# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: seed-data.spec.js >> Seed de données réalistes (UI + API limitée) >> crée budgets + 10 missions + messages
- Location: tests\seed-data.spec.js:136:3

# Error details

```
Error: API login failed [401]: {"success":false,"message":"Identifiants invalides."}
```

# Test source

```ts
  1   | import { test, expect, request as playwrightRequest } from '@playwright/test'
  2   | 
  3   | const creds = {
  4   |   admin: { email: 'admin@at.dz', password: 'Password@123' },
  5   |   validateur: { email: 'validateur@at.dz', password: 'Password@123' },
  6   |   demandeur: { email: 'demandeur@at.dz', password: 'Password@123' },
  7   |   utilisateur: { email: 'user@at.dz', password: 'Password@123' },
  8   | }
  9   | 
  10  | async function apiLogin(credsFor) {
  11  |   const api = await playwrightRequest.newContext({ baseURL: 'http://127.0.0.1:8000' })
  12  |   const res = await api.post('/api/auth/login', { data: credsFor })
  13  |   if (!res.ok()) {
  14  |     const txt = await res.text()
> 15  |     throw new Error(`API login failed [${res.status()}]: ${txt.slice(0, 200)}`)
      |           ^ Error: API login failed [401]: {"success":false,"message":"Identifiants invalides."}
  16  |   }
  17  |   const body = await res.json()
  18  |   const token = body?.data?.token
  19  |   await api.dispose()
  20  |   if (!token) throw new Error(`Token introuvable pour ${credsFor?.email}`)
  21  |   return token
  22  | }
  23  | 
  24  | async function authPageWithToken(page, credsFor) {
  25  |   const token = await apiLogin(credsFor)
  26  |   await page.addInitScript((t) => {
  27  |     window.localStorage.setItem('at_token', t)
  28  |   }, token)
  29  |   await page.goto('/', { waitUntil: 'domcontentloaded' })
  30  |   return token
  31  | }
  32  | 
  33  | async function apiLoginToken() {
  34  |   // Attendre avant de faire la requête (throttle rate limit)
  35  |   await new Promise(resolve => setTimeout(resolve, 15000))
  36  |   return apiLogin(creds.admin)
  37  | }
  38  | 
  39  | async function createBudgetsViaApi(token) {
  40  |   const api = await playwrightRequest.newContext({
  41  |     baseURL: 'http://127.0.0.1:8000',
  42  |     extraHTTPHeaders: { Authorization: `Bearer ${token}` },
  43  |   })
  44  |   const year = new Date().getFullYear()
  45  |   const payloads = [
  46  |     { direction: 'DG', service: 'Direction Générale', annee: year, montant_alloue: 3_000_000 },
  47  |     { direction: 'Technique', service: 'DSI', annee: year, montant_alloue: 5_000_000 },
  48  |     { direction: 'Ressources Humaines', service: 'Formation', annee: year, montant_alloue: 2_000_000 },
  49  |   ]
  50  |   for (const p of payloads) {
  51  |     const r = await api.post('/api/admin/budgets', { data: p })
  52  |     if (!r.ok()) {
  53  |       const txt = await r.text()
  54  |       throw new Error(`Création budget API failed: ${r.status()} ${txt.slice(0, 200)}`)
  55  |     }
  56  |   }
  57  |   await api.dispose()
  58  | }
  59  | 
  60  | function futureDateISO(daysFromNow) {
  61  |   const d = new Date()
  62  |   d.setDate(d.getDate() + daysFromNow)
  63  |   const yyyy = d.getFullYear()
  64  |   const mm = String(d.getMonth() + 1).padStart(2, '0')
  65  |   const dd = String(d.getDate()).padStart(2, '0')
  66  |   return `${yyyy}-${mm}-${dd}`
  67  | }
  68  | 
  69  | async function createPrestataireViaApi(token) {
  70  |   const api = await playwrightRequest.newContext({
  71  |     baseURL: 'http://127.0.0.1:8000',
  72  |     extraHTTPHeaders: { Authorization: `Bearer ${token}` },
  73  |   })
  74  |   const prestataires = [
  75  |     { nom: 'Hotel Test Alpha', ville: 'Alger', type: 'hotel' },
  76  |     { nom: 'Restaurant Test Beta', ville: 'Oran', type: 'restaurant' },
  77  |     { nom: 'Compagnie Air Test', ville: 'Alger', type: 'compagnie_aerienne' },
  78  |   ]
  79  |   for (const p of prestataires) {
  80  |     const r = await api.post('/api/admin/prestataires', { data: p })
  81  |     if (!r.ok()) {
  82  |       const txt = await r.text()
  83  |       throw new Error(`Création prestataire API failed: ${r.status()} ${txt.slice(0, 200)}`)
  84  |     }
  85  |   }
  86  |   await api.dispose()
  87  | }
  88  | 
  89  | async function createMissionUI(page, { titre, objet, ville, pays, typeMission = 'formation', priorite = 'normale', budget = 150000 }) {
  90  |   await page.goto('/missions/nouvelle', { waitUntil: 'domcontentloaded' })
  91  | 
  92  |   await page.getByLabel('Titre').fill(titre)
  93  |   await page.getByLabel(/Objet de la mission/i).fill(objet)
  94  |   await page.getByLabel(/Ville de destination/i).fill(ville)
  95  |   await page.getByLabel(/Pays de destination/i).fill(pays)
  96  | 
  97  |   // Date inputs (2 inputs[type=date] présents à l'étape 1)
  98  |   const dates = page.locator('input[type="date"]')
  99  |   await dates.nth(0).fill(futureDateISO(3))
  100 |   await dates.nth(1).fill(futureDateISO(6))
  101 | 
  102 |   // selects (type mission + priorité)
  103 |   const selects = page.locator('select')
  104 |   await selects.nth(0).selectOption(typeMission)
  105 |   if (await selects.count() > 1) {
  106 |     await selects.nth(1).selectOption(priorite)
  107 |   }
  108 | 
  109 |   await page.getByLabel(/Budget prévisionnel/i).fill(String(budget))
  110 | 
  111 |   await page.getByRole('button', { name: /Suivant/i }).click()
  112 | 
  113 |   // Étape 2: ajouter une réservation minimale
  114 |   // Montant estimé + bouton Ajouter (icône + / Ajouter / Enregistrer)
  115 |   const montant = page.getByLabel(/Montant/i).first()
```