<!doctype html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Test /api/register</title>
    <style>
        body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; margin: 24px; line-height: 1.35; }
        .wrap { max-width: 820px; margin: 0 auto; }
        .card { border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; }
        .row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        label { display:block; font-size: 12px; color: #374151; margin-bottom: 6px; }
        input { width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 10px; font-size: 14px; }
        button { padding: 10px 14px; border: 0; border-radius: 10px; background: #111827; color: white; cursor: pointer; }
        button:disabled { opacity: .6; cursor: not-allowed; }
        pre { background: #0b1020; color: #e5e7eb; padding: 12px; border-radius: 12px; overflow: auto; }
        .muted { color: #6b7280; font-size: 13px; }
        .top { display:flex; align-items: baseline; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
        a { color: #2563eb; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .status { font-weight: 600; }
    </style>
</head>
<body>
<div class="wrap">
    <div class="top">
        <h2>Formulaire de test — <code>POST /api/register</code></h2>
        <div class="muted">
            Tu peux aussi ouvrir <a href="/api/register" target="_blank" rel="noreferrer">/api/register</a> (GET) pour voir l’aide/les rôles.
        </div>
    </div>

    <div class="card">
        <form id="form">
            <div class="row">
                <div>
                    <label for="role_id">role_id</label>
                    <input id="role_id" name="role_id" type="number" value="1" min="1" required>
                </div>
                <div>
                    <label for="name">name</label>
                    <input id="name" name="name" type="text" value="User Chrome" required>
                </div>
                <div>
                    <label for="email">email</label>
                    <input id="email" name="email" type="email" value="chrome_user@example.com" required>
                </div>
                <div>
                    <label for="password">password</label>
                    <input id="password" name="password" type="text" value="secret123" required>
                </div>
            </div>

            <div style="margin-top: 12px; display:flex; gap: 10px; align-items: center; flex-wrap: wrap;">
                <button id="btn" type="submit">Créer le compte (POST)</button>
                <span id="status" class="status muted"></span>
            </div>
        </form>
    </div>

    <h3 style="margin-top: 18px;">Résultat</h3>
    <pre id="out">{}</pre>
</div>

<script>
    const form = document.getElementById('form');
    const out = document.getElementById('out');
    const statusEl = document.getElementById('status');
    const btn = document.getElementById('btn');

    function setStatus(text) {
        statusEl.textContent = text || '';
    }

    function pretty(obj) {
        return JSON.stringify(obj, null, 2);
    }

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        btn.disabled = true;
        setStatus('Envoi...');
        out.textContent = '{}';

        const payload = {
            role_id: Number(document.getElementById('role_id').value),
            name: document.getElementById('name').value,
            email: document.getElementById('email').value,
            password: document.getElementById('password').value,
        };

        try {
            const res = await fetch('/api/register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                body: JSON.stringify(payload),
            });

            let body;
            const ct = res.headers.get('content-type') || '';
            if (ct.includes('application/json')) {
                body = await res.json();
            } else {
                body = { raw: await res.text() };
            }

            setStatus(`HTTP ${res.status}`);
            out.textContent = pretty(body);
        } catch (err) {
            setStatus('Erreur');
            out.textContent = pretty({ error: String(err) });
        } finally {
            btn.disabled = false;
        }
    });
</script>
</body>
</html>

