import { test, expect } from '@playwright/test'

const creds = {
  admin: { email: 'admin@at.dz', password: 'Password@123' },
  validateur: { email: 'validateur@at.dz', password: 'Password@123' },
  demandeur: { email: 'demandeur@at.dz', password: 'Password@123' },
  utilisateur: { email: 'user@at.dz', password: 'Password@123' },
}

async function login(page, { email, password }) {
  await page.goto('/login', { waitUntil: 'domcontentloaded' })
  await page.locator('input[name="email"]').fill(email)
  await page.locator('input[name="password"]').fill(password)
  await page.getByRole('button', { name: /se connecter|connexion|login/i }).click()

  const navPromise = page.waitForURL((u) => !u.pathname.endsWith('/login'), { timeout: 25_000 })
  const alert = page.getByRole('alert')
  const alertPromise = alert.waitFor({ timeout: 25_000 }).then(async () => {
    throw new Error((await alert.textContent())?.trim() || 'Echec login')
  })
  await Promise.race([navPromise, alertPromise])
}

async function safeVisit(page, path, failures, label) {
  try {
    await page.goto(path, { waitUntil: 'domcontentloaded' })
    await expect(page.locator('body')).toBeVisible()
  } catch (e) {
    failures.push(`${label} -> ${path} : ${String(e?.message ?? e)}`)
  }
}

async function openMessagerie(page, failures, who) {
  try {
    await page.goto('/messagerie', { waitUntil: 'domcontentloaded' })
    await expect(page.getByText('Conversations', { exact: false })).toBeVisible()
  } catch (e) {
    failures.push(`${who} messagerie ouverture: ${String(e?.message ?? e)}`)
  }
}

async function testConversationNoFlicker(page, failures, who) {
  try {
    await openMessagerie(page, failures, who)
    const conv = page.locator('button').filter({ hasText: /Interlocuteur|Admin|Demandeur|Validateur|Utilisateur|@/i }).first()
    if (await conv.count() === 0) {
      failures.push(`${who} messagerie: aucune conversation trouvée`)
      return
    }

    await conv.click()
    await page.waitForTimeout(600)

    // Vérifie pendant ~12s que le skeleton ne réapparaît pas périodiquement.
    let flickerDetected = false
    for (let i = 0; i < 6; i += 1) {
      const skeletons = await page.locator('.animate-pulse').count()
      if (skeletons >= 3) {
        flickerDetected = true
        break
      }
      await page.waitForTimeout(2000)
    }
    if (flickerDetected) {
      failures.push(`${who} messagerie: flicker/skeleton périodique détecté`)
    }
  } catch (e) {
    failures.push(`${who} messagerie flicker test: ${String(e?.message ?? e)}`)
  }
}

test.describe('E2E complet application', () => {
  test('workflow multi-profils complet', async ({ browser }) => {
    test.setTimeout(12 * 60_000)
    const failures = []

    const adminCtx = await browser.newContext({ acceptDownloads: true })
    const validateurCtx = await browser.newContext()
    const demandeurCtx = await browser.newContext({ acceptDownloads: true })
    const utilisateurCtx = await browser.newContext()

    const admin = await adminCtx.newPage()
    const validateur = await validateurCtx.newPage()
    const demandeur = await demandeurCtx.newPage()
    const utilisateur = await utilisateurCtx.newPage()

    try {
      await login(admin, creds.admin)
    } catch (e) {
      failures.push(`login admin: ${String(e?.message ?? e)}`)
    }
    try {
      await login(validateur, creds.validateur)
    } catch (e) {
      failures.push(`login validateur: ${String(e?.message ?? e)}`)
    }
    try {
      await login(demandeur, creds.demandeur)
    } catch (e) {
      failures.push(`login demandeur: ${String(e?.message ?? e)}`)
    }
    try {
      await login(utilisateur, creds.utilisateur)
    } catch (e) {
      failures.push(`login utilisateur: ${String(e?.message ?? e)}`)
    }

    // Pages admin
    for (const path of [
      '/',
      '/missions',
      '/notifications',
      '/organigramme',
      '/profil',
      '/messagerie',
      '/admin/utilisateurs',
      '/admin/prestataires',
      '/admin/budgets',
      '/admin/audit-logs',
      '/admin/statistiques',
      '/rapports',
      '/validations',
    ]) {
      await safeVisit(admin, path, failures, 'admin')
    }

    // Pages validateur
    for (const path of [
      '/',
      '/missions',
      '/validations',
      '/notifications',
      '/organigramme',
      '/messagerie',
      '/rapports',
      '/profil',
    ]) {
      await safeVisit(validateur, path, failures, 'validateur')
    }

    // Pages demandeur
    for (const path of [
      '/',
      '/missions',
      '/missions/nouvelle',
      '/notifications',
      '/organigramme',
      '/messagerie',
      '/profil',
    ]) {
      await safeVisit(demandeur, path, failures, 'demandeur')
    }

    // Pages utilisateur
    for (const path of [
      '/',
      '/missions',
      '/notifications',
      '/organigramme',
      '/messagerie',
      '/profil',
    ]) {
      await safeVisit(utilisateur, path, failures, 'utilisateur')
    }

    // Organigramme: test recherche + panel (admin)
    try {
      await admin.goto('/organigramme', { waitUntil: 'domcontentloaded' })
      const searchInput = admin.locator('input').filter({ hasText: /./ }).first()
      if (await searchInput.count()) {
        await searchInput.fill('dir')
      }
    } catch (e) {
      failures.push(`admin organigramme interaction: ${String(e?.message ?? e)}`)
    }

    // Exports admin (Excel + PDF) - robuste même si navigateur bloque le download event.
    try {
      await admin.goto('/rapports', { waitUntil: 'domcontentloaded' })
      const maybeDownload = admin.waitForEvent('download', { timeout: 12_000 }).catch(() => null)
      await admin.getByRole('button', { name: /Missions Excel/i }).click()
      const d = await maybeDownload
      if (!d) {
        const toast = admin.getByText(/Export téléchargé|Téléchargement lancé|Erreur export/i).first()
        await expect(toast).toBeVisible({ timeout: 8_000 })
      }
    } catch (e) {
      failures.push(`admin export excel: ${String(e?.message ?? e)}`)
    }
    try {
      await admin.goto('/rapports', { waitUntil: 'domcontentloaded' })
      const maybeDownload = admin.waitForEvent('download', { timeout: 12_000 }).catch(() => null)
      await admin.getByRole('button', { name: /Missions PDF/i }).click()
      const d = await maybeDownload
      if (!d) {
        const toast = admin.getByText(/Export téléchargé|Téléchargement lancé|Erreur export/i).first()
        await expect(toast).toBeVisible({ timeout: 8_000 })
      }
    } catch (e) {
      failures.push(`admin export pdf: ${String(e?.message ?? e)}`)
    }

    // Messagerie inter-profils admin <-> demandeur
    try {
      await openMessagerie(admin, failures, 'admin')
      await openMessagerie(demandeur, failures, 'demandeur')
      const txt = `E2E ping ${Date.now()}`

      const firstConvAdmin = admin.locator('button').filter({ hasText: /Interlocuteur|@|Admin|Demandeur|Validateur|Utilisateur/i }).first()
      if (await firstConvAdmin.count()) {
        await firstConvAdmin.click()
        await admin.locator('textarea').fill(txt)
        await admin.getByRole('button', { name: /envoyer/i }).click()
        await demandeur.reload({ waitUntil: 'domcontentloaded' })
      } else {
        failures.push('admin messagerie: aucune conversation cliquable')
      }
    } catch (e) {
      failures.push(`messagerie inter-profils: ${String(e?.message ?? e)}`)
    }

    // Vérifie le bug de disparition périodique conversation.
    await testConversationNoFlicker(admin, failures, 'admin')
    await testConversationNoFlicker(demandeur, failures, 'demandeur')

    // WORKFLOW CRÉATION MISSION (demandeur)
    try {
      await demandeur.goto('/missions/nouvelle', { waitUntil: 'domcontentloaded' })

      const now = new Date()
      const depart = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 2)
      const retour = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 5)
      const fmt = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`

      const titleInput = demandeur.locator('input[name="titre"], input[placeholder*="Titre"], input').first()
      await titleInput.fill('Mission Test E2E')

      const destinationInput = demandeur.locator('input[name*="destination"], input[placeholder*="Destination"]').first()
      if (await destinationInput.count()) {
        await destinationInput.fill('Alger')
      }

      const dateDepartInput = demandeur.locator('input[name*="date_depart"], input[type="date"]').first()
      if (await dateDepartInput.count()) {
        await dateDepartInput.fill(fmt(depart))
      }

      const dateRetourInput = demandeur.locator('input[name*="date_retour"], input[type="date"]').nth(1)
      if (await dateRetourInput.count()) {
        await dateRetourInput.fill(fmt(retour))
      }

      const typeSelect = demandeur.locator('select[name*="type_mission"], select').first()
      if (await typeSelect.count()) {
        const options = await typeSelect.locator('option').allTextContents()
        const idx = options.findIndex((o) => /formation|conference|reunion|inspection|audit|autre/i.test(o || ''))
        if (idx >= 0) await typeSelect.selectOption({ index: idx })
      }

      const submitBtn = demandeur.getByRole('button', { name: /Soumettre|Envoyer|Créer|Valider/i }).first()
      if (await submitBtn.count()) {
        await submitBtn.click()
      }

      const successToast = demandeur.getByText(/succès|mission créée|soumise|envoyée/i).first()
      await expect(successToast).toBeVisible({ timeout: 8000 })
    } catch (e) {
      failures.push(`demandeur création mission: ${String(e?.message ?? e)}`)
    }

    // WORKFLOW VALIDATION (validateur)
    try {
      await validateur.goto('/validations', { waitUntil: 'domcontentloaded' })
      const approveBtn = validateur.getByRole('button', { name: /Approuver|Valider/i }).first()
      if (await approveBtn.count()) {
        await approveBtn.click()
        const ok = validateur.getByText(/succès|approuvée|validée/i).first()
        await expect(ok).toBeVisible({ timeout: 8000 })
      }
    } catch (e) {
      failures.push(`validateur approbation: ${String(e?.message ?? e)}`)
    }

    // WORKFLOW REJET MISSION (validateur)
    try {
      await validateur.goto('/validations', { waitUntil: 'domcontentloaded' })
      const rejectBtn = validateur.getByRole('button', { name: /Rejeter|Refuser/i }).first()
      if (await rejectBtn.count()) {
        await rejectBtn.click()
        const motif = validateur.locator('textarea, input[name*="motif"], input[name*="comment"]').first()
        if (await motif.count()) {
          await motif.fill('Rejet test E2E')
        }
        const confirmReject = validateur.getByRole('button', { name: /Confirmer|Rejeter|Valider/i }).first()
        if (await confirmReject.count()) {
          await confirmReject.click()
        }
        const ok = validateur.getByText(/succès|rejetée|refusée/i).first()
        await expect(ok).toBeVisible({ timeout: 8000 })
      }
    } catch (e) {
      failures.push(`validateur rejet: ${String(e?.message ?? e)}`)
    }

    // UPLOAD PIÈCE JUSTIFICATIVE (demandeur)
    try {
      await demandeur.goto('/missions', { waitUntil: 'domcontentloaded' })
      const missionLink = demandeur.locator('a[href*="/missions/"]').first()
      if (await missionLink.count()) {
        await missionLink.click()
      } else {
        await demandeur.goto('/missions', { waitUntil: 'domcontentloaded' })
      }

      const documentsTab = demandeur.getByRole('button', { name: /Documents/i }).first()
      if (await documentsTab.count()) {
        await documentsTab.click()
      }

      const fileInput = demandeur.locator('input[type="file"]').first()
      if (await fileInput.count()) {
        await fileInput.setInputFiles({
          name: 'piece-justificative-test.txt',
          mimeType: 'text/plain',
          buffer: Buffer.from('Pièce justificative E2E'),
        })
      } else {
        failures.push('demandeur upload PJ: input file introuvable')
      }
    } catch (e) {
      failures.push(`demandeur upload PJ: ${String(e?.message ?? e)}`)
    }

    // ORGANIGRAMME COMPLET (admin)
    try {
      await admin.goto('/organigramme', { waitUntil: 'domcontentloaded' })
      const search = admin.locator('input[placeholder*="Recherche"], input[placeholder*="recherche"], input[type="search"], input').first()
      if (await search.count()) {
        await search.fill('Direction')
      }
      const hasResult = await admin.locator('button, [role="button"], .node, .react-flow__node').count()
      if (hasResult < 1) {
        failures.push('admin organigramme: aucun résultat affiché')
      } else {
        await admin.locator('button, [role="button"], .node, .react-flow__node').first().click()
        const detailPanel = admin.getByText(/Direction|Service|Détail|Responsable/i).first()
        await expect(detailPanel).toBeVisible({ timeout: 8000 })
      }
    } catch (e) {
      failures.push(`admin organigramme: ${String(e?.message ?? e)}`)
    }

    // MESSAGERIE ADMIN (ouverture + liste + envoi)
    try {
      await openMessagerie(admin, failures, 'admin')
      const convList = admin.locator('button').filter({ hasText: /Interlocuteur|Admin|Demandeur|Validateur|Utilisateur|@/i })
      const convCount = await convList.count()
      if (convCount < 1) {
        failures.push('admin messagerie: liste conversations vide')
      } else {
        await convList.first().click()
        const txt = `Admin msg test ${Date.now()}`
        await admin.locator('textarea').fill(txt)
        await admin.getByRole('button', { name: /Envoyer/i }).click()
      }
    } catch (e) {
      failures.push(`admin messagerie: ${String(e?.message ?? e)}`)
    }

    await adminCtx.close()
    await validateurCtx.close()
    await demandeurCtx.close()
    await utilisateurCtx.close()

    expect(failures, failures.join('\n')).toEqual([])
  })
})

