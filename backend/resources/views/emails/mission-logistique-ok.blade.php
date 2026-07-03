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
      <h1>🧳 Logistique confirmée</h1>
      <p>AT Réservations — Algérie Télécom</p>
    </div>
    <div class="body">
      <p>Bonjour {{ $mission->user->prenom ?? '' }},</p>
      <p>
        Le service DML a finalisé la logistique de votre mission
        <strong>{{ $mission->numero_unique ?? $mission->id }}</strong>
        (« {{ $mission->titre }} »).
      </p>

      <div class="info-row">
        <span>Statut logistique</span>
        <span class="badge">Confirmée</span>
      </div>
      @if ($traitement->hotel)
      <div class="info-row">
        <span>Hôtel</span>
        <strong>{{ $traitement->hotel->nom }} ({{ $traitement->hotel->ville }})</strong>
      </div>
      @elseif ($traitement->hotel_nom_libre)
      <div class="info-row">
        <span>Hôtel</span>
        <strong>{{ $traitement->hotel_nom_libre }}</strong>
      </div>
      @endif
      @if ($traitement->vehicule)
      <div class="info-row">
        <span>Véhicule</span>
        <strong>{{ $traitement->vehicule->marque }} {{ $traitement->vehicule->modele }} — {{ $traitement->vehicule->immatriculation }}</strong>
      </div>
      @endif
      @if ($traitement->type_transport)
      <div class="info-row">
        <span>Transport</span>
        <strong>{{ ucfirst(str_replace('_', ' ', $traitement->type_transport)) }}</strong>
      </div>
      @endif
      @if ($traitement->numero_bon)
      <div class="info-row">
        <span>N° de bon</span>
        <strong>{{ $traitement->numero_bon }}</strong>
      </div>
      @endif
      @if ($traitement->observations)
      <div class="info-row">
        <span>Observations</span>
        <span>{{ $traitement->observations }}</span>
      </div>
      @endif

      <p style="margin-top:20px">
        Retrouvez tous les détails dans la fiche de votre mission.
      </p>
    </div>
    <div class="footer">
      AT Réservations — message automatique, merci de ne pas répondre.
    </div>
  </div>
</body>
</html>
