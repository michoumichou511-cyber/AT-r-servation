<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family:Arial,sans-serif;
      background:#F4F6FA;margin:0;padding:20px}
    .container { max-width:600px;margin:0 auto;
      background:white;border-radius:12px;
      overflow:hidden;
      box-shadow:0 2px 8px rgba(0,0,0,0.1)}
    .header { background:linear-gradient(
      135deg,#00A650,#003DA5);
      padding:30px;text-align:center}
    .header h1 { color:white;margin:0;
      font-size:22px}
    .header p { color:rgba(255,255,255,0.8);
      margin:8px 0 0;font-size:14px}
    .body { padding:30px}
    .info-row { display:flex;
      justify-content:space-between;
      padding:10px 0;
      border-bottom:1px solid #EAECF0;
      font-size:14px}
    .badge { background:#E6F7EE;
      color:#00A650;padding:4px 12px;
      border-radius:20px;font-weight:700;
      font-size:13px}
    .footer { background:#F4F6FA;
      padding:20px 30px;text-align:center;
      font-size:12px;color:#9AA0AE}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>✅ Mission approuvée !</h1>
      <p>AT Réservations — Algérie Télécom</p>
    </div>
    <div class="body">
      <p style="color:#1A1D26;font-size:16px">
        Bonjour {{ optional($mission->user)->prenom ?? '—' }},
      </p>
      <p style="color:#5A6070;font-size:14px">
        Votre demande de mission a été
        <span class="badge">✅ APPROUVÉE</span>
      </p>

      <div style="margin:20px 0">
        <div class="info-row">
          <span style="color:#9AA0AE">
            Référence
          </span>
          <span style="font-weight:600">
            {{ $mission->numero_unique ?? $mission->reference ?? '—' }}
          </span>
        </div>
        <div class="info-row">
          <span style="color:#9AA0AE">
            Destination
          </span>
          <span style="font-weight:600">
            {{ $mission->destination_ville ?? $mission->destination ?? '—' }},
            {{ $mission->destination_pays ?? '—' }}
          </span>
        </div>
        <div class="info-row">
          <span style="color:#9AA0AE">
            Dates
          </span>
          <span style="font-weight:600">
            {{ $mission->date_depart }}
            →
            {{ $mission->date_retour }}
          </span>
        </div>
      </div>

      <p style="color:#5A6070;font-size:14px">
        Vous pouvez consulter les détails
        et vos bons de commande dans
        l'application.
      </p>
    </div>
    <div class="footer">
      AT Réservations — Algérie Télécom
    </div>
  </div>
</body>
</html>
