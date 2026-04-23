import { test, expect } from '@playwright/test'

const BASE_URL = process.env.UI_BASE_URL ?? 'http://127.0.0.1:5175'

const creds = {
  admin: { email: 'admin@at.dz', password: 'Password@123' },
}

async function login(page, { email, password }) {
  await page.goto(`${BASE_URL}/login`, { waitUntil: 'domcontentloaded' })
  await page.locator('input[name="email"]').fill(email)
  await page.locator('input[name="password"]').fill(password)
  await page.getByRole('button', { name: /se connecter|connexion|login/i }).click()
  // attend soit redirection, soit alerte explicite
  const navPromise = page.waitForURL((u) => !u.pathname.endsWith('/login'), { timeout: 20_000 })
  const alert = page.getByRole('alert')
  const alertPromise = alert.waitFor({ timeout: 20_000 }).then(async () => {
    const txt = (await alert.textContent())?.trim() ?? ''
    throw new Error(`Login échoué: ${txt || 'alerte sans texte'}`)
  })
  await Promise.race([navPromise, alertPromise])
}

async function installLongTaskProbe(page) {
  await page.addInitScript(() => {
    window.__atPerf = { longTasks: [], raf: { frames: 0, jank: 0, worstGapMs: 0 } }

    // Long Tasks (si supporté)
    try {
      // eslint-disable-next-line no-undef
      const po = new PerformanceObserver((list) => {
        for (const e of list.getEntries()) {
          window.__atPerf.longTasks.push({
            name: e.name,
            startTime: e.startTime,
            duration: e.duration,
          })
        }
      })
      po.observe({ entryTypes: ['longtask'] })
    } catch {
      // ignore
    }

    // Heuristique jank via RAF: on compte les “gros trous” > 50ms
    let last = performance.now()
    function tick(now) {
      const gap = now - last
      window.__atPerf.raf.frames += 1
      if (gap > 50) {
        window.__atPerf.raf.jank += 1
        window.__atPerf.raf.worstGapMs = Math.max(window.__atPerf.raf.worstGapMs, gap)
      }
      last = now
      requestAnimationFrame(tick)
    }
    requestAnimationFrame(tick)
  })
}

async function getPagePerfSnapshot(page) {
  const nav = await page.evaluate(() => {
    const n = performance.getEntriesByType('navigation')?.[0]
    if (!n) return null
    return {
      domContentLoaded: n.domContentLoadedEventEnd,
      loadEventEnd: n.loadEventEnd,
      transferSize: n.transferSize,
      encodedBodySize: n.encodedBodySize,
      decodedBodySize: n.decodedBodySize,
    }
  })
  const probe = await page.evaluate(() => window.__atPerf ?? null)
  return { nav, probe }
}

async function auditRoute(page, path) {
  await page.goto(`${BASE_URL}${path}`, { waitUntil: 'domcontentloaded' })
  // laisse tourner un peu pour capter longtasks + raf gaps
  await page.waitForTimeout(3000)
  const snap = await getPagePerfSnapshot(page)
  return { path, ...snap }
}

test('audit perf UI (admin)', async ({ page, context }) => {
  test.setTimeout(3 * 60_000)
  await installLongTaskProbe(page)

  await context.tracing.start({
    screenshots: true,
    snapshots: true,
    sources: false,
  })

  let loggedIn = false
  const results = []
  try {
    try {
      await login(page, creds.admin)
      loggedIn = true
    } catch (e) {
      // Si le backend/DB est KO, on continue l’audit sur les pages publiques/redirect.
      // eslint-disable-next-line no-console
      console.log(String(e?.message ?? e))
    }

    const routes = loggedIn
      ? [
          '/',
          '/missions',
          '/validations',
          '/messagerie',
          '/notifications',
          '/prestataires',
          '/admin/utilisateurs',
          '/admin/budgets',
          '/admin/audit-logs',
          '/admin/statistiques',
          '/rapports',
          '/profil',
        ]
      : [
          '/login',
          '/',
          '/missions',
          '/validations',
          '/admin/utilisateurs',
        ]

    for (const r of routes) results.push(await auditRoute(page, r))
  } finally {
    try {
      await context.tracing.stop({ path: 'test-results/perf-admin-trace.zip' })
    } catch {
      // ignore
    }
  }

  // Résumé imprimé dans la sortie test.
  const summary = results.map((x) => {
    const longTasks = x.probe?.longTasks?.length ?? 0
    const maxLong = Math.max(0, ...(x.probe?.longTasks?.map((t) => t.duration) ?? [0]))
    const jank = x.probe?.raf?.jank ?? null
    const worstGapMs = x.probe?.raf?.worstGapMs ?? null
    return {
      path: x.path,
      dcl_ms: x.nav?.domContentLoaded ?? null,
      load_ms: x.nav?.loadEventEnd ?? null,
      transfer_kb: x.nav?.transferSize != null ? Math.round(x.nav.transferSize / 1024) : null,
      longTasks,
      maxLong_ms: Math.round(maxLong),
      rafJankCount: jank,
      rafWorstGap_ms: worstGapMs != null ? Math.round(worstGapMs) : null,
    }
  })

  // eslint-disable-next-line no-console
  console.log(JSON.stringify({ baseUrl: BASE_URL, loggedIn, summary }, null, 2))

  // Test “passe” même si perf mauvaise: on ne veut pas masquer les mesures.
  expect(Array.isArray(summary)).toBeTruthy()
})

