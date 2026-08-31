# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: responsive.spec.ts >> Tests responsive >> Desktop (1920x1080) >> Page login s'affiche correctement
- Location: tests\responsive.spec.ts:15:7

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
  4  | test.describe('Tests responsive', () => {
  5  |   const viewports = [
  6  |     { name: 'Mobile', width: 375, height: 667 },
  7  |     { name: 'Tablette', width: 768, height: 1024 },
  8  |     { name: 'Desktop', width: 1920, height: 1080 },
  9  |   ];
  10 | 
  11 |   for (const vp of viewports) {
  12 |     test.describe(`${vp.name} (${vp.width}x${vp.height})`, () => {
  13 |       test.use({ viewport: { width: vp.width, height: vp.height } });
  14 | 
  15 |       test(`Page login s'affiche correctement`, async ({ page }) => {
> 16 |         await page.goto('/login');
     |                    ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
  17 |         await page.waitForLoadState('networkidle');
  18 | 
  19 |         const loginForm = page.locator('form, input[type="email"], input[type="password"]').first();
  20 |         await expect(loginForm).toBeVisible();
  21 | 
  22 |         // Pas de scroll horizontal
  23 |         const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
  24 |         expect(bodyWidth).toBeLessThanOrEqual(vp.width + 20);
  25 |       });
  26 | 
  27 |       test(`Dashboard s'affiche correctement`, async ({ page }) => {
  28 |         await loginAs(page, 'admin');
  29 | 
  30 |         const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
  31 |         expect(bodyWidth).toBeLessThanOrEqual(vp.width + 20);
  32 | 
  33 |         if (vp.width <= 768) {
  34 |           // Sur mobile/tablette, vérifier que le menu hamburger existe
  35 |           const hamburger = page.locator('button[aria-label*="menu"], button:has(svg), [class*="hamburger"], [class*="toggle"]').first();
  36 |           // Le hamburger peut être présent ou non selon le breakpoint
  37 |         }
  38 |       });
  39 | 
  40 |       test(`Liste missions s'affiche`, async ({ page }) => {
  41 |         await loginAs(page, 'admin');
  42 |         await page.goto('/missions');
  43 |         await page.waitForLoadState('networkidle');
  44 | 
  45 |         const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
  46 |         expect(bodyWidth).toBeLessThanOrEqual(vp.width + 20);
  47 |       });
  48 |     });
  49 |   }
  50 | });
  51 | 
```