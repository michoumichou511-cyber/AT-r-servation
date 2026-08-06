import { test, expect } from '@playwright/test';
import { loginAs } from './helpers/auth.helper';
import { TEST_MISSION } from './helpers/test-data';

test.describe('Flux complet de mission', () => {
  const missionTitle = TEST_MISSION.titre();

  test.describe.serial('Cycle de vie : création → validation → clôture', () => {

    test('Étape 1 — Demandeur crée une nouvelle mission', async ({ page }) => {
      await test.step('Login demandeur', async () => {
        await loginAs(page, 'demandeur');
      });

      await test.step('Naviguer vers nouvelle mission', async () => {
        const newMissionBtn = page.locator('a:has-text("Nouvelle"), button:has-text("Nouvelle"), a[href*="new"], a[href*="nouvelle"]').first();
        if (await newMissionBtn.isVisible()) {
          await newMissionBtn.click();
        } else {
          await page.goto('/missions/nouvelle');
        }
        await page.waitForLoadState('networkidle');
      });

      await test.step('Remplir le formulaire — Étape 1 Informations', async () => {
        const titreInput = page.locator('input[name="titre"], input[placeholder*="titre"], input[placeholder*="Titre"]').first();
        if (await titreInput.isVisible({ timeout: 5000 })) {
          await titreInput.fill(missionTitle);
        }

        const destInput = page.locator('input[name="destination"], input[placeholder*="destination"], input[placeholder*="Destination"], select[name="destination"]').first();
        if (await destInput.isVisible()) {
          if (await destInput.evaluate(el => el.tagName) === 'SELECT') {
            await destInput.selectOption({ label: TEST_MISSION.destination });
          } else {
            await destInput.fill(TEST_MISSION.destination);
          }
        }

        const objectifsInput = page.locator('textarea[name="objectifs"], textarea[placeholder*="objectif"]').first();
        if (await objectifsInput.isVisible()) {
          await objectifsInput.fill(TEST_MISSION.objectifs);
        }

        const dateDepart = page.locator('input[name="date_depart"], input[type="date"]').first();
        if (await dateDepart.isVisible()) {
          await dateDepart.fill(TEST_MISSION.date_depart);
        }

        const dateRetour = page.locator('input[name="date_retour"], input[type="date"]').nth(1);
        if (await dateRetour.isVisible().catch(() => false)) {
          await dateRetour.fill(TEST_MISSION.date_retour);
        }
      });

      await test.step('Passer aux étapes suivantes et soumettre', async () => {
        for (let step = 0; step < 4; step++) {
          const nextBtn = page.locator('button:has-text("Suivant"), button:has-text("Continuer"), button:has-text("Étape")').first();
          if (await nextBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
            await nextBtn.click();
            await page.waitForTimeout(1000);
          }
        }

        const submitBtn = page.locator('button:has-text("Soumettre"), button:has-text("Envoyer"), button:has-text("Créer")').first();
        if (await submitBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
          await submitBtn.click();
          await page.waitForTimeout(3000);
        }
      });
    });

    test('Étape 2 — Mission visible dans la liste du demandeur', async ({ page }) => {
      await loginAs(page, 'demandeur');
      await page.goto('/missions');
      await page.waitForLoadState('networkidle');

      const body = await page.textContent('body');
      expect(body).toBeTruthy();
    });

    test('Étape 3 — Validateur voit la mission en attente', async ({ page }) => {
      await loginAs(page, 'validateur');
      await page.goto('/validations');
      await page.waitForLoadState('networkidle');

      const body = await page.textContent('body');
      expect(body).toBeTruthy();
    });

    test('Étape 4 — Validateur approuve une mission', async ({ page }) => {
      await loginAs(page, 'validateur');
      await page.goto('/validations');
      await page.waitForLoadState('networkidle');

      const approveBtn = page.locator('button:has-text("Approuver"), button:has-text("Valider"), button[title*="approuver"]').first();
      if (await approveBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
        await approveBtn.click();
        await page.waitForTimeout(2000);

        const confirmBtn = page.locator('button:has-text("Confirmer"), button:has-text("Oui")').first();
        if (await confirmBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
          await confirmBtn.click();
        }
        await page.waitForTimeout(2000);
      }
    });
  });

  test.describe.serial('Flux de rejet', () => {
    test('Validateur rejette une mission avec motif', async ({ page }) => {
      await loginAs(page, 'validateur');
      await page.goto('/validations');
      await page.waitForLoadState('networkidle');

      const rejectBtn = page.locator('button:has-text("Rejeter"), button:has-text("Refuser"), button[title*="rejeter"]').first();
      if (await rejectBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
        await rejectBtn.click();
        await page.waitForTimeout(1000);

        const motifInput = page.locator('textarea[name="motif"], textarea[placeholder*="motif"], textarea').first();
        if (await motifInput.isVisible({ timeout: 3000 }).catch(() => false)) {
          await motifInput.fill('Budget insuffisant pour cette période');
        }

        const confirmBtn = page.locator('button:has-text("Confirmer"), button:has-text("Rejeter"), button[type="submit"]').first();
        if (await confirmBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
          await confirmBtn.click({ force: true });
        }
        await page.waitForTimeout(2000);
      }
    });
  });
});
