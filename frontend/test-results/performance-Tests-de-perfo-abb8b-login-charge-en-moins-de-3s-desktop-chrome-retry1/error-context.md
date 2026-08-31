# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: performance.spec.ts >> Tests de performance >> Page login charge en moins de 3s
- Location: tests\performance.spec.ts:6:3

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
  2  | import { loginAs } from './helpers/auth.helper';
  3  | 
  4  | test.describe('Tests de performance', () => {
  5  | 
  6  |   test('Page login charge en moins de 3s', async ({ page }) => {
  7  |     const start = Date.now();
> 8  |     await page.goto('/login');
     |                ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
  9  |     await page.waitForLoadState('domcontentloaded');
  10 | 
  11 |     const loginForm = page.locator('input[type="email"], input[type="password"]').first();
  12 |     await expect(loginForm).toBeVisible({ timeout: 10000 });
  13 | 
  14 |     const elapsed = Date.now() - start;
  15 |     console.log(`⏱️ Login chargé en ${elapsed}ms`);
  16 |     expect(elapsed).toBeLessThan(5000);
  17 |   });
  18 | 
  19 |   test('Dashboard charge en moins de 5s après login', async ({ page }) => {
  20 |     await page.goto('/login');
  21 |     await page.waitForLoadState('networkidle');
  22 | 
  23 |     const emailInput = page.locator('input[type="email"], input[name="email"]').first();
  24 |     const passwordInput = page.locator('input[type="password"]').first();
  25 |     await emailInput.fill('admin@at.dz');
  26 |     await passwordInput.fill('Password@123');
  27 | 
  28 |     const start = Date.now();
  29 |     const submitBtn = page.locator('button[type="submit"], button:has-text("Connexion"), button:has-text("Se connecter")').first();
  30 |     await submitBtn.click();
  31 |     await page.waitForFunction(() => !window.location.pathname.includes('/login'), { timeout: 15000 });
  32 |     await page.waitForLoadState('networkidle');
  33 | 
  34 |     const elapsed = Date.now() - start;
  35 |     console.log(`⏱️ Dashboard chargé en ${elapsed}ms après login`);
  36 |     expect(elapsed).toBeLessThan(8000);
  37 |   });
  38 | 
  39 |   test('Navigation entre pages rapide (< 3s)', async ({ page }) => {
  40 |     await loginAs(page, 'admin');
  41 | 
  42 |     const pages = ['/missions', '/notifications', '/profil', '/organigramme'];
  43 |     for (const p of pages) {
  44 |       const start = Date.now();
  45 |       await page.goto(p);
  46 |       await page.waitForLoadState('domcontentloaded');
  47 |       const elapsed = Date.now() - start;
  48 |       console.log(`⏱️ ${p} chargé en ${elapsed}ms`);
  49 |       expect(elapsed).toBeLessThan(5000);
  50 |     }
  51 |   });
  52 | 
  53 |   test('Pas de requêtes API en erreur 500', async ({ page }) => {
  54 |     const errors: string[] = [];
  55 |     page.on('response', response => {
  56 |       if (response.status() >= 500) {
  57 |         errors.push(`${response.status()} ${response.url()}`);
  58 |       }
  59 |     });
  60 | 
  61 |     await loginAs(page, 'admin');
  62 |     await page.goto('/missions');
  63 |     await page.waitForLoadState('networkidle');
  64 |     await page.goto('/notifications');
  65 |     await page.waitForLoadState('networkidle');
  66 | 
  67 |     if (errors.length > 0) {
  68 |       console.log('❌ Erreurs 500 détectées:', errors);
  69 |     }
  70 |     expect(errors.length).toBe(0);
  71 |   });
  72 | });
  73 | 
```