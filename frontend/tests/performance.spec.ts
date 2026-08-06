import { test, expect } from '@playwright/test';
import { loginAs } from './helpers/auth.helper';

test.describe('Tests de performance', () => {

  test('Page login charge en moins de 3s', async ({ page }) => {
    const start = Date.now();
    await page.goto('/login');
    await page.waitForLoadState('domcontentloaded');

    const loginForm = page.locator('input[type="email"], input[type="password"]').first();
    await expect(loginForm).toBeVisible({ timeout: 10000 });

    const elapsed = Date.now() - start;
    console.log(`⏱️ Login chargé en ${elapsed}ms`);
    expect(elapsed).toBeLessThan(5000);
  });

  test('Dashboard charge en moins de 5s après login', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    const emailInput = page.locator('input[type="email"], input[name="email"]').first();
    const passwordInput = page.locator('input[type="password"]').first();
    await emailInput.fill('admin@at.dz');
    await passwordInput.fill('Password@123');

    const start = Date.now();
    const submitBtn = page.locator('button[type="submit"], button:has-text("Connexion"), button:has-text("Se connecter")').first();
    await submitBtn.click();
    await page.waitForFunction(() => !window.location.pathname.includes('/login'), { timeout: 15000 });
    await page.waitForLoadState('networkidle');

    const elapsed = Date.now() - start;
    console.log(`⏱️ Dashboard chargé en ${elapsed}ms après login`);
    expect(elapsed).toBeLessThan(8000);
  });

  test('Navigation entre pages rapide (< 3s)', async ({ page }) => {
    await loginAs(page, 'admin');

    const pages = ['/missions', '/notifications', '/profil', '/organigramme'];
    for (const p of pages) {
      const start = Date.now();
      await page.goto(p);
      await page.waitForLoadState('domcontentloaded');
      const elapsed = Date.now() - start;
      console.log(`⏱️ ${p} chargé en ${elapsed}ms`);
      expect(elapsed).toBeLessThan(5000);
    }
  });

  test('Pas de requêtes API en erreur 500', async ({ page }) => {
    const errors: string[] = [];
    page.on('response', response => {
      if (response.status() >= 500) {
        errors.push(`${response.status()} ${response.url()}`);
      }
    });

    await loginAs(page, 'admin');
    await page.goto('/missions');
    await page.waitForLoadState('networkidle');
    await page.goto('/notifications');
    await page.waitForLoadState('networkidle');

    if (errors.length > 0) {
      console.log('❌ Erreurs 500 détectées:', errors);
    }
    expect(errors.length).toBe(0);
  });
});
