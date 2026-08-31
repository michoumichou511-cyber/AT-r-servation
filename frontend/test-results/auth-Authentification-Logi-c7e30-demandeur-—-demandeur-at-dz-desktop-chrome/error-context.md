# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: auth.spec.ts >> Authentification >> Login valide par rôle >> Login demandeur — demandeur@at.dz
- Location: tests\auth.spec.ts:14:7

# Error details

```
Error: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
Call log:
  - navigating to "http://127.0.0.1:5173/login", waiting until "load"

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
  1  | import { test, expect } from '@playwright/test';
  2  | import { loginAs, logout, CREDENTIALS, RoleName } from './helpers/auth.helper';
  3  | 
  4  | test.describe('Authentification', () => {
  5  |   test.beforeEach(async ({ page }) => {
> 6  |     await page.goto('/login');
     |                ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
  7  |     await page.waitForLoadState('networkidle');
  8  |   });
  9  | 
  10 |   test.describe('Login valide par rôle', () => {
  11 |     const roles: RoleName[] = ['admin', 'validateur', 'demandeur'];
  12 | 
  13 |     for (const role of roles) {
  14 |       test(`Login ${role} — ${CREDENTIALS[role].email}`, async ({ page }) => {
  15 |         await loginAs(page, role);
  16 |         await expect(page).not.toHaveURL(/\/login/);
  17 |         const body = page.locator('body');
  18 |         await expect(body).toBeVisible();
  19 |       });
  20 |     }
  21 |   });
  22 | 
  23 |   test('Login avec mauvais mot de passe → erreur', async ({ page }) => {
  24 |     const emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="mail"]').first();
  25 |     const passwordInput = page.locator('input[type="password"]').first();
  26 |     await emailInput.fill('admin@at.dz');
  27 |     await passwordInput.fill('WrongPassword');
  28 | 
  29 |     const submitBtn = page.locator('button[type="submit"], button:has-text("Connexion"), button:has-text("Se connecter")').first();
  30 |     await submitBtn.click();
  31 | 
  32 |     await page.waitForTimeout(2000);
  33 |     const errorMsg = page.locator('text=/erreur|incorrect|invalide|échoué/i').first();
  34 |     await expect(errorMsg).toBeVisible({ timeout: 5000 });
  35 |   });
  36 | 
  37 |   test('Login avec email inexistant → erreur', async ({ page }) => {
  38 |     const emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="mail"]').first();
  39 |     const passwordInput = page.locator('input[type="password"]').first();
  40 |     await emailInput.fill('nexistepas@at.dz');
  41 |     await passwordInput.fill('Password@123');
  42 | 
  43 |     const submitBtn = page.locator('button[type="submit"], button:has-text("Connexion"), button:has-text("Se connecter")').first();
  44 |     await submitBtn.click();
  45 | 
  46 |     await page.waitForTimeout(2000);
  47 |     const errorMsg = page.locator('text=/erreur|incorrect|invalide|échoué|introuvable/i').first();
  48 |     await expect(errorMsg).toBeVisible({ timeout: 5000 });
  49 |   });
  50 | 
  51 |   test('Champs vides → validation empêche soumission', async ({ page }) => {
  52 |     const submitBtn = page.locator('button[type="submit"], button:has-text("Connexion"), button:has-text("Se connecter")').first();
  53 |     await submitBtn.click();
  54 |     await page.waitForTimeout(1000);
  55 |     await expect(page).toHaveURL(/\/login/);
  56 |   });
  57 | 
  58 |   test('Déconnexion redirige vers login', async ({ page }) => {
  59 |     await loginAs(page, 'admin');
  60 |     await logout(page);
  61 |     await expect(page).toHaveURL(/\/login/);
  62 |   });
  63 | 
  64 |   test('Redirection vers login si non authentifié', async ({ page }) => {
  65 |     await page.goto('/missions');
  66 |     await page.waitForLoadState('networkidle');
  67 |     await expect(page).toHaveURL(/\/login/);
  68 |   });
  69 | 
  70 |   test.describe('Dashboard correct par rôle après login', () => {
  71 |     test('Admin voit le dashboard admin', async ({ page }) => {
  72 |       await loginAs(page, 'admin');
  73 |       const content = page.locator('body');
  74 |       await expect(content).toContainText(/dashboard|tableau de bord|statistiques|administration/i);
  75 |     });
  76 | 
  77 |     test('Validateur voit ses validations', async ({ page }) => {
  78 |       await loginAs(page, 'validateur');
  79 |       const body = await page.textContent('body');
  80 |       expect(body).toBeTruthy();
  81 |     });
  82 | 
  83 |     test('Demandeur voit ses missions', async ({ page }) => {
  84 |       await loginAs(page, 'demandeur');
  85 |       const body = await page.textContent('body');
  86 |       expect(body).toBeTruthy();
  87 |     });
  88 |   });
  89 | });
  90 | 
```