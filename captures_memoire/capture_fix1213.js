// Recaptures fig12 (hotels/conventions) et fig13 (modale DML hotel+vehicule)
const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const OUT = 'C:/Users/loulou/ProjetFinFormation/captures_memoire/chap3';
const APP = 'http://localhost:5173';
const VIEWPORT = { width: 1440, height: 900 };

async function loginAs(page, email) {
  await page.goto(`${APP}/login`, { waitUntil: 'networkidle2', timeout: 30000 });
  await new Promise(r => setTimeout(r, 1500));
  const token = await page.evaluate(async (email) => {
    const r = await fetch('http://127.0.0.1:8000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ email, password: 'Password@123' })
    });
    const d = await r.json();
    if (!d.success) throw new Error('Login failed: ' + JSON.stringify(d));
    return d.data.token;
  }, email);
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
}

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME, headless: 'new',
    args: ['--no-sandbox', '--disable-gpu'], defaultViewport: VIEWPORT
  });

  // fig12 : prestataires, section Hotels
  {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    await loginAs(page, 'admin@at.dz');
    await page.goto(`${APP}/admin/prestataires`, { waitUntil: 'networkidle2', timeout: 45000 });
    await new Promise(r => setTimeout(r, 5000));
    // scroller jusqu'a la premiere carte "Hôtel"
    await page.evaluate(() => {
      const el = [...document.querySelectorAll('*')].find(e =>
        e.children.length === 0 && e.textContent.trim() === 'Hôtel');
      if (el) el.scrollIntoView({ block: 'start' });
    });
    await new Promise(r => setTimeout(r, 1500));
    await page.screenshot({ path: path.join(OUT, 'fig12_conventions.png') });
    console.log('OK fig12 (hotels)');
    await page.close();
  }
  await new Promise(r => setTimeout(r, 15000));

  // fig13 : DML — modale Traiter (hotel + vehicule)
  {
    const page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    await loginAs(page, 'agent.dml@at.dz');
    await page.goto(`${APP}/dml`, { waitUntil: 'networkidle2', timeout: 45000 });
    await new Promise(r => setTimeout(r, 5000));
    let clicked = null;
    for (let t = 0; t < 10 && !clicked; t++) {
      clicked = await page.evaluate(() => {
        const btn = [...document.querySelectorAll('button')].find(b =>
          b.textContent.trim() === 'Traiter');
        if (btn) { btn.click(); return btn.textContent.trim(); }
        return null;
      });
      if (!clicked) await new Promise(r => setTimeout(r, 2000));
    }
    console.log('bouton clique:', clicked);
    await new Promise(r => setTimeout(r, 3000));
    const picked = await page.evaluate(() => {
      const sel = [...document.querySelectorAll('select')].find(s =>
        [...s.options].some(o => o.value === 'vehicule_service'));
      if (!sel) return null;
      const setter = Object.getOwnPropertyDescriptor(window.HTMLSelectElement.prototype, 'value').set;
      setter.call(sel, 'vehicule_service');
      sel.dispatchEvent(new Event('change', { bubbles: true }));
      return 'vehicule_service';
    });
    console.log('transport choisi:', picked);
    await new Promise(r => setTimeout(r, 2500));
    await page.screenshot({ path: path.join(OUT, 'fig13_vehicules.png') });
    console.log('OK fig13 (modale DML)');
    await page.close();
  }

  await browser.close();
  console.log('TERMINE');
})();
