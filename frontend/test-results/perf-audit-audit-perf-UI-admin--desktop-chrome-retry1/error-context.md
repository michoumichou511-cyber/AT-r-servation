# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: perf-audit.spec.js >> audit perf UI (admin)
- Location: tests\perf-audit.spec.js:85:1

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5175/login
Call log:
  - navigating to "http://127.0.0.1:5175/login", waiting until "domcontentloaded"

```

# Page snapshot

```yaml
- generic [ref=f1e3]:
  - generic [ref=f1e6]:
    - heading "Ce site est inaccessible" [level=1] [ref=f1e7]
    - paragraph [ref=f1e8]:
      - strong [ref=f1e9]: 127.0.0.1
      - text: n'autorise pas la connexion.
    - generic [ref=f1e10]:
      - paragraph [ref=f1e11]: "Voici quelques conseils :"
      - list [ref=f1e12]:
        - listitem [ref=f1e13]: Vérifier la connexion
        - listitem [ref=f1e14]:
          - link "Vérifier le proxy et le pare-feu" [ref=f1e15] [cursor=pointer]:
            - /url: "#buttons"
    - generic [ref=f1e16]: ERR_CONNECTION_REFUSED
  - generic [ref=f1e17]:
    - button "Actualiser" [ref=f1e19] [cursor=pointer]
    - button "Détails" [ref=f1e20] [cursor=pointer]
```

# Test source

```ts
  1   | import { test, expect } from '@playwright/test'
  2   | 
  3   | const BASE_URL = process.env.UI_BASE_URL ?? 'http://127.0.0.1:5175'
  4   | 
  5   | const creds = {
  6   |   admin: { email: 'admin@at.dz', password: 'Password@123' },
  7   | }
  8   | 
  9   | async function login(page, { email, password }) {
  10  |   await page.goto(`${BASE_URL}/login`, { waitUntil: 'domcontentloaded' })
  11  |   await page.locator('input[name="email"]').fill(email)
  12  |   await page.locator('input[name="password"]').fill(password)
  13  |   await page.getByRole('button', { name: /se connecter|connexion|login/i }).click()
  14  |   // attend soit redirection, soit alerte explicite
  15  |   const navPromise = page.waitForURL((u) => !u.pathname.endsWith('/login'), { timeout: 20_000 })
  16  |   const alert = page.getByRole('alert')
  17  |   const alertPromise = alert.waitFor({ timeout: 20_000 }).then(async () => {
  18  |     const txt = (await alert.textContent())?.trim() ?? ''
  19  |     throw new Error(`Login échoué: ${txt || 'alerte sans texte'}`)
  20  |   })
  21  |   await Promise.race([navPromise, alertPromise])
  22  | }
  23  | 
  24  | async function installLongTaskProbe(page) {
  25  |   await page.addInitScript(() => {
  26  |     window.__atPerf = { longTasks: [], raf: { frames: 0, jank: 0, worstGapMs: 0 } }
  27  | 
  28  |     // Long Tasks (si supporté)
  29  |     try {
  30  |       // eslint-disable-next-line no-undef
  31  |       const po = new PerformanceObserver((list) => {
  32  |         for (const e of list.getEntries()) {
  33  |           window.__atPerf.longTasks.push({
  34  |             name: e.name,
  35  |             startTime: e.startTime,
  36  |             duration: e.duration,
  37  |           })
  38  |         }
  39  |       })
  40  |       po.observe({ entryTypes: ['longtask'] })
  41  |     } catch {
  42  |       // ignore
  43  |     }
  44  | 
  45  |     // Heuristique jank via RAF: on compte les “gros trous” > 50ms
  46  |     let last = performance.now()
  47  |     function tick(now) {
  48  |       const gap = now - last
  49  |       window.__atPerf.raf.frames += 1
  50  |       if (gap > 50) {
  51  |         window.__atPerf.raf.jank += 1
  52  |         window.__atPerf.raf.worstGapMs = Math.max(window.__atPerf.raf.worstGapMs, gap)
  53  |       }
  54  |       last = now
  55  |       requestAnimationFrame(tick)
  56  |     }
  57  |     requestAnimationFrame(tick)
  58  |   })
  59  | }
  60  | 
  61  | async function getPagePerfSnapshot(page) {
  62  |   const nav = await page.evaluate(() => {
  63  |     const n = performance.getEntriesByType('navigation')?.[0]
  64  |     if (!n) return null
  65  |     return {
  66  |       domContentLoaded: n.domContentLoadedEventEnd,
  67  |       loadEventEnd: n.loadEventEnd,
  68  |       transferSize: n.transferSize,
  69  |       encodedBodySize: n.encodedBodySize,
  70  |       decodedBodySize: n.decodedBodySize,
  71  |     }
  72  |   })
  73  |   const probe = await page.evaluate(() => window.__atPerf ?? null)
  74  |   return { nav, probe }
  75  | }
  76  | 
  77  | async function auditRoute(page, path) {
> 78  |   await page.goto(`${BASE_URL}${path}`, { waitUntil: 'domcontentloaded' })
      |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5175/login
  79  |   // laisse tourner un peu pour capter longtasks + raf gaps
  80  |   await page.waitForTimeout(3000)
  81  |   const snap = await getPagePerfSnapshot(page)
  82  |   return { path, ...snap }
  83  | }
  84  | 
  85  | test('audit perf UI (admin)', async ({ page, context }) => {
  86  |   test.setTimeout(3 * 60_000)
  87  |   await installLongTaskProbe(page)
  88  | 
  89  |   await context.tracing.start({
  90  |     screenshots: true,
  91  |     snapshots: true,
  92  |     sources: false,
  93  |   })
  94  | 
  95  |   let loggedIn = false
  96  |   const results = []
  97  |   try {
  98  |     try {
  99  |       await login(page, creds.admin)
  100 |       loggedIn = true
  101 |     } catch (e) {
  102 |       // Si le backend/DB est KO, on continue l’audit sur les pages publiques/redirect.
  103 |       // eslint-disable-next-line no-console
  104 |       console.log(String(e?.message ?? e))
  105 |     }
  106 | 
  107 |     const routes = loggedIn
  108 |       ? [
  109 |           '/',
  110 |           '/missions',
  111 |           '/validations',
  112 |           '/messagerie',
  113 |           '/notifications',
  114 |           '/prestataires',
  115 |           '/admin/utilisateurs',
  116 |           '/admin/budgets',
  117 |           '/admin/audit-logs',
  118 |           '/admin/statistiques',
  119 |           '/rapports',
  120 |           '/profil',
  121 |         ]
  122 |       : [
  123 |           '/login',
  124 |           '/',
  125 |           '/missions',
  126 |           '/validations',
  127 |           '/admin/utilisateurs',
  128 |         ]
  129 | 
  130 |     for (const r of routes) results.push(await auditRoute(page, r))
  131 |   } finally {
  132 |     try {
  133 |       await context.tracing.stop({ path: 'test-results/perf-admin-trace.zip' })
  134 |     } catch {
  135 |       // ignore
  136 |     }
  137 |   }
  138 | 
  139 |   // Résumé imprimé dans la sortie test.
  140 |   const summary = results.map((x) => {
  141 |     const longTasks = x.probe?.longTasks?.length ?? 0
  142 |     const maxLong = Math.max(0, ...(x.probe?.longTasks?.map((t) => t.duration) ?? [0]))
  143 |     const jank = x.probe?.raf?.jank ?? null
  144 |     const worstGapMs = x.probe?.raf?.worstGapMs ?? null
  145 |     return {
  146 |       path: x.path,
  147 |       dcl_ms: x.nav?.domContentLoaded ?? null,
  148 |       load_ms: x.nav?.loadEventEnd ?? null,
  149 |       transfer_kb: x.nav?.transferSize != null ? Math.round(x.nav.transferSize / 1024) : null,
  150 |       longTasks,
  151 |       maxLong_ms: Math.round(maxLong),
  152 |       rafJankCount: jank,
  153 |       rafWorstGap_ms: worstGapMs != null ? Math.round(worstGapMs) : null,
  154 |     }
  155 |   })
  156 | 
  157 |   // eslint-disable-next-line no-console
  158 |   console.log(JSON.stringify({ baseUrl: BASE_URL, loggedIn, summary }, null, 2))
  159 | 
  160 |   // Test “passe” même si perf mauvaise: on ne veut pas masquer les mesures.
  161 |   expect(Array.isArray(summary)).toBeTruthy()
  162 | })
  163 | 
  164 | 
```