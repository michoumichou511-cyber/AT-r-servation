// Capture isolée de figure19 (validations) après reset du throttle
const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const OUT = 'C:/Users/loulou/ProjetFinFormation/captures_memoire';
const APP = 'http://localhost:5173';
const VIEWPORT = { width: 1440, height: 900 };

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu'],
    defaultViewport: VIEWPORT,
  });

  const page = await browser.newPage();
  await page.setViewport(VIEWPORT);

  await page.goto(`${APP}/login`, { waitUntil: 'networkidle2', timeout: 30000 });
  await new Promise((r) => setTimeout(r, 1500));

  const token = await page.evaluate(async () => {
    const r = await fetch('http://127.0.0.1:8000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ email: 'validateur@at.dz', password: 'Password@123' }),
    });
    const d = await r.json();
    if (!d.success) throw new Error('Login failed: ' + JSON.stringify(d));
    return d.data.token;
  });

  const user = await page.evaluate(async (t) => {
    const r = await fetch('http://127.0.0.1:8000/api/auth/me', {
      headers: { Authorization: 'Bearer ' + t, Accept: 'application/json' },
    });
    const d = await r.json();
    return d.data.user || d.data;
  }, token);

  await page.evaluate(({ token, user }) => {
    sessionStorage.setItem('at_token', token);
    sessionStorage.setItem('at_user', JSON.stringify(user));
    sessionStorage.setItem('at_auth_method', 'db');
  }, { token, user });

  await page.goto(`${APP}/validations`, { waitUntil: 'networkidle2' });
  await new Promise((r) => setTimeout(r, 5000));
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({ path: path.join(OUT, 'figure19.png'), fullPage: false });
  console.log('OK figure19');

  await browser.close();
})().catch((e) => {
  console.error('ERROR:', e.message);
  process.exit(1);
});
