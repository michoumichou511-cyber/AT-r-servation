/* eslint-disable no-console */

async function apiLogin(base, { email, password }) {
  const r = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  })
  const j = await r.json().catch(() => ({}))
  const token = j?.data?.token
  if (!token) {
    throw new Error(`Login failed for ${email}: ${r.status} ${JSON.stringify(j).slice(0, 200)}`)
  }
  return token
}

async function authedFetch(base, token, path, { method = 'GET', body } = {}) {
  const r = await fetch(`${base}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  })
  const txt = await r.text()
  let j = null
  try { j = JSON.parse(txt) } catch { /* ignore */ }
  return { r, txt, j }
}

function futureISO(daysFromNow) {
  const d = new Date()
  d.setDate(d.getDate() + daysFromNow)
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
}

async function createPrestataire(base, adminToken, payload) {
  const { r, txt, j } = await authedFetch(base, adminToken, '/admin/prestataires', { method: 'POST', body: payload })
  if (!r.ok) throw new Error(`createPrestataire ${r.status}: ${txt.slice(0, 300)}`)
  return j
}

async function createBudget(base, adminToken, payload) {
  const { r, txt, j } = await authedFetch(base, adminToken, '/admin/budgets', { method: 'POST', body: payload })
  if (!r.ok) throw new Error(`createBudget ${r.status}: ${txt.slice(0, 300)}`)
  return j
}

async function createMission(base, token, missionPayload) {
  const { r, txt, j } = await authedFetch(base, token, '/missions', { method: 'POST', body: missionPayload })
  if (!r.ok) throw new Error(`createMission ${r.status}: ${txt.slice(0, 300)}`)
  const data = j?.data ?? j
  const id = data?.id ?? data?.mission?.id
  if (!id) throw new Error(`Mission id missing: ${txt.slice(0, 200)}`)
  return id
}

async function addReservation(base, token, missionId, payload) {
  const { r, txt } = await authedFetch(base, token, `/missions/${missionId}/reservations`, { method: 'POST', body: payload })
  if (!r.ok) throw new Error(`addReservation ${r.status}: ${txt.slice(0, 300)}`)
}

async function submitMission(base, token, missionId) {
  const { r, txt } = await authedFetch(base, token, `/missions/${missionId}/submit`, { method: 'POST' })
  if (!r.ok) throw new Error(`submitMission ${r.status}: ${txt.slice(0, 300)}`)
}

async function main() {
  const base = process.env.API_BASE_URL ?? 'http://127.0.0.1:8000/api'
  const year = new Date().getFullYear()
  const creds = {
    admin: { email: 'admin@at.dz', password: 'Password@123' },
    demandeur: { email: 'demandeur@at.dz', password: 'Password@123' },
    utilisateur: { email: 'user@at.dz', password: 'Password@123' },
  }

  console.log('[seed] login tokens...')
  const adminToken = await apiLogin(base, creds.admin)
  const demandeurToken = await apiLogin(base, creds.demandeur)
  const userToken = await apiLogin(base, creds.utilisateur)

  console.log('[seed] create budgets...')
  await createBudget(base, adminToken, { direction: 'DG', service: 'Direction Générale', annee: year, montant_alloue: 3_000_000 })
  await createBudget(base, adminToken, { direction: 'Technique', service: 'DSI', annee: year, montant_alloue: 5_000_000 })
  await createBudget(base, adminToken, { direction: 'Ressources Humaines', service: 'Formation', annee: year, montant_alloue: 2_000_000 })

  console.log('[seed] create prestataires...')
  // NB: Schéma backend prestataires.type = enum(['compagnie_aerienne','hotel','catering','agence_voyage'])
  // et pas forcément de colonne `ville` selon migrations.
  await createPrestataire(base, adminToken, { nom: 'Hotel Test Alpha', type: 'hotel', is_active: true })
  await createPrestataire(base, adminToken, { nom: 'Catering Test Beta', type: 'catering', is_active: true })
  await createPrestataire(base, adminToken, { nom: 'Compagnie Air Test', type: 'compagnie_aerienne', is_active: true })

  const missionsToCreate = 20
  console.log(`[seed] create ${missionsToCreate} missions + reservations + submit...`)
  for (let i = 1; i <= missionsToCreate; i += 1) {
    const token = i <= 10 ? demandeurToken : userToken
    const type_mission = i % 3 === 0 ? 'conference' : i % 2 === 0 ? 'reunion' : 'formation'
    const priorite = i % 5 === 0 ? 'urgente' : 'normale'
    const payload = {
      titre: `Mission seed #${i}`,
      objet_mission: `Objet mission seed #${i}`,
      destination_ville: i % 2 === 0 ? 'Alger' : 'Oran',
      destination_pays: 'Algérie',
      date_depart: futureISO(3),
      date_retour: futureISO(6),
      type_mission,
      priorite,
      budget_previsionnel: 120000 + i * 5000,
      description: 'Mission de test générée automatiquement pour alimenter stats/rapports.',
    }

    const id = await createMission(base, token, payload)
    await addReservation(base, token, id, { type: 'billet', montant_estime: 15000, notes: 'Seed auto' })
    await submitMission(base, token, id)
    if (i % 5 === 0) console.log(`[seed] missions: ${i}/${missionsToCreate}`)
  }

  console.log('[seed] validate admin stats + exports...')
  const stats = await authedFetch(base, adminToken, '/admin/statistiques')
  console.log('admin/statistiques', stats.r.status)
  const exp = await authedFetch(base, adminToken, '/export/prestataires/excel')
  console.log('export/prestataires/excel', exp.r.status)

  console.log('[seed] done')
}

main().catch((e) => {
  console.error('[seed] FAILED', e)
  process.exit(1)
})

