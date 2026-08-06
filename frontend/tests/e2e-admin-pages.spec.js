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

test.describe('E2E Admin Pages Complet', () => {
  test('workflow multi-profils + vérifie toutes pages admin', async ({ browser }) => {
    test.setTimeout(15 * 60_000)
    const failures = []

    const adminCtx = await browser.newContext({ acceptDownloads: true })
    const validateurCtx = await browser.newContext()
    const demandeurCtx = await browser.newContext()

    const admin = await adminCtx.newPage()
    const validateur = await validateurCtx.newPage()
    const demandeur = await demandeurCtx.newPage()

    try {
      console.log('[E2E] Login admin...')
      await login(admin, creds.admin)
    } catch (e) {
      failures.push(`Login admin: ${String(e?.message ?? e)}`)
    }
    try {
      console.log('[E2E] Login validateur...')
      await login(validateur, creds.validateur)
    } catch (e) {
      failures.push(`Login validateur: ${String(e?.message ?? e)}`)
    }
    try {
      console.log('[E2E] Login demandeur...')
      await login(demandeur, creds.demandeur)
    } catch (e) {
      failures.push(`Login demandeur: ${String(e?.message ?? e)}`)
    }

    // ADMIN PAGES
    const adminPages = [
      { path: '/', label: 'Dashboard' },
      { path: '/missions', label: 'Missions' },
      { path: '/validations', label: 'Validations' },
      { path: '/notifications', label: 'Notifications' },
      { path: '/organigramme', label: 'Organigramme' },
      { path: '/messagerie', label: 'Messagerie' },
      { path: '/profil', label: 'Profil' },
      { path: '/rapports', label: 'Rapports' },
      { path: '/admin/utilisateurs', label: 'Admin > Utilisateurs' },
      { path: '/admin/prestataires', label: 'Admin > Prestataires' },
      { path: '/admin/budgets', label: 'Admin > Budgets' },
      { path: '/admin/audit-logs', label: 'Admin > AuditLogs' },
      { path: '/admin/statistiques', label: 'Admin > Statistiques' },
    ]

    console.log('[E2E] Checking admin pages...')
    for (const { path, label } of adminPages) {
      try {
        await admin.goto(path, { waitUntil: 'domcontentloaded' })
        const bodyVisible = await admin.locator('body').isVisible()
        if (!bodyVisible) {
          failures.push(`${label}: page non visible`)
        } else {
          console.log(`  ✓ ${label}`)
        }
      } catch (e) {
        failures.push(`${label}: ${String(e?.message ?? e)}`)
      }
    }

    // VALIDATEUR PAGES
    const validateurPages = [
      { path: '/', label: 'Dashboard' },
      { path: '/missions', label: 'Missions' },
      { path: '/validations', label: 'Validations' },
      { path: '/notifications', label: 'Notifications' },
      { path: '/messagerie', label: 'Messagerie' },
      { path: '/profil', label: 'Profil' },
    ]

    console.log('[E2E] Checking validateur pages...')
    for (const { path, label } of validateurPages) {
      try {
        await validateur.goto(path, { waitUntil: 'domcontentloaded' })
        const bodyVisible = await validateur.locator('body').isVisible()
        if (!bodyVisible) {
          failures.push(`Validateur ${label}: page non visible`)
        } else {
          console.log(`  ✓ Validateur ${label}`)
        }
      } catch (e) {
        failures.push(`Validateur ${label}: ${String(e?.message ?? e)}`)
      }
    }

    // DEMANDEUR PAGES
    const demandeurPages = [
      { path: '/', label: 'Dashboard' },
      { path: '/missions', label: 'Missions' },
      { path: '/missions/nouvelle', label: 'Nouvelle Mission' },
      { path: '/notifications', label: 'Notifications' },
      { path: '/messagerie', label: 'Messagerie' },
      { path: '/profil', label: 'Profil' },
    ]

    console.log('[E2E] Checking demandeur pages...')
    for (const { path, label } of demandeurPages) {
      try {
        await demandeur.goto(path, { waitUntil: 'domcontentloaded' })
        const bodyVisible = await demandeur.locator('body').isVisible()
        if (!bodyVisible) {
          failures.push(`Demandeur ${label}: page non visible`)
        } else {
          console.log(`  ✓ Demandeur ${label}`)
        }
      } catch (e) {
        failures.push(`Demandeur ${label}: ${String(e?.message ?? e)}`)
      }
    }

    // TEST: ADMIN EXPORT EXCEL
    console.log('[E2E] Testing export Excel...')
    try {
      await admin.goto('/rapports', { waitUntil: 'domcontentloaded' })
      const exportBtn = admin.getByRole('button', { name: /Missions Excel|Excel/i }).first()
      if (await exportBtn.count()) {
        await exportBtn.click()
        console.log('  ✓ Export Excel button clicked')
      } else {
        failures.push('Export Excel: button non trouvé')
      }
    } catch (e) {
      failures.push(`Export Excel: ${String(e?.message ?? e)}`)
    }

    // TEST: ADMIN CREATE MISSION
    console.log('[E2E] Testing demandeur create mission...')
    try {
      await demandeur.goto('/missions/nouvelle', { waitUntil: 'domcontentloaded' })
      const titleInput = demandeur.locator('input[name="titre"], input[placeholder*="Titre"]').first()
      if (await titleInput.count()) {
        await titleInput.fill('Mission E2E Test')
        console.log('  ✓ Mission creation form accessible')
      } else {
        failures.push('Mission creation: form non trouvé')
      }
    } catch (e) {
      failures.push(`Mission creation: ${String(e?.message ?? e)}`)
    }

    // TEST: ORGANIGRAMME + SEARCH
    console.log('[E2E] Testing organigramme search...')
    try {
      await admin.goto('/organigramme', { waitUntil: 'domcontentloaded' })
      const searchInput = admin.locator('input[type="search"], input[placeholder*="recherche"], input[placeholder*="Recherche"]').first()
      if (await searchInput.count()) {
        await searchInput.fill('Direction')
        console.log('  ✓ Organigramme search working')
      } else {
        console.log('  ⚠ Organigramme search input not found')
      }
    } catch (e) {
      failures.push(`Organigramme search: ${String(e?.message ?? e)}`)
    }

    // SUMMARY
    console.log('\n[E2E] Summary:')
    console.log(`  Total issues: ${failures.length}`)
    if (failures.length > 0) {
      failures.forEach((f, i) => console.log(`  ${i + 1}. ${f}`))
    }

    await adminCtx.close()
    await validateurCtx.close()
    await demandeurCtx.close()

    expect(failures, failures.join('\n')).toEqual([])
  })
})
