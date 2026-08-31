# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: e2e-full-app.spec.js >> E2E complet application >> workflow multi-profils complet
- Location: tests\e2e-full-app.spec.js:73:3

# Error details

```
Error: login admin: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
Call log:
  - navigating to "http://127.0.0.1:5173/login", waiting until "domcontentloaded"

login validateur: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
Call log:
  - navigating to "http://127.0.0.1:5173/login", waiting until "domcontentloaded"

login demandeur: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
Call log:
  - navigating to "http://127.0.0.1:5173/login", waiting until "domcontentloaded"

login utilisateur: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
Call log:
  - navigating to "http://127.0.0.1:5173/login", waiting until "domcontentloaded"

admin -> / : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
Call log:
  - navigating to "http://127.0.0.1:5173/", waiting until "domcontentloaded"

admin -> /missions : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
Call log:
  - navigating to "http://127.0.0.1:5173/missions", waiting until "domcontentloaded"

admin -> /notifications : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
Call log:
  - navigating to "http://127.0.0.1:5173/notifications", waiting until "domcontentloaded"

admin -> /organigramme : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
Call log:
  - navigating to "http://127.0.0.1:5173/organigramme", waiting until "domcontentloaded"

admin -> /profil : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
Call log:
  - navigating to "http://127.0.0.1:5173/profil", waiting until "domcontentloaded"

admin -> /messagerie : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

admin -> /admin/utilisateurs : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/utilisateurs
Call log:
  - navigating to "http://127.0.0.1:5173/admin/utilisateurs", waiting until "domcontentloaded"

admin -> /admin/prestataires : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/prestataires
Call log:
  - navigating to "http://127.0.0.1:5173/admin/prestataires", waiting until "domcontentloaded"

admin -> /admin/budgets : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/budgets
Call log:
  - navigating to "http://127.0.0.1:5173/admin/budgets", waiting until "domcontentloaded"

admin -> /admin/audit-logs : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/audit-logs
Call log:
  - navigating to "http://127.0.0.1:5173/admin/audit-logs", waiting until "domcontentloaded"

admin -> /admin/statistiques : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/statistiques
Call log:
  - navigating to "http://127.0.0.1:5173/admin/statistiques", waiting until "domcontentloaded"

admin -> /rapports : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
Call log:
  - navigating to "http://127.0.0.1:5173/rapports", waiting until "domcontentloaded"

admin -> /validations : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
Call log:
  - navigating to "http://127.0.0.1:5173/validations", waiting until "domcontentloaded"

validateur -> / : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
Call log:
  - navigating to "http://127.0.0.1:5173/", waiting until "domcontentloaded"

validateur -> /missions : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
Call log:
  - navigating to "http://127.0.0.1:5173/missions", waiting until "domcontentloaded"

validateur -> /validations : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
Call log:
  - navigating to "http://127.0.0.1:5173/validations", waiting until "domcontentloaded"

validateur -> /notifications : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
Call log:
  - navigating to "http://127.0.0.1:5173/notifications", waiting until "domcontentloaded"

validateur -> /organigramme : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
Call log:
  - navigating to "http://127.0.0.1:5173/organigramme", waiting until "domcontentloaded"

validateur -> /messagerie : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

validateur -> /rapports : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
Call log:
  - navigating to "http://127.0.0.1:5173/rapports", waiting until "domcontentloaded"

validateur -> /profil : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
Call log:
  - navigating to "http://127.0.0.1:5173/profil", waiting until "domcontentloaded"

demandeur -> / : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
Call log:
  - navigating to "http://127.0.0.1:5173/", waiting until "domcontentloaded"

demandeur -> /missions : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
Call log:
  - navigating to "http://127.0.0.1:5173/missions", waiting until "domcontentloaded"

demandeur -> /missions/nouvelle : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions/nouvelle
Call log:
  - navigating to "http://127.0.0.1:5173/missions/nouvelle", waiting until "domcontentloaded"

demandeur -> /notifications : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
Call log:
  - navigating to "http://127.0.0.1:5173/notifications", waiting until "domcontentloaded"

demandeur -> /organigramme : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
Call log:
  - navigating to "http://127.0.0.1:5173/organigramme", waiting until "domcontentloaded"

demandeur -> /messagerie : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

demandeur -> /profil : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
Call log:
  - navigating to "http://127.0.0.1:5173/profil", waiting until "domcontentloaded"

utilisateur -> / : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
Call log:
  - navigating to "http://127.0.0.1:5173/", waiting until "domcontentloaded"

utilisateur -> /missions : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
Call log:
  - navigating to "http://127.0.0.1:5173/missions", waiting until "domcontentloaded"

utilisateur -> /notifications : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
Call log:
  - navigating to "http://127.0.0.1:5173/notifications", waiting until "domcontentloaded"

utilisateur -> /organigramme : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
Call log:
  - navigating to "http://127.0.0.1:5173/organigramme", waiting until "domcontentloaded"

utilisateur -> /messagerie : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

utilisateur -> /profil : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
Call log:
  - navigating to "http://127.0.0.1:5173/profil", waiting until "domcontentloaded"

admin organigramme interaction: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
Call log:
  - navigating to "http://127.0.0.1:5173/organigramme", waiting until "domcontentloaded"

admin export excel: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
Call log:
  - navigating to "http://127.0.0.1:5173/rapports", waiting until "domcontentloaded"

admin export pdf: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
Call log:
  - navigating to "http://127.0.0.1:5173/rapports", waiting until "domcontentloaded"

admin messagerie ouverture: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

demandeur messagerie ouverture: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

admin messagerie: aucune conversation cliquable
admin messagerie ouverture: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

admin messagerie: aucune conversation trouvée
demandeur messagerie ouverture: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

demandeur messagerie: aucune conversation trouvée
demandeur création mission: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions/nouvelle
Call log:
  - navigating to "http://127.0.0.1:5173/missions/nouvelle", waiting until "domcontentloaded"

validateur approbation: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
Call log:
  - navigating to "http://127.0.0.1:5173/validations", waiting until "domcontentloaded"

validateur rejet: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
Call log:
  - navigating to "http://127.0.0.1:5173/validations", waiting until "domcontentloaded"

demandeur upload PJ: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
Call log:
  - navigating to "http://127.0.0.1:5173/missions", waiting until "domcontentloaded"

admin organigramme: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
Call log:
  - navigating to "http://127.0.0.1:5173/organigramme", waiting until "domcontentloaded"

admin messagerie ouverture: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
Call log:
  - navigating to "http://127.0.0.1:5173/messagerie", waiting until "domcontentloaded"

admin messagerie: liste conversations vide

expect(received).toEqual(expected) // deep equality

- Expected  -   1
+ Received  + 210

- Array []
+ Array [
+   "login admin: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/login\", waiting until \"domcontentloaded\"
+ ",
+   "login validateur: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/login\", waiting until \"domcontentloaded\"
+ ",
+   "login demandeur: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/login\", waiting until \"domcontentloaded\"
+ ",
+   "login utilisateur: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/login\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> / : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /missions : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /notifications : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/notifications\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /organigramme : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/organigramme\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /profil : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/profil\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /messagerie : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /admin/utilisateurs : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/utilisateurs
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/admin/utilisateurs\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /admin/prestataires : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/prestataires
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/admin/prestataires\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /admin/budgets : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/budgets
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/admin/budgets\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /admin/audit-logs : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/audit-logs
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/admin/audit-logs\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /admin/statistiques : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/admin/statistiques
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/admin/statistiques\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /rapports : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/rapports\", waiting until \"domcontentloaded\"
+ ",
+   "admin -> /validations : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/validations\", waiting until \"domcontentloaded\"
+ ",
+   "validateur -> / : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/\", waiting until \"domcontentloaded\"
+ ",
+   "validateur -> /missions : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions\", waiting until \"domcontentloaded\"
+ ",
+   "validateur -> /validations : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/validations\", waiting until \"domcontentloaded\"
+ ",
+   "validateur -> /notifications : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/notifications\", waiting until \"domcontentloaded\"
+ ",
+   "validateur -> /organigramme : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/organigramme\", waiting until \"domcontentloaded\"
+ ",
+   "validateur -> /messagerie : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "validateur -> /rapports : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/rapports\", waiting until \"domcontentloaded\"
+ ",
+   "validateur -> /profil : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/profil\", waiting until \"domcontentloaded\"
+ ",
+   "demandeur -> / : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/\", waiting until \"domcontentloaded\"
+ ",
+   "demandeur -> /missions : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions\", waiting until \"domcontentloaded\"
+ ",
+   "demandeur -> /missions/nouvelle : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions/nouvelle
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions/nouvelle\", waiting until \"domcontentloaded\"
+ ",
+   "demandeur -> /notifications : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/notifications\", waiting until \"domcontentloaded\"
+ ",
+   "demandeur -> /organigramme : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/organigramme\", waiting until \"domcontentloaded\"
+ ",
+   "demandeur -> /messagerie : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "demandeur -> /profil : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/profil\", waiting until \"domcontentloaded\"
+ ",
+   "utilisateur -> / : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/\", waiting until \"domcontentloaded\"
+ ",
+   "utilisateur -> /missions : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions\", waiting until \"domcontentloaded\"
+ ",
+   "utilisateur -> /notifications : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/notifications
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/notifications\", waiting until \"domcontentloaded\"
+ ",
+   "utilisateur -> /organigramme : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/organigramme\", waiting until \"domcontentloaded\"
+ ",
+   "utilisateur -> /messagerie : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "utilisateur -> /profil : page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/profil
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/profil\", waiting until \"domcontentloaded\"
+ ",
+   "admin organigramme interaction: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/organigramme\", waiting until \"domcontentloaded\"
+ ",
+   "admin export excel: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/rapports\", waiting until \"domcontentloaded\"
+ ",
+   "admin export pdf: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/rapports
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/rapports\", waiting until \"domcontentloaded\"
+ ",
+   "admin messagerie ouverture: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "demandeur messagerie ouverture: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "admin messagerie: aucune conversation cliquable",
+   "admin messagerie ouverture: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "admin messagerie: aucune conversation trouvée",
+   "demandeur messagerie ouverture: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "demandeur messagerie: aucune conversation trouvée",
+   "demandeur création mission: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions/nouvelle
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions/nouvelle\", waiting until \"domcontentloaded\"
+ ",
+   "validateur approbation: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/validations\", waiting until \"domcontentloaded\"
+ ",
+   "validateur rejet: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/validations
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/validations\", waiting until \"domcontentloaded\"
+ ",
+   "demandeur upload PJ: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/missions
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/missions\", waiting until \"domcontentloaded\"
+ ",
+   "admin organigramme: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/organigramme
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/organigramme\", waiting until \"domcontentloaded\"
+ ",
+   "admin messagerie ouverture: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/messagerie
+ Call log:
+   - navigating to \"http://127.0.0.1:5173/messagerie\", waiting until \"domcontentloaded\"
+ ",
+   "admin messagerie: liste conversations vide",
+ ]
```

# Test source

```ts
  275 |       if (await approveBtn.count()) {
  276 |         await approveBtn.click()
  277 |         const ok = validateur.getByText(/succès|approuvée|validée/i).first()
  278 |         await expect(ok).toBeVisible({ timeout: 8000 })
  279 |       }
  280 |     } catch (e) {
  281 |       failures.push(`validateur approbation: ${String(e?.message ?? e)}`)
  282 |     }
  283 | 
  284 |     // WORKFLOW REJET MISSION (validateur)
  285 |     try {
  286 |       await validateur.goto('/validations', { waitUntil: 'domcontentloaded' })
  287 |       const rejectBtn = validateur.getByRole('button', { name: /Rejeter|Refuser/i }).first()
  288 |       if (await rejectBtn.count()) {
  289 |         await rejectBtn.click()
  290 |         const motif = validateur.locator('textarea, input[name*="motif"], input[name*="comment"]').first()
  291 |         if (await motif.count()) {
  292 |           await motif.fill('Rejet test E2E')
  293 |         }
  294 |         const confirmReject = validateur.getByRole('button', { name: /Confirmer|Rejeter|Valider/i }).first()
  295 |         if (await confirmReject.count()) {
  296 |           await confirmReject.click()
  297 |         }
  298 |         const ok = validateur.getByText(/succès|rejetée|refusée/i).first()
  299 |         await expect(ok).toBeVisible({ timeout: 8000 })
  300 |       }
  301 |     } catch (e) {
  302 |       failures.push(`validateur rejet: ${String(e?.message ?? e)}`)
  303 |     }
  304 | 
  305 |     // UPLOAD PIÈCE JUSTIFICATIVE (demandeur)
  306 |     try {
  307 |       await demandeur.goto('/missions', { waitUntil: 'domcontentloaded' })
  308 |       const missionLink = demandeur.locator('a[href*="/missions/"]').first()
  309 |       if (await missionLink.count()) {
  310 |         await missionLink.click()
  311 |       } else {
  312 |         await demandeur.goto('/missions', { waitUntil: 'domcontentloaded' })
  313 |       }
  314 | 
  315 |       const documentsTab = demandeur.getByRole('button', { name: /Documents/i }).first()
  316 |       if (await documentsTab.count()) {
  317 |         await documentsTab.click()
  318 |       }
  319 | 
  320 |       const fileInput = demandeur.locator('input[type="file"]').first()
  321 |       if (await fileInput.count()) {
  322 |         await fileInput.setInputFiles({
  323 |           name: 'piece-justificative-test.txt',
  324 |           mimeType: 'text/plain',
  325 |           buffer: Buffer.from('Pièce justificative E2E'),
  326 |         })
  327 |       } else {
  328 |         failures.push('demandeur upload PJ: input file introuvable')
  329 |       }
  330 |     } catch (e) {
  331 |       failures.push(`demandeur upload PJ: ${String(e?.message ?? e)}`)
  332 |     }
  333 | 
  334 |     // ORGANIGRAMME COMPLET (admin)
  335 |     try {
  336 |       await admin.goto('/organigramme', { waitUntil: 'domcontentloaded' })
  337 |       const search = admin.locator('input[placeholder*="Recherche"], input[placeholder*="recherche"], input[type="search"], input').first()
  338 |       if (await search.count()) {
  339 |         await search.fill('Direction')
  340 |       }
  341 |       const hasResult = await admin.locator('button, [role="button"], .node, .react-flow__node').count()
  342 |       if (hasResult < 1) {
  343 |         failures.push('admin organigramme: aucun résultat affiché')
  344 |       } else {
  345 |         await admin.locator('button, [role="button"], .node, .react-flow__node').first().click()
  346 |         const detailPanel = admin.getByText(/Direction|Service|Détail|Responsable/i).first()
  347 |         await expect(detailPanel).toBeVisible({ timeout: 8000 })
  348 |       }
  349 |     } catch (e) {
  350 |       failures.push(`admin organigramme: ${String(e?.message ?? e)}`)
  351 |     }
  352 | 
  353 |     // MESSAGERIE ADMIN (ouverture + liste + envoi)
  354 |     try {
  355 |       await openMessagerie(admin, failures, 'admin')
  356 |       const convList = admin.locator('button').filter({ hasText: /Interlocuteur|Admin|Demandeur|Validateur|Utilisateur|@/i })
  357 |       const convCount = await convList.count()
  358 |       if (convCount < 1) {
  359 |         failures.push('admin messagerie: liste conversations vide')
  360 |       } else {
  361 |         await convList.first().click()
  362 |         const txt = `Admin msg test ${Date.now()}`
  363 |         await admin.locator('textarea').fill(txt)
  364 |         await admin.getByRole('button', { name: /Envoyer/i }).click()
  365 |       }
  366 |     } catch (e) {
  367 |       failures.push(`admin messagerie: ${String(e?.message ?? e)}`)
  368 |     }
  369 | 
  370 |     await adminCtx.close()
  371 |     await validateurCtx.close()
  372 |     await demandeurCtx.close()
  373 |     await utilisateurCtx.close()
  374 | 
> 375 |     expect(failures, failures.join('\n')).toEqual([])
      |                                           ^ Error: login admin: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
  376 |   })
  377 | })
  378 | 
  379 | 
```