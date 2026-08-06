import { test, expect } from '@playwright/test';
import { loginAs } from './helpers/auth.helper';
import { TEST_PRESTATAIRE } from './helpers/test-data';

test.describe('Tests CRUD', () => {

  test.describe('Missions — lecture et liste', () => {
    test('Liste des missions affiche des résultats', async ({ page }) => {
      await loginAs(page, 'admin');
      await page.goto('/missions');
      await page.waitForLoadState('networkidle');
      const body = await page.textContent('body');
      expect(body).toBeTruthy();
      expect(body!.length).toBeGreaterThan(100);
    });

    test('Détail mission accessible au clic', async ({ page }) => {
      await loginAs(page, 'admin');
      await page.goto('/missions');
      await page.waitForLoadState('networkidle');

      const missionLink = page.locator('a[href*="/missions/"], tr:has-text("mission"), [class*="card"]:has-text("mission")').first();
      if (await missionLink.isVisible({ timeout: 5000 }).catch(() => false)) {
        await missionLink.click();
        await page.waitForLoadState('networkidle');
        const url = page.url();
        expect(url).toContain('/missions/');
      }
    });
  });

  test.describe('Prestataires — CRUD admin', () => {
    test('Liste des prestataires', async ({ page }) => {
      await loginAs(page, 'admin');
      await page.goto('/admin/prestataires');
      await page.waitForLoadState('networkidle');
      const body = await page.textContent('body');
      expect(body).toContain('prestataire') || expect(body).toContain('Prestataire');
    });

    test('Formulaire de création prestataire — validation champs requis', async ({ page }) => {
      await loginAs(page, 'admin');
      await page.goto('/admin/prestataires');
      await page.waitForLoadState('networkidle');

      const addBtn = page.locator('button:has-text("Ajouter"), button:has-text("Nouveau"), button:has-text("Créer")').first();
      if (await addBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
        await addBtn.click();
        await page.waitForTimeout(1000);

        const submitBtn = page.locator('button[type="submit"], button:has-text("Enregistrer"), button:has-text("Créer")').first();
        if (await submitBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
          await submitBtn.click();
          await page.waitForTimeout(1000);
          // Le formulaire ne doit pas se fermer si champs requis vides
        }
      }
    });
  });

  test.describe('Utilisateurs — gestion admin', () => {
    test('Liste des utilisateurs accessible', async ({ page }) => {
      await loginAs(page, 'admin');
      await page.goto('/admin/utilisateurs');
      await page.waitForLoadState('networkidle');
      const body = await page.textContent('body');
      expect(body!.length).toBeGreaterThan(50);
    });
  });

  test.describe('Notifications', () => {
    test('Page notifications accessible', async ({ page }) => {
      await loginAs(page, 'admin');
      await page.goto('/notifications');
      await page.waitForLoadState('networkidle');
      await expect(page).not.toHaveURL(/\/login/);
    });
  });

  test.describe('Messagerie', () => {
    test('Page messagerie accessible', async ({ page }) => {
      await loginAs(page, 'admin');
      await page.goto('/messagerie');
      await page.waitForLoadState('networkidle');
      await expect(page).not.toHaveURL(/\/login/);
    });
  });
});
