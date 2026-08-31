# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: accessibility.spec.ts >> Tests accessibilité WCAG 2.1 AA >> Page de login — scan accessibilité
- Location: tests\accessibility.spec.ts:7:3

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
  2  | import AxeBuilder from '@axe-core/playwright';
  3  | import { loginAs } from './helpers/auth.helper';
  4  | 
  5  | test.describe('Tests accessibilité WCAG 2.1 AA', () => {
  6  | 
  7  |   test('Page de login — scan accessibilité', async ({ page }) => {
> 8  |     await page.goto('/login');
     |                ^ Error: page.goto: net::ERR_CONNECTION_REFUSED at http://127.0.0.1:5173/login
  9  |     await page.waitForLoadState('networkidle');
  10 | 
  11 |     const results = await new AxeBuilder({ page })
  12 |       .withTags(['wcag2a', 'wcag2aa'])
  13 |       .exclude('.particle-background, canvas')
  14 |       .analyze();
  15 | 
  16 |     const critical = results.violations.filter(v => v.impact === 'critical' || v.impact === 'serious');
  17 |     if (critical.length > 0) {
  18 |       console.log('Violations critiques login:', JSON.stringify(critical.map(v => ({
  19 |         id: v.id,
  20 |         impact: v.impact,
  21 |         description: v.description,
  22 |         nodes: v.nodes.length,
  23 |       })), null, 2));
  24 |     }
  25 |     expect(critical.length).toBeLessThanOrEqual(5);
  26 |   });
  27 | 
  28 |   test('Dashboard admin — scan accessibilité', async ({ page }) => {
  29 |     await loginAs(page, 'admin');
  30 |     await page.waitForLoadState('networkidle');
  31 | 
  32 |     const results = await new AxeBuilder({ page })
  33 |       .withTags(['wcag2a', 'wcag2aa'])
  34 |       .exclude('canvas, svg, .recharts-wrapper')
  35 |       .analyze();
  36 | 
  37 |     const critical = results.violations.filter(v => v.impact === 'critical' || v.impact === 'serious');
  38 |     if (critical.length > 0) {
  39 |       console.log('Violations critiques dashboard:', JSON.stringify(critical.map(v => ({
  40 |         id: v.id,
  41 |         impact: v.impact,
  42 |         description: v.description,
  43 |         nodes: v.nodes.length,
  44 |       })), null, 2));
  45 |     }
  46 |     expect(critical.length).toBeLessThanOrEqual(10);
  47 |   });
  48 | 
  49 |   test('Page missions — scan accessibilité', async ({ page }) => {
  50 |     await loginAs(page, 'admin');
  51 |     await page.goto('/missions');
  52 |     await page.waitForLoadState('networkidle');
  53 | 
  54 |     const results = await new AxeBuilder({ page })
  55 |       .withTags(['wcag2a', 'wcag2aa'])
  56 |       .analyze();
  57 | 
  58 |     const critical = results.violations.filter(v => v.impact === 'critical' || v.impact === 'serious');
  59 |     expect(critical.length).toBeLessThanOrEqual(10);
  60 |   });
  61 | 
  62 |   test('Formulaire nouvelle mission — scan accessibilité', async ({ page }) => {
  63 |     await loginAs(page, 'demandeur');
  64 | 
  65 |     const newBtn = page.locator('a:has-text("Nouvelle"), a[href*="nouvelle"]').first();
  66 |     if (await newBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
  67 |       await newBtn.click();
  68 |     } else {
  69 |       await page.goto('/missions/nouvelle');
  70 |     }
  71 |     await page.waitForLoadState('networkidle');
  72 | 
  73 |     const results = await new AxeBuilder({ page })
  74 |       .withTags(['wcag2a', 'wcag2aa'])
  75 |       .analyze();
  76 | 
  77 |     const critical = results.violations.filter(v => v.impact === 'critical' || v.impact === 'serious');
  78 |     expect(critical.length).toBeLessThanOrEqual(10);
  79 |   });
  80 | });
  81 | 
```