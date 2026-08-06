import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { loginAs } from './helpers/auth.helper';

test.describe('Tests accessibilité WCAG 2.1 AA', () => {

  test('Page de login — scan accessibilité', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .exclude('.particle-background, canvas')
      .analyze();

    const critical = results.violations.filter(v => v.impact === 'critical' || v.impact === 'serious');
    if (critical.length > 0) {
      console.log('Violations critiques login:', JSON.stringify(critical.map(v => ({
        id: v.id,
        impact: v.impact,
        description: v.description,
        nodes: v.nodes.length,
      })), null, 2));
    }
    expect(critical.length).toBeLessThanOrEqual(5);
  });

  test('Dashboard admin — scan accessibilité', async ({ page }) => {
    await loginAs(page, 'admin');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .exclude('canvas, svg, .recharts-wrapper')
      .analyze();

    const critical = results.violations.filter(v => v.impact === 'critical' || v.impact === 'serious');
    if (critical.length > 0) {
      console.log('Violations critiques dashboard:', JSON.stringify(critical.map(v => ({
        id: v.id,
        impact: v.impact,
        description: v.description,
        nodes: v.nodes.length,
      })), null, 2));
    }
    expect(critical.length).toBeLessThanOrEqual(10);
  });

  test('Page missions — scan accessibilité', async ({ page }) => {
    await loginAs(page, 'admin');
    await page.goto('/missions');
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();

    const critical = results.violations.filter(v => v.impact === 'critical' || v.impact === 'serious');
    expect(critical.length).toBeLessThanOrEqual(10);
  });

  test('Formulaire nouvelle mission — scan accessibilité', async ({ page }) => {
    await loginAs(page, 'demandeur');

    const newBtn = page.locator('a:has-text("Nouvelle"), a[href*="nouvelle"]').first();
    if (await newBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
      await newBtn.click();
    } else {
      await page.goto('/missions/nouvelle');
    }
    await page.waitForLoadState('networkidle');

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();

    const critical = results.violations.filter(v => v.impact === 'critical' || v.impact === 'serious');
    expect(critical.length).toBeLessThanOrEqual(10);
  });
});
