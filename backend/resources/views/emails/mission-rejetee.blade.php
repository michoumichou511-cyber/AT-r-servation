<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family:Arial,sans-serif;
      background:#F4F6FA;margin:0;padding:20px}
    .container { max-width:600px;margin:0 auto;
      background:white;border-radius:12px;
      overflow:hidden}
    .header { background:linear-gradient(
      135deg,#EF4444,#B91C1C);
      padding:30px;text-align:center}
    .header h1 { color:white;margin:0;
      font-size:22px}
    .motif { background:#FEF2F2;
      border-left:4px solid #EF4444;
      padding:16px;border-radius:4px;
      margin:16px 0}
    .footer { background:#F4F6FA;
      padding:20px;text-align:center;
      font-size:12px;color:#9AA0AE}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>❌ Mission rejetée</h1>
    </div>
    <div style="padding:30px">
      <p style="color:#1A1D26">
        Bonjour {{ optional($mission->user)->prenom ?? '—' }},
      </p>
      <p style="color:#5A6070;font-size:14px">
        Votre demande de mission
        <strong>
          {{ $mission->numero_unique ?? $mission->reference ?? '—' }}
        </strong>
        a été rejetée.
      </p>
      @if($motif)
      <div class="motif">
        <p style="color:#B91C1C;font-weight:600;
          margin:0 0 8px">
          Motif du rejet :
        </p>
        <p style="color:#1A1D26;margin:0">
          {{ $motif }}
        </p>
      </div>
      @endif
      <p style="color:#5A6070;font-size:14px">
        Vous pouvez modifier votre demande
        et la resoumettre.
      </p>
    </div>
    <div class="footer">
      AT Réservations — Algérie Télécom
    </div>
  </div>
</body>
</html>
