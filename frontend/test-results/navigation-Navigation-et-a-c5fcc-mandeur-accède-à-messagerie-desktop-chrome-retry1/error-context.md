# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: navigation.spec.ts >> Navigation et autorisations >> Demandeur — pages autorisées >> Demandeur accède à /messagerie
- Location: tests\navigation.spec.ts:51:7

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
  1  | import { Page, expect } from '@playwright/test';
  2  | 
  3  | export const CREDENTIALS = {
  4  |   admin: {
  5  |     email: 'admin@at.dz',
  6  |     password: 'Password@123',
  7  |     role: 'admin',
  8  |     name: 'Admin',
  9  |   },
  10 |   validateur: {
  11 |     email: 'nadia.khelifi@at.dz',
  12 |     password: 'Password@123',
  13 |     role: 'validateur',
  14 |     name: 'Nadia Khelifi',
  15 |   },
  16 |   demandeur: {
  17 |     email: 'demandeur@at.dz',
  18 |     password: 'Password@123',
  19 |     role: 'demandeur',
  20 |     name: 'Demandeur Test',
  21 |   },
  22 | } as const;
  23 | 
  24 | export type RoleName = keyof typeof CREDENTIALS;
  25 | 
  26 | export async function loginAs(page: Page, role: RoleName) {
  27 |   const creds = CREDENTIALS[role];
> 28 |   await page.goto('/login');
     |              ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
  29 | 
  30 |   const emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="@"]').first();
  31 |   await emailInput.waitFor({ state: 'visible', timeout: 30000 });
  32 | 
  33 |   await emailInput.fill(creds.email);
  34 |   const passwordInput = page.locator('input[type="password"]').first();
  35 |   await passwordInput.fill(creds.password);
  36 | 
  37 |   const submitBtn = page.locator('button:has-text("Se connecter"), button[type="submit"]').first();
  38 |   await submitBtn.click();
  39 | 
  40 |   await page.waitForFunction(
  41 |     () => !window.location.pathname.includes('/login'),
  42 |     { timeout: 30000 }
  43 |   );
  44 |   await page.waitForLoadState('domcontentloaded');
  45 |   await page.waitForTimeout(2000);
  46 | }
  47 | 
  48 | export async function logout(page: Page) {
  49 |   await page.evaluate(() => {
  50 |     localStorage.removeItem('at_token');
  51 |   });
  52 |   await page.goto('/login');
  53 |   await page.waitForLoadState('domcontentloaded');
  54 | }
  55 | 
```