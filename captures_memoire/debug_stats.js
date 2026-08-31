// Reproduire l'erreur de la page Statistiques et afficher la console
const puppeteer = require('puppeteer-core');

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const APP = 'http://localhost:5173';

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME, headless: 'new',
    args: ['--no-sandbox', '--disable-gpu'],
    defaultViewport: { width: 1440, height: 900 }
  });
  const page = await browser.newPage();
  page.on('console', m => { if (['error','warning'].includes(m.type())) console.log('[console]', m.type(), m.text().slice(0, 400)); });
  page.on('pageerror', e => console.log('[pageerror]', e.message.slice(0, 600)));
  page.on('requestfailed', r => console.log('[reqfail]', r.url().slice(0, 120)));
  page.on('response', r => { if (r.status() >= 400) console.log('[http]', r.status(), r.url().slice(0, 120)); });

  await page.goto(`${APP}/login`, { waitUntil: 'networkidle2', timeout: 30000 });
  await new Promise(r => setTimeout(r, 1500));
  const token = await page.evaluate(async () => {
    const r = await fetch('http://127.0.0.1:8000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ email: 'admin@at.dz', password: 'Password@123' })
    });
    const d = await r.json();
    return d.data.token;
  });
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
  }, { token, user });

  await page.goto(`${APP}/admin/statistiques`, { waitUntil: 'networkidle2', timeout: 45000 });
  await new Promise(r => setTimeout(r, 6000));
  const hasError = await page.evaluate(() =>
    document.body.innerText.includes("problème d'affichage"));
  console.log('ERREUR AFFICHEE:', hasError);
  await browser.close();
})();
