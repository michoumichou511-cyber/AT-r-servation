import { Page, expect } from '@playwright/test';

export const CREDENTIALS = {
  admin: {
    email: 'admin@at.dz',
    password: 'Password@123',
    role: 'admin',
    name: 'Admin',
  },
  validateur: {
    email: 'nadia.khelifi@at.dz',
    password: 'Password@123',
    role: 'validateur',
    name: 'Nadia Khelifi',
  },
  demandeur: {
    email: 'demandeur@at.dz',
    password: 'Password@123',
    role: 'demandeur',
    name: 'Demandeur Test',
  },
} as const;

export type RoleName = keyof typeof CREDENTIALS;

export async function loginAs(page: Page, role: RoleName) {
  const creds = CREDENTIALS[role];
  await page.goto('/login');

  const emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="@"]').first();
  await emailInput.waitFor({ state: 'visible', timeout: 30000 });

  await emailInput.fill(creds.email);
  const passwordInput = page.locator('input[type="password"]').first();
  await passwordInput.fill(creds.password);

  const submitBtn = page.locator('button:has-text("Se connecter"), button[type="submit"]').first();
  await submitBtn.click();

  await page.waitForFunction(
    () => !window.location.pathname.includes('/login'),
    { timeout: 30000 }
  );
  await page.waitForLoadState('domcontentloaded');
  await page.waitForTimeout(2000);
}

export async function logout(page: Page) {
  await page.evaluate(() => {
    localStorage.removeItem('at_token');
  });
  await page.goto('/login');
  await page.waitForLoadState('domcontentloaded');
}
