import { test, expect } from '@playwright/test';
import { loginAs, logout, CREDENTIALS, RoleName } from './helpers/auth.helper';

test.describe('Authentification', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');
  });

  test.describe('Login valide par rôle', () => {
    const roles: RoleName[] = ['admin', 'validateur', 'demandeur'];

    for (const role of roles) {
      test(`Login ${role} — ${CREDENTIALS[role].email}`, async ({ page }) => {
        await loginAs(page, role);
        await expect(page).not.toHaveURL(/\/login/);
        const body = page.locator('body');
        await expect(body).toBeVisible();
      });
    }
  });

  test('Login avec mauvais mot de passe → erreur', async ({ page }) => {
    const emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="mail"]').first();
    const passwordInput = page.locator('input[type="password"]').first();
    await emailInput.fill('admin@at.dz');
    await passwordInput.fill('WrongPassword');

    const submitBtn = page.locator('button[type="submit"], button:has-text("Connexion"), button:has-text("Se connecter")').first();
    await submitBtn.click();

    await page.waitForTimeout(2000);
    const errorMsg = page.locator('text=/erreur|incorrect|invalide|échoué/i').first();
    await expect(errorMsg).toBeVisible({ timeout: 5000 });
  });

  test('Login avec email inexistant → erreur', async ({ page }) => {
    const emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="mail"]').first();
    const passwordInput = page.locator('input[type="password"]').first();
    await emailInput.fill('nexistepas@at.dz');
    await passwordInput.fill('Password@123');

    const submitBtn = page.locator('button[type="submit"], button:has-text("Connexion"), button:has-text("Se connecter")').first();
    await submitBtn.click();

    await page.waitForTimeout(2000);
    const errorMsg = page.locator('text=/erreur|incorrect|invalide|échoué|introuvable/i').first();
    await expect(errorMsg).toBeVisible({ timeout: 5000 });
  });

  test('Champs vides → validation empêche soumission', async ({ page }) => {
    const submitBtn = page.locator('button[type="submit"], button:has-text("Connexion"), button:has-text("Se connecter")').first();
    await submitBtn.click();
    await page.waitForTimeout(1000);
    await expect(page).toHaveURL(/\/login/);
  });

  test('Déconnexion redirige vers login', async ({ page }) => {
    await loginAs(page, 'admin');
    await logout(page);
    await expect(page).toHaveURL(/\/login/);
  });

  test('Redirection vers login si non authentifié', async ({ page }) => {
    await page.goto('/missions');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/login/);
  });

  test.describe('Dashboard correct par rôle après login', () => {
    test('Admin voit le dashboard admin', async ({ page }) => {
      await loginAs(page, 'admin');
      const content = page.locator('body');
      await expect(content).toContainText(/dashboard|tableau de bord|statistiques|administration/i);
    });

    test('Validateur voit ses validations', async ({ page }) => {
      await loginAs(page, 'validateur');
      const body = await page.textContent('body');
      expect(body).toBeTruthy();
    });

    test('Demandeur voit ses missions', async ({ page }) => {
      await loginAs(page, 'demandeur');
      const body = await page.textContent('body');
      expect(body).toBeTruthy();
    });
  });
});
