import { test, expect } from '@playwright/test'

const BASE_URL = process.env.UI_BASE_URL ?? 'http://127.0.0.1:5175'
const API_BASE = process.env.API_BASE_URL ?? 'http://127.0.0.1:8000/api'

const creds = {
  admin: { email: 'admin@at.dz', password: 'Password@123' },
  validateur: { email: 'validateur@at.dz', password: 'Password@123' },
  demandeur: { email: 'demandeur@at.dz', password: 'Password@123' },
  utilisateur: { email: 'user@at.dz', password: 'Password@123' },
}

function isApi(url) {
  return typeof url === 'string' && url.startsWith(API_BASE)
}

function shouldIgnoreFailure(status, url) {
  // Ignorer les 401/403 attendus selon les rôles (l'app peut afficher /403).
  if (!isApi(url)) return false
  if (status === 401) return true
  if (status === 403) return true
  return false
}

async function login(page, { email, password }) {
  await page.goto(`${BASE_URL}/login`, { waitUntil: 'domcontentloaded' })
  await expect(page).toHaveURL(/\/login/)

  // Les labels sont en "sr-only" et contiennent "e-mail" (avec tiret),
  // donc on cible les attributs name stables.
  await page.locator('input[name="email"]').fill(email)
  await page.locator('input[name="password"]').fill(password)

  // Le bouton peut être "Se connecter" / "Connexion" selon UI.
  const submit = page.getByRole('button', { name: /se connecter|connexion|login/i })
  await submit.click()

  // Après login, soit on quitte /login, soit l'écran affiche une erreur (role="alert").
  // On préfère une erreur explicite plutôt qu'un timeout “muet”.
  const navPromise = page.waitForURL((u) => !u.pathname.endsWith('/login'), { timeout: 20_000 })
  const alert = page.getByRole('alert')
  const alertPromise = alert.waitFor({ timeout: 20_000 }).then(async () => {
    const txt = (await alert.textContent())?.trim() ?? ''
    throw new Error(`Login échoué: ${txt || 'alerte sans texte'}`)
  })
  await Promise.race([navPromise, alertPromise])
}

async function visit(page, path) {
  await page.goto(`${BASE_URL}${path}`, { waitUntil: 'domcontentloaded' })
  // Petites attentes pour laisser les appels API finir.
  await page.waitForTimeout(700)
}

test.describe('UI smoke', () => {
  for (const [role, cred] of Object.entries(creds)) {
    test(`${role}: parcours principal`, async ({ page }) => {
      const failures = []
      page.on('response', (resp) => {
        const url = resp.url()
        const status = resp.status()
        if (isApi(url) && status >= 400 && !shouldIgnoreFailure(status, url)) {
          failures.push({ status, url })
        }
      })

      page.on('pageerror', (err) => {
        failures.push({ status: 'JS', url: String(err?.message ?? err) })
      })

      await login(page, cred)

      // Pages communes
      await visit(page, '/')
      await visit(page, '/missions')
      await visit(page, '/profil')
      await visit(page, '/notifications')
      await visit(page, '/messagerie')
      await visit(page, '/prestataires')

      // Validations: réservé à validateur/admin (sinon /403 ou erreurs 403 attendues)
      await visit(page, '/validations')

      // Admin (devrait être KO hors admin)
      await visit(page, '/admin/utilisateurs')
      await visit(page, '/admin/budgets')
      await visit(page, '/admin/audit-logs')
      await visit(page, '/admin/prestataires')
      await visit(page, '/admin/statistiques')

      // Rapports (admin/validateur)
      await visit(page, '/rapports')

      // Signalement final
      // Déduplique pour lisibilité.
      const uniq = new Map()
      for (const f of failures) {
        const key = `${f.status} ${f.url}`
        if (!uniq.has(key)) uniq.set(key, f)
      }
      const list = [...uniq.values()]

      // On attend 0 échec API 4xx/5xx inattendu pour ce rôle.
      // Les pages Admin pour non-admin risquent d'appeler des endpoints admin -> 403 (ignorés) mais l'écran doit gérer proprement.
      expect(list, JSON.stringify(list, null, 2)).toEqual([])
    })
  }
})

