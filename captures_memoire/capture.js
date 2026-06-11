// Capture des 5 figures du memoire via Puppeteer + Chrome existant
const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const OUT = 'C:/Users/loulou/ProjetFinFormation/captures_memoire';

const APP = 'http://localhost:5173';
const VIEWPORT = { width: 1440, height: 900 };

async function loginAs(page, role) {
  const accounts = {
    admin:      { email: 'admin@at.dz', pwd: 'Password@123' },
    dml:        { email: 'agent.dml@at.dz', pwd: 'Password@123' },
    demandeur:  { email: 'demandeur@at.dz', pwd: 'Password@123' },
    validateur: { email: 'validateur@at.dz', pwd: 'Password@123' },
  };
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
    sessionStorage.setItem('at_token', token);
    sessionStorage.setItem('at_user', JSON.stringify(user));
    sessionStorage.setItem('at_auth_method', 'db');
  }, { token, user });
}

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu'],
    defaultViewport: VIEWPORT
  });

  // FIGURE 13 - Login
  {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    await page.goto(`${APP}/login`, { waitUntil: 'networkidle2', timeout: 30000 });
    await new Promise(r => setTimeout(r, 3000));
    await page.screenshot({ path: path.join(OUT, 'figure13.png'), fullPage: false });
    console.log('OK figure13');
    await page.close();
  }

  // FIGURE 14 - Dashboard admin
  {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    await loginAs(page, 'admin');
    await page.goto(`${APP}/`, { waitUntil: 'networkidle2' });
    await new Promise(r => setTimeout(r, 5000));
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.screenshot({ path: path.join(OUT, 'figure14.png'), fullPage: false });
    console.log('OK figure14');
    await page.close();
  }

  // FIGURE 15 - Organigramme
  {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    await loginAs(page, 'admin');
    await page.goto(`${APP}/organigramme`, { waitUntil: 'networkidle2' });
    await new Promise(r => setTimeout(r, 5000));
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.screenshot({ path: path.join(OUT, 'figure15.png'), fullPage: false });
    console.log('OK figure15');
    await page.close();
  }

  // FIGURE 16 - Wizard
  {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    await loginAs(page, 'admin');
    await page.goto(`${APP}/missions/nouvelle`, { waitUntil: 'networkidle2' });
    await new Promise(r => setTimeout(r, 3000));
    await page.evaluate(() => {
      const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
      const taSetter = Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value').set;
      const fill = (el, v) => {
        if (el.tagName === 'TEXTAREA') taSetter.call(el, v);
        else if (el.tagName === 'SELECT') el.value = v;
        else setter.call(el, v);
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
      };
      document.querySelectorAll('input, textarea, select').forEach(el => {
        const ph = (el.placeholder || '').toLowerCase();
        const lbl = (el.previousElementSibling?.textContent || el.labels?.[0]?.textContent || '').toLowerCase();
        if (ph.includes('titre') || lbl.includes('titre')) fill(el, "Formation Cybersecurite DSI Algerie Telecom");
        else if (ph.includes('objet') || lbl.includes('objet')) fill(el, "Formation sur les bonnes pratiques de cybersecurite pour les agents DSI");
        else if (ph.includes('ville') && ph.includes('destination')) fill(el, 'Constantine');
        else if (ph.includes('pays')) fill(el, 'Algerie');
        else if (el.type === 'date' && (lbl.includes('depart'))) fill(el, '2026-06-15');
        else if (el.type === 'date' && (lbl.includes('retour'))) fill(el, '2026-06-19');
        else if (ph.includes('budget') || lbl.includes('budget')) fill(el, '85000');
        else if (ph.includes('details') || lbl.includes('description')) fill(el, "Session intensive de 4 jours pour 12 agents.");
      });
      document.querySelectorAll('select').forEach(s => {
        const lbl = (s.previousElementSibling?.textContent || '').toLowerCase();
        if (lbl.includes('type') && s.options.length > 1) { s.value = 'formation'; s.dispatchEvent(new Event('change', { bubbles: true })); }
        if (lbl.includes('priorit') && s.options.length > 1) { s.value = 'normale'; s.dispatchEvent(new Event('change', { bubbles: true })); }
      });
    });
    await new Promise(r => setTimeout(r, 1500));
    await page.evaluate(() => window.scrollTo(0, 0));
    await new Promise(r => setTimeout(r, 500));
    await page.screenshot({ path: path.join(OUT, 'figure16.png'), fullPage: false });
    console.log('OK figure16');
    await page.close();
  }

  // FIGURE 17 - DML dashboard
  {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    await loginAs(page, 'dml');
    await page.goto(`${APP}/dml`, { waitUntil: 'networkidle2' });
    await new Promise(r => setTimeout(r, 5000));
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.screenshot({ path: path.join(OUT, 'figure17.png'), fullPage: false });
    console.log('OK figure17');
    await page.close();
  }

  // FIGURE 18 - Messagerie (demandeur)
  {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    await loginAs(page, 'demandeur');
    await page.goto(`${APP}/messagerie`, { waitUntil: 'networkidle2' });
    await new Promise(r => setTimeout(r, 5000));
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.screenshot({ path: path.join(OUT, 'figure18.png'), fullPage: false });
    console.log('OK figure18');
    await page.close();
  }

  // FIGURE 19 - Validations (validateur)
  {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    await loginAs(page, 'validateur');
    await page.goto(`${APP}/validations`, { waitUntil: 'networkidle2' });
    await new Promise(r => setTimeout(r, 5000));
    await page.evaluate(() => window.scrollTo(0, 0));
    await page.screenshot({ path: path.join(OUT, 'figure19.png'), fullPage: false });
    console.log('OK figure19');
    await page.close();
  }

  await browser.close();
  console.log('=== 7 CAPTURES DONE ===');
})().catch(e => {
  console.error('ERROR:', e.message);
  console.error(e.stack);
  process.exit(1);
});
