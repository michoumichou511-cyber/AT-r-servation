// Captures du Chapitre III — 15 figures (fig2 à fig16)
const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const OUT = 'C:/Users/loulou/ProjetFinFormation/captures_memoire/chap3';
const APP = 'http://localhost:5173';
const VIEWPORT = { width: 1440, height: 900 };

const accounts = {
  admin:      { email: 'admin@at.dz', pwd: 'Password@123' },
  dml:        { email: 'agent.dml@at.dz', pwd: 'Password@123' },
  demandeur:  { email: 'demandeur@at.dz', pwd: 'Password@123' },
  validateur: { email: 'validateur@at.dz', pwd: 'Password@123' },
};

async function loginAs(page, role) {
  const acc = accounts[role];
  await page.goto(`${APP}/login`, { waitUntil: 'networkidle2', timeout: 30000 });
  await new Promise(r => setTimeout(r, 1500));
  const token = await page.evaluate(async (acc) => {
    const r = await fetch('http://127.0.0.1:8000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ email: acc.email, password: acc.pwd })
    });
    const d = await r.json();
    if (!d.success) throw new Error('Login failed: ' + JSON.stringify(d));
    return d.data.token;
  }, acc);
  const user = await page.evaluate(async (token) => {
    const r = await fetch('http://127.0.0.1:8000/api/auth/me', {
      headers: { 'Authorization': 'Bearer ' + token, 'Accept': 'application/json' }
    });
    const d = await r.json();
    return d.data.user || d.data;
  }, token);
  await page.evaluate(({ token, user }) => {
    localStorage.setItem('at_token', token);
    localStorage.setItem('at_user', JSON.stringify(user));
    localStorage.setItem('at_auth_method', 'db');
    sessionStorage.setItem('at_token', token);
    sessionStorage.setItem('at_user', JSON.stringify(user));
  }, { token, user });
}

async function shot(browser, name, role, url, waitMs = 5000) {
  const page = await browser.newPage();
  await page.setViewport(VIEWPORT);
  try {
    if (role) await loginAs(page, role);
    await page.goto(`${APP}${url}`, { waitUntil: 'networkidle2', timeout: 45000 });
    await new Promise(r => setTimeout(r, waitMs));
    await page.evaluate(() => window.scrollTo(0, 0));
    await new Promise(r => setTimeout(r, 500));
    const finalUrl = page.url();
    await page.screenshot({ path: path.join(OUT, name + '.png'), fullPage: false });
    console.log(`OK ${name}  (${finalUrl})`);
  } catch (e) {
    console.log(`FAIL ${name}: ${e.message}`);
  }
  await page.close();
}

(async () => {
  const fs = require('fs');
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu'],
    defaultViewport: VIEWPORT
  });

  // capture sans login
  await shot(browser, 'fig03_login', null, '/login', 3000);

  // une session par role — un seul login chacun
  const plans = [
    ['admin', [
      ['fig02_trame', '/missions'],
      ['fig04_dash_admin', '/'],
      ['fig08_utilisateurs', '/admin/utilisateurs'],
      ['fig12_conventions', '/admin/prestataires'],
      ['fig13_vehicules', '/admin/budgets'],
      ['fig14_statistiques', '/admin/statistiques'],
      ['fig15_messagerie', '/messagerie'],
      ['fig16_organigramme', '/organigramme'],
    ]],
    ['validateur', [
      ['fig05_dash_directeur', '/'],
      ['fig10_validations', '/validations'],
    ]],
    ['demandeur', [
      ['fig06_dash_demandeur', '/'],
      ['fig09_creation_mission', '/missions/nouvelle'],
    ]],
    ['dml', [
      ['fig07_dash_dml', '/'],
      ['fig11_dml_logistique', '/dml'],
    ]],
  ];
  for (const [role, pages] of plans) {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    try {
      await loginAs(page, role);
      for (const [name, url] of pages) {
        await page.goto(`${APP}${url}`, { waitUntil: 'networkidle2', timeout: 45000 });
        await new Promise(r => setTimeout(r, 5000));
        await page.evaluate(() => window.scrollTo(0, 0));
        await new Promise(r => setTimeout(r, 500));
        await page.screenshot({ path: path.join(OUT, name + '.png'), fullPage: false });
        console.log(`OK ${name}  (${page.url()})`);
      }
    } catch (e) { console.log(`FAIL role ${role}: ${e.message}`); }
    await page.close();
    await new Promise(r => setTimeout(r, 15000)); // throttle login 5/min
  }

  await browser.close();
  console.log('TERMINE');
})();
