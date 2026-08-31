# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: ui-smoke.spec.js >> UI smoke >> admin: parcours principal
- Location: tests\ui-smoke.spec.js:57:5

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5175/login
Call log:
  - navigating to "http://127.0.0.1:5175/login", waiting until "domcontentloaded"

```

# Page snapshot

```yaml
- generic [ref=e3]:
  - generic [ref=e6]:
    - heading "Ce site est inaccessible" [level=1] [ref=e7]
    - paragraph [ref=e8]:
      - strong [ref=e9]: 127.0.0.1
      - text: n'autorise pas la connexion.
    - generic [ref=e10]:
      - paragraph [ref=e11]: "Voici quelques conseils :"
      - list [ref=e12]:
        - listitem [ref=e13]: Vérifier la connexion
        - listitem [ref=e14]:
          - link "Vérifier le proxy et le pare-feu" [ref=e15] [cursor=pointer]:
            - /url: "#buttons"
    - generic [ref=e16]: ERR_CONNECTION_REFUSED
  - generic [ref=e17]:
    - button "Actualiser" [ref=e19] [cursor=pointer]
    - button "Détails" [ref=e20] [cursor=pointer]
```

# Test source

```ts
  1   | import { test, expect } from '@playwright/test'
  2   | 
  3   | const BASE_URL = process.env.UI_BASE_URL ?? 'http://127.0.0.1:5175'
  4   | const API_BASE = process.env.API_BASE_URL ?? 'http://127.0.0.1:8000/api'
  5   | 
  6   | const creds = {
  7   |   admin: { email: 'admin@at.dz', password: 'Password@123' },
  8   |   validateur: { email: 'validateur@at.dz', password: 'Password@123' },
  9   |   demandeur: { email: 'demandeur@at.dz', password: 'Password@123' },
  10  |   utilisateur: { email: 'user@at.dz', password: 'Password@123' },
  11  | }
  12  | 
  13  | function isApi(url) {
  14  |   return typeof url === 'string' && url.startsWith(API_BASE)
  15  | }
  16  | 
  17  | function shouldIgnoreFailure(status, url) {
  18  |   // Ignorer les 401/403 attendus selon les rôles (l'app peut afficher /403).
  19  |   if (!isApi(url)) return false
  20  |   if (status === 401) return true
  21  |   if (status === 403) return true
  22  |   return false
  23  | }
  24  | 
  25  | async function login(page, { email, password }) {
> 26  |   await page.goto(`${BASE_URL}/login`, { waitUntil: 'domcontentloaded' })
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5175/login
  27  |   await expect(page).toHaveURL(/\/login/)
  28  | 
  29  |   // Les labels sont en "sr-only" et contiennent "e-mail" (avec tiret),
  30  |   // donc on cible les attributs name stables.
  31  |   await page.locator('input[name="email"]').fill(email)
  32  |   await page.locator('input[name="password"]').fill(password)
  33  | 
  34  |   // Le bouton peut être "Se connecter" / "Connexion" selon UI.
  35  |   const submit = page.getByRole('button', { name: /se connecter|connexion|login/i })
  36  |   await submit.click()
  37  | 
  38  |   // Après login, soit on quitte /login, soit l'écran affiche une erreur (role="alert").
  39  |   // On préfère une erreur explicite plutôt qu'un timeout “muet”.
  40  |   const navPromise = page.waitForURL((u) => !u.pathname.endsWith('/login'), { timeout: 20_000 })
  41  |   const alert = page.getByRole('alert')
  42  |   const alertPromise = alert.waitFor({ timeout: 20_000 }).then(async () => {
  43  |     const txt = (await alert.textContent())?.trim() ?? ''
  44  |     throw new Error(`Login échoué: ${txt || 'alerte sans texte'}`)
  45  |   })
  46  |   await Promise.race([navPromise, alertPromise])
  47  | }
  48  | 
  49  | async function visit(page, path) {
  50  |   await page.goto(`${BASE_URL}${path}`, { waitUntil: 'domcontentloaded' })
  51  |   // Petites attentes pour laisser les appels API finir.
  52  |   await page.waitForTimeout(700)
  53  | }
  54  | 
  55  | test.describe('UI smoke', () => {
  56  |   for (const [role, cred] of Object.entries(creds)) {
  57  |     test(`${role}: parcours principal`, async ({ page }) => {
  58  |       const failures = []
  59  |       page.on('response', (resp) => {
  60  |         const url = resp.url()
  61  |         const status = resp.status()
  62  |         if (isApi(url) && status >= 400 && !shouldIgnoreFailure(status, url)) {
  63  |           failures.push({ status, url })
  64  |         }
  65  |       })
  66  | 
  67  |       page.on('pageerror', (err) => {
  68  |         failures.push({ status: 'JS', url: String(err?.message ?? err) })
  69  |       })
  70  | 
  71  |       await login(page, cred)
  72  | 
  73  |       // Pages communes
  74  |       await visit(page, '/')
  75  |       await visit(page, '/missions')
  76  |       await visit(page, '/profil')
  77  |       await visit(page, '/notifications')
  78  |       await visit(page, '/messagerie')
  79  |       await visit(page, '/prestataires')
  80  | 
  81  |       // Validations: réservé à validateur/admin (sinon /403 ou erreurs 403 attendues)
  82  |       await visit(page, '/validations')
  83  | 
  84  |       // Admin (devrait être KO hors admin)
  85  |       await visit(page, '/admin/utilisateurs')
  86  |       await visit(page, '/admin/budgets')
  87  |       await visit(page, '/admin/audit-logs')
  88  |       await visit(page, '/admin/prestataires')
  89  |       await visit(page, '/admin/statistiques')
  90  | 
  91  |       // Rapports (admin/validateur)
  92  |       await visit(page, '/rapports')
  93  | 
  94  |       // Signalement final
  95  |       // Déduplique pour lisibilité.
  96  |       const uniq = new Map()
  97  |       for (const f of failures) {
  98  |         const key = `${f.status} ${f.url}`
  99  |         if (!uniq.has(key)) uniq.set(key, f)
  100 |       }
  101 |       const list = [...uniq.values()]
  102 | 
  103 |       // On attend 0 échec API 4xx/5xx inattendu pour ce rôle.
  104 |       // Les pages Admin pour non-admin risquent d'appeler des endpoints admin -> 403 (ignorés) mais l'écran doit gérer proprement.
  105 |       expect(list, JSON.stringify(list, null, 2)).toEqual([])
  106 |     })
  107 |   }
  108 | })
  109 | 
  110 | 
```