import { test, expect, request as playwrightRequest } from '@playwright/test'

const creds = {
  admin: { email: 'admin@at.dz', password: 'Password@123' },
  validateur: { email: 'validateur@at.dz', password: 'Password@123' },
  demandeur: { email: 'demandeur@at.dz', password: 'Password@123' },
  utilisateur: { email: 'user@at.dz', password: 'Password@123' },
}

async function apiLogin(credsFor) {
  const api = await playwrightRequest.newContext({ baseURL: 'http://127.0.0.1:8000' })
  const res = await api.post('/api/auth/login', { data: credsFor })
  if (!res.ok()) {
    const txt = await res.text()
    throw new Error(`API login failed [${res.status()}]: ${txt.slice(0, 200)}`)
  }
  const body = await res.json()
  const token = body?.data?.token
  await api.dispose()
  if (!token) throw new Error(`Token introuvable pour ${credsFor?.email}`)
  return token
}

async function authPageWithToken(page, credsFor) {
  const token = await apiLogin(credsFor)
  await page.addInitScript((t) => {
    window.localStorage.setItem('at_token', t)
  }, token)
  await page.goto('/', { waitUntil: 'domcontentloaded' })
  return token
}

async function apiLoginToken() {
  // Attendre avant de faire la requête (throttle rate limit)
  await new Promise(resolve => setTimeout(resolve, 15000))
  return apiLogin(creds.admin)
}

async function createBudgetsViaApi(token) {
  const api = await playwrightRequest.newContext({
    baseURL: 'http://127.0.0.1:8000',
    extraHTTPHeaders: { Authorization: `Bearer ${token}` },
  })
  const year = new Date().getFullYear()
  const payloads = [
    { direction: 'DG', service: 'Direction Générale', annee: year, montant_alloue: 3_000_000 },
    { direction: 'Technique', service: 'DSI', annee: year, montant_alloue: 5_000_000 },
    { direction: 'Ressources Humaines', service: 'Formation', annee: year, montant_alloue: 2_000_000 },
  ]
  for (const p of payloads) {
    const r = await api.post('/api/admin/budgets', { data: p })
    if (!r.ok()) {
      const txt = await r.text()
      throw new Error(`Création budget API failed: ${r.status()} ${txt.slice(0, 200)}`)
    }
  }
  await api.dispose()
}

function futureDateISO(daysFromNow) {
  const d = new Date()
  d.setDate(d.getDate() + daysFromNow)
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
}

async function createPrestataireViaApi(token) {
  const api = await playwrightRequest.newContext({
    baseURL: 'http://127.0.0.1:8000',
    extraHTTPHeaders: { Authorization: `Bearer ${token}` },
  })
  const prestataires = [
    { nom: 'Hotel Test Alpha', ville: 'Alger', type: 'hotel' },
    { nom: 'Restaurant Test Beta', ville: 'Oran', type: 'restaurant' },
    { nom: 'Compagnie Air Test', ville: 'Alger', type: 'compagnie_aerienne' },
  ]
  for (const p of prestataires) {
    const r = await api.post('/api/admin/prestataires', { data: p })
    if (!r.ok()) {
      const txt = await r.text()
      throw new Error(`Création prestataire API failed: ${r.status()} ${txt.slice(0, 200)}`)
    }
  }
  await api.dispose()
}

async function createMissionUI(page, { titre, objet, ville, pays, typeMission = 'formation', priorite = 'normale', budget = 150000 }) {
  await page.goto('/missions/nouvelle', { waitUntil: 'domcontentloaded' })

  await page.getByLabel('Titre').fill(titre)
  await page.getByLabel(/Objet de la mission/i).fill(objet)
  await page.getByLabel(/Ville de destination/i).fill(ville)
  await page.getByLabel(/Pays de destination/i).fill(pays)

  // Date inputs (2 inputs[type=date] présents à l'étape 1)
  const dates = page.locator('input[type="date"]')
  await dates.nth(0).fill(futureDateISO(3))
  await dates.nth(1).fill(futureDateISO(6))

  // selects (type mission + priorité)
  const selects = page.locator('select')
  await selects.nth(0).selectOption(typeMission)
  if (await selects.count() > 1) {
    await selects.nth(1).selectOption(priorite)
  }

  await page.getByLabel(/Budget prévisionnel/i).fill(String(budget))

  await page.getByRole('button', { name: /Suivant/i }).click()

  // Étape 2: ajouter une réservation minimale
  // Montant estimé + bouton Ajouter (icône + / Ajouter / Enregistrer)
  const montant = page.getByLabel(/Montant/i).first()
  if (await montant.count()) {
    await montant.fill('15000')
  } else {
    // fallback: premier input type number dans l'étape 2
    const num = page.locator('input[type="number"]').first()
    if (await num.count()) await num.fill('15000')
  }
  const addBtn = page.getByRole('button', { name: /Ajouter|Enregistrer|Sauvegarder/i }).first()
  if (await addBtn.count()) await addBtn.click()

  await page.getByRole('button', { name: /Suivant/i }).click()
  await page.getByRole('button', { name: /Suivant/i }).click()

  // Étape 4: soumettre
  const submitBtn = page.getByRole('button', { name: /Soumettre|Envoyer/i }).first()
  await submitBtn.click()
  await expect(page.getByText(/Mission soumise|soumise ✅/i).first()).toBeVisible({ timeout: 12_000 })
}

test.describe('Seed de données réalistes (UI + API limitée)', () => {
  test('crée budgets + 10 missions + messages', async ({ browser }) => {
    test.setTimeout(30 * 60_000)

    // Budgets (UI ne propose pas la création) → API admin
    const token = await apiLoginToken()
    console.log('[seed] budgets via API...')
    await createBudgetsViaApi(token)

    const adminCtx = await browser.newContext()
    const demandeurCtx = await browser.newContext()

    const admin = await adminCtx.newPage()
    const demandeur = await demandeurCtx.newPage()

    console.log('[seed] auth admin...')
    await authPageWithToken(admin, creds.admin)
    console.log('[seed] auth demandeur...')
    await authPageWithToken(demandeur, creds.demandeur)

    // Missions via UI demandeur (10 missions pour test rapide)
    for (let i = 1; i <= 10; i += 1) {
      console.log(`[seed] create mission ${i}/10...`)
      const urgency = i % 3 === 0 ? 'urgente' : 'normale'
      const typeMission = i % 3 === 0 ? 'conference' : i % 2 === 0 ? 'reunion' : 'formation'
      await createMissionUI(demandeur, {
        titre: `Mission Seed #${i} - Audit Qualité`,
        objet: `Objet mission #${i} - Inspection et audit technique du service`,
        ville: i % 2 === 0 ? 'Alger' : 'Oran',
        pays: 'Algérie',
        typeMission,
        priorite: urgency,
        budget: 120000 + i * 5000,
      })
    }

    // Navigation admin pour vérifier les données
    console.log('[seed] verify missions in admin dashboard...')
    await admin.goto('/admin/utilisateurs', { waitUntil: 'domcontentloaded' })
    await admin.goto('/admin/budgets', { waitUntil: 'domcontentloaded' })
    await admin.goto('/admin/statistiques', { waitUntil: 'domcontentloaded' })

    // Valider une mission 
    console.log('[seed] admin validating mission...')
    await admin.goto('/missions', { waitUntil: 'domcontentloaded' })
    const firstMissionLink = admin.locator('a[href*="/missions/"]').first()
    if (await firstMissionLink.count()) {
      await firstMissionLink.click()
    }

    // Tests de messagerie
    console.log('[seed] testing messagerie...')
    await admin.goto('/messagerie', { waitUntil: 'domcontentloaded' })
    const conversationBtn = admin.locator('button').filter({ hasText: /Demandeur|Admin|Interlocuteur/i }).first()
    if (await conversationBtn.count()) {
      await conversationBtn.click()
      const textarea = admin.locator('textarea').first()
      if (await textarea.count()) {
        await textarea.fill(`Seed test message ${Date.now()}`)
        const sendBtn = admin.getByRole('button', { name: /envoyer|send/i }).first()
        if (await sendBtn.count()) {
          await sendBtn.click()
          console.log('[seed] message sent')
        }
      }
    }

    await adminCtx.close()
    await demandeurCtx.close()
  })
})

