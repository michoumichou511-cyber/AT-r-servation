<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #F4F6FA;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background: white;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .header {
      background: linear-gradient(135deg,
        #003DA5, #00A650);
      padding: 30px;
      text-align: center;
    }
    .header h1 {
      color: white;
      margin: 0;
      font-size: 22px;
    }
    .header p {
      color: rgba(255,255,255,0.8);
      margin: 8px 0 0;
      font-size: 14px;
    }
    .body {
      padding: 30px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #EAECF0;
      font-size: 14px;
    }
    .info-label {
      color: #9AA0AE;
      font-weight: 500;
    }
    .info-value {
      color: #1A1D26;
      font-weight: 600;
    }
    .btn {
      display: inline-block;
      background: linear-gradient(135deg,
        #00A650, #003DA5);
      color: white;
      padding: 12px 24px;
      border-radius: 8px;
      text-decoration: none;
      font-weight: 600;
      margin-top: 20px;
    }
    .footer {
      background: #F4F6FA;
      padding: 20px 30px;
      text-align: center;
      font-size: 12px;
      color: #9AA0AE;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔔 Nouvelle mission à valider</h1>
      <p>AT Réservations — Algérie Télécom</p>
    </div>
    <div class="body">
      <p style="color:#1A1D26;font-size:16px">
        Bonjour,
      </p>
      <p style="color:#5A6070;font-size:14px">
        Une nouvelle demande de mission
        nécessite votre validation.
      </p>

      <div style="margin:20px 0">
        <div class="info-row">
          <span class="info-label">
            Référence
          </span>
          <span class="info-value">
            {{ $mission->numero_unique ?? $mission->reference ?? '—' }}
          </span>
        </div>
        <div class="info-row">
          <span class="info-label">
            Demandeur
          </span>
          <span class="info-value">
            {{ $demandeur->prenom ?? '' }}
            {{ $demandeur->nom ?? '' }}
          </span>
        </div>
        <div class="info-row">
          <span class="info-label">
            Destination
          </span>
          <span class="info-value">
            {{ $mission->destination_ville ?? $mission->destination ?? '—' }},
            {{ $mission->destination_pays ?? '—' }}
          </span>
        </div>
        <div class="info-row">
          <span class="info-label">
            Dates
          </span>
          <span class="info-value">
            {{ $mission->date_depart }}
            →
            {{ $mission->date_retour }}
          </span>
        </div>
        <div class="info-row">
          <span class="info-label">
            Budget prévisionnel
          </span>
          <span class="info-value">
            {{ number_format(
              (float) ($mission->budget_previsionnel ?? 0),
              0, ',', ' ') }} DZD
          </span>
        </div>
      </div>

      <center>
        <a href="{{ config('app.url') }}/validations"
          class="btn">
          Voir et valider la mission →
        </a>
      </center>
    </div>
    <div class="footer">
      <p>
        AT Réservations — Algérie Télécom
      </p>
      <p>
        Cet email a été envoyé
        automatiquement.
      </p>
    </div>
  </div>
</body>
</html>
