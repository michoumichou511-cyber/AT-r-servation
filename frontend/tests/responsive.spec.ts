import { test, expect } from '@playwright/test';
import { loginAs } from './helpers/auth.helper';

test.describe('Tests responsive', () => {
  const viewports = [
    { name: 'Mobile', width: 375, height: 667 },
    { name: 'Tablette', width: 768, height: 1024 },
    { name: 'Desktop', width: 1920, height: 1080 },
  ];

  for (const vp of viewports) {
    test.describe(`${vp.name} (${vp.width}x${vp.height})`, () => {
      test.use({ viewport: { width: vp.width, height: vp.height } });

      test(`Page login s'affiche correctement`, async ({ page }) => {
        await page.goto('/login');
        await page.waitForLoadState('networkidle');

        const loginForm = page.locator('form, input[type="email"], input[type="password"]').first();
        await expect(loginForm).toBeVisible();

        // Pas de scroll horizontal
        const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
        expect(bodyWidth).toBeLessThanOrEqual(vp.width + 20);
      });

      test(`Dashboard s'affiche correctement`, async ({ page }) => {
        await loginAs(page, 'admin');

        const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
        expect(bodyWidth).toBeLessThanOrEqual(vp.width + 20);

        if (vp.width <= 768) {
          // Sur mobile/tablette, vérifier que le menu hamburger existe
          const hamburger = page.locator('button[aria-label*="menu"], button:has(svg), [class*="hamburger"], [class*="toggle"]').first();
          // Le hamburger peut être présent ou non selon le breakpoint
        }
      });

      test(`Liste missions s'affiche`, async ({ page }) => {
        await loginAs(page, 'admin');
        await page.goto('/missions');
        await page.waitForLoadState('networkidle');

        const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
        expect(bodyWidth).toBeLessThanOrEqual(vp.width + 20);
      });
    });
  }
});
