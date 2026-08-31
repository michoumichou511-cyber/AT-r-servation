# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: e2e-admin-pages.spec.js >> E2E Admin Pages Complet >> workflow multi-profils + vérifie toutes pages admin
- Location: tests\e2e-admin-pages.spec.js:25:3

# Error details

```
Error: Login admin: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
Call log:
  - navigating to "http://127.0.0.1:5173/login", waiting until "domcontentloaded"

Login validateur: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
Call log:
  - navigating to "http://127.0.0.1:5173/login", waiting until "domcontentloaded"

Login demandeur: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
Call log:
  - navigating to "http://127.0.0.1:5173/login", waiting until "domcontentloaded"

Dashboard: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
Call log:
  - navigating to "http://127.0.0.1:5173/", waiting until "domcontentloaded"

Missions: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
Call log:
  - navigating to "http://127.0.0.1:5173/missions", waiting until "domcontentloaded"

Validations: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
Call log:
  - navigating to "http://127.0.0.1:5173/validations", waiting until "domcontentloaded"

Notifications: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
Call log:
  - navigating to "http://127.0.0.1:5173/notifications", waiting until "domcontentloaded"

Organigramme: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
Call log:
  - navigating to "http://127.0.0.1:5173/organigramme", waiting until "domcontentloaded"

Messagerie: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

Profil: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
Call log:
  - navigating to "http://127.0.0.1:5173/profil", waiting until "domcontentloaded"

Rapports: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
Call log:
  - navigating to "http://127.0.0.1:5173/rapports", waiting until "domcontentloaded"

Admin > Utilisateurs: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/utilisateurs
Call log:
  - navigating to "http://127.0.0.1:5173/admin/utilisateurs", waiting until "domcontentloaded"

Admin > Prestataires: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/prestataires
Call log:
  - navigating to "http://127.0.0.1:5173/admin/prestataires", waiting until "domcontentloaded"

Admin > Budgets: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/budgets
Call log:
  - navigating to "http://127.0.0.1:5173/admin/budgets", waiting until "domcontentloaded"

Admin > AuditLogs: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/audit-logs
Call log:
  - navigating to "http://127.0.0.1:5173/admin/audit-logs", waiting until "domcontentloaded"

Admin > Statistiques: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/statistiques
Call log:
  - navigating to "http://127.0.0.1:5173/admin/statistiques", waiting until "domcontentloaded"

Validateur Dashboard: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
Call log:
  - navigating to "http://127.0.0.1:5173/", waiting until "domcontentloaded"

Validateur Missions: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
Call log:
  - navigating to "http://127.0.0.1:5173/missions", waiting until "domcontentloaded"

Validateur Validations: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
Call log:
  - navigating to "http://127.0.0.1:5173/validations", waiting until "domcontentloaded"

Validateur Notifications: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
Call log:
  - navigating to "http://127.0.0.1:5173/notifications", waiting until "domcontentloaded"

Validateur Messagerie: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

Validateur Profil: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
Call log:
  - navigating to "http://127.0.0.1:5173/profil", waiting until "domcontentloaded"

Demandeur Dashboard: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
Call log:
  - navigating to "http://127.0.0.1:5173/", waiting until "domcontentloaded"

Demandeur Missions: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
Call log:
  - navigating to "http://127.0.0.1:5173/missions", waiting until "domcontentloaded"

Demandeur Nouvelle Mission: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions/nouvelle
Call log:
  - navigating to "http://127.0.0.1:5173/missions/nouvelle", waiting until "domcontentloaded"

Demandeur Notifications: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
Call log:
  - navigating to "http://127.0.0.1:5173/notifications", waiting until "domcontentloaded"

Demandeur Messagerie: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

Demandeur Profil: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
Call log:
  - navigating to "http://127.0.0.1:5173/profil", waiting until "domcontentloaded"

Export Excel: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
Call log:
  - navigating to "http://127.0.0.1:5173/rapports", waiting until "domcontentloaded"

Mission creation: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions/nouvelle
Call log:
  - navigating to "http://127.0.0.1:5173/missions/nouvelle", waiting until "domcontentloaded"

Organigramme search: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
Call log:
  - navigating to "http://127.0.0.1:5173/organigramme", waiting until "domcontentloaded"


expect(received).toEqual(expected) // deep equality

- Expected  -   1
+ Received  + 126

- Array []
+ Array [
+   "Login admin: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/login\", waiting until \"domcontentloaded\"
+ ",
+   "Login validateur: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/login\", waiting until \"domcontentloaded\"
+ ",
+   "Login demandeur: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/login\", waiting until \"domcontentloaded\"
+ ",
+   "Dashboard: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/\", waiting until \"domcontentloaded\"
+ ",
+   "Missions: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions\", waiting until \"domcontentloaded\"
+ ",
+   "Validations: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/validations\", waiting until \"domcontentloaded\"
+ ",
+   "Notifications: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/notifications\", waiting until \"domcontentloaded\"
+ ",
+   "Organigramme: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/organigramme\", waiting until \"domcontentloaded\"
+ ",
+   "Messagerie: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "Profil: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/profil\", waiting until \"domcontentloaded\"
+ ",
+   "Rapports: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/rapports\", waiting until \"domcontentloaded\"
+ ",
+   "Admin > Utilisateurs: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/utilisateurs
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/admin/utilisateurs\", waiting until \"domcontentloaded\"
+ ",
+   "Admin > Prestataires: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/prestataires
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/admin/prestataires\", waiting until \"domcontentloaded\"
+ ",
+   "Admin > Budgets: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/budgets
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/admin/budgets\", waiting until \"domcontentloaded\"
+ ",
+   "Admin > AuditLogs: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/audit-logs
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/admin/audit-logs\", waiting until \"domcontentloaded\"
+ ",
+   "Admin > Statistiques: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/statistiques
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/admin/statistiques\", waiting until \"domcontentloaded\"
+ ",
+   "Validateur Dashboard: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/\", waiting until \"domcontentloaded\"
+ ",
+   "Validateur Missions: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions\", waiting until \"domcontentloaded\"
+ ",
+   "Validateur Validations: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/validations\", waiting until \"domcontentloaded\"
+ ",
+   "Validateur Notifications: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/notifications\", waiting until \"domcontentloaded\"
+ ",
+   "Validateur Messagerie: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "Validateur Profil: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/profil\", waiting until \"domcontentloaded\"
+ ",
+   "Demandeur Dashboard: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/\", waiting until \"domcontentloaded\"
+ ",
+   "Demandeur Missions: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions\", waiting until \"domcontentloaded\"
+ ",
+   "Demandeur Nouvelle Mission: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions/nouvelle
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions/nouvelle\", waiting until \"domcontentloaded\"
+ ",
+   "Demandeur Notifications: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/notifications\", waiting until \"domcontentloaded\"
+ ",
+   "Demandeur Messagerie: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "Demandeur Profil: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/profil\", waiting until \"domcontentloaded\"
+ ",
+   "Export Excel: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/rapports\", waiting until \"domcontentloaded\"
+ ",
+   "Mission creation: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions/nouvelle
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions/nouvelle\", waiting until \"domcontentloaded\"
+ ",
+   "Organigramme search: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/organigramme\", waiting until \"domcontentloaded\"
+ ",
+ ]
```

# Test source

```ts
  94  |       { path: '/messagerie', label: 'Messagerie' },
  95  |       { path: '/profil', label: 'Profil' },
  96  |     ]
  97  | 
  98  |     console.log('[E2E] Checking validateur pages...')
  99  |     for (const { path, label } of validateurPages) {
  100 |       try {
  101 |         await validateur.goto(path, { waitUntil: 'domcontentloaded' })
  102 |         const bodyVisible = await validateur.locator('body').isVisible()
  103 |         if (!bodyVisible) {
  104 |           failures.push(`Validateur ${label}: page non visible`)
  105 |         } else {
  106 |           console.log(`  ✓ Validateur ${label}`)
  107 |         }
  108 |       } catch (e) {
  109 |         failures.push(`Validateur ${label}: ${String(e?.message ?? e)}`)
  110 |       }
  111 |     }
  112 | 
  113 |     // DEMANDEUR PAGES
  114 |     const demandeurPages = [
  115 |       { path: '/', label: 'Dashboard' },
  116 |       { path: '/missions', label: 'Missions' },
  117 |       { path: '/missions/nouvelle', label: 'Nouvelle Mission' },
  118 |       { path: '/notifications', label: 'Notifications' },
  119 |       { path: '/messagerie', label: 'Messagerie' },
  120 |       { path: '/profil', label: 'Profil' },
  121 |     ]
  122 | 
  123 |     console.log('[E2E] Checking demandeur pages...')
  124 |     for (const { path, label } of demandeurPages) {
  125 |       try {
  126 |         await demandeur.goto(path, { waitUntil: 'domcontentloaded' })
  127 |         const bodyVisible = await demandeur.locator('body').isVisible()
  128 |         if (!bodyVisible) {
  129 |           failures.push(`Demandeur ${label}: page non visible`)
  130 |         } else {
  131 |           console.log(`  ✓ Demandeur ${label}`)
  132 |         }
  133 |       } catch (e) {
  134 |         failures.push(`Demandeur ${label}: ${String(e?.message ?? e)}`)
  135 |       }
  136 |     }
  137 | 
  138 |     // TEST: ADMIN EXPORT EXCEL
  139 |     console.log('[E2E] Testing export Excel...')
  140 |     try {
  141 |       await admin.goto('/rapports', { waitUntil: 'domcontentloaded' })
  142 |       const exportBtn = admin.getByRole('button', { name: /Missions Excel|Excel/i }).first()
  143 |       if (await exportBtn.count()) {
  144 |         await exportBtn.click()
  145 |         console.log('  ✓ Export Excel button clicked')
  146 |       } else {
  147 |         failures.push('Export Excel: button non trouvé')
  148 |       }
  149 |     } catch (e) {
  150 |       failures.push(`Export Excel: ${String(e?.message ?? e)}`)
  151 |     }
  152 | 
  153 |     // TEST: ADMIN CREATE MISSION
  154 |     console.log('[E2E] Testing demandeur create mission...')
  155 |     try {
  156 |       await demandeur.goto('/missions/nouvelle', { waitUntil: 'domcontentloaded' })
  157 |       const titleInput = demandeur.locator('input[name="titre"], input[placeholder*="Titre"]').first()
  158 |       if (await titleInput.count()) {
  159 |         await titleInput.fill('Mission E2E Test')
  160 |         console.log('  ✓ Mission creation form accessible')
  161 |       } else {
  162 |         failures.push('Mission creation: form non trouvé')
  163 |       }
  164 |     } catch (e) {
  165 |       failures.push(`Mission creation: ${String(e?.message ?? e)}`)
  166 |     }
  167 | 
  168 |     // TEST: ORGANIGRAMME + SEARCH
  169 |     console.log('[E2E] Testing organigramme search...')
  170 |     try {
  171 |       await admin.goto('/organigramme', { waitUntil: 'domcontentloaded' })
  172 |       const searchInput = admin.locator('input[type="search"], input[placeholder*="recherche"], input[placeholder*="Recherche"]').first()
  173 |       if (await searchInput.count()) {
  174 |         await searchInput.fill('Direction')
  175 |         console.log('  ✓ Organigramme search working')
  176 |       } else {
  177 |         console.log('  ⚠ Organigramme search input not found')
  178 |       }
  179 |     } catch (e) {
  180 |       failures.push(`Organigramme search: ${String(e?.message ?? e)}`)
  181 |     }
  182 | 
  183 |     // SUMMARY
  184 |     console.log('\n[E2E] Summary:')
  185 |     console.log(`  Total issues: ${failures.length}`)
  186 |     if (failures.length > 0) {
  187 |       failures.forEach((f, i) => console.log(`  ${i + 1}. ${f}`))
  188 |     }
  189 | 
  190 |     await adminCtx.close()
  191 |     await validateurCtx.close()
  192 |     await demandeurCtx.close()
  193 | 
> 194 |     expect(failures, failures.join('\n')).toEqual([])
      |                                           ^ Error: Login admin: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
  195 |   })
  196 | })
  197 | 
```