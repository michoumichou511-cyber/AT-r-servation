<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Modification demandée</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Segoe UI',Arial,sans-serif;background:#F4F6FA;padding:30px 16px}
    .wrap{max-width:620px;margin:0 auto}
    .card{background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08)}
    .hdr{background:linear-gradient(135deg,#F39C12 0%,#003DA5 100%);padding:36px 32px;text-align:center}
    .hdr-icon{font-size:48px;display:block;margin-bottom:10px}
    .hdr h1{color:#fff;font-size:22px;font-weight:700}
    .hdr p{color:rgba(255,255,255,.8);font-size:13px;margin-top:6px}
    .body{padding:32px}
    .greeting{font-size:16px;color:#1A1D26;font-weight:600;margin-bottom:8px}
    .intro{font-size:14px;color:#5A6070;margin-bottom:24px;line-height:1.6}
    .warn-banner{background:#FFF8E1;border-left:4px solid #F39C12;border-radius:8px;padding:16px 20px;margin-bottom:24px}
    .warn-banner-title{font-size:13px;font-weight:700;color:#B07D00;margin-bottom:6px}
    .warn-banner-text{font-size:14px;color:#4A3800;line-height:1.5}
    .info-table{width:100%;border-collapse:collapse;margin-bottom:24px}
    .info-table tr{border-bottom:1px solid #F0F2F7}
    .info-table tr:last-child{border-bottom:none}
    .info-table td{padding:11px 6px;font-size:14px}
    .info-table td:first-child{color:#9AA0AE;width:42%}
    .info-table td:last-child{color:#1A1D26;font-weight:600;text-align:right}
    .btn{display:block;text-align:center;background:linear-gradient(135deg,#F39C12,#003DA5);color:#fff;text-decoration:none;padding:14px 28px;border-radius:8px;font-size:14px;font-weight:600;margin:24px 0 0}
    .note{font-size:12px;color:#9AA0AE;line-height:1.6;margin-top:20px;padding-top:16px;border-top:1px solid #F0F2F7}
    .footer{background:#F4F6FA;padding:18px 32px;text-align:center;font-size:11px;color:#9AA0AE}
  </style>
</head>
<body>
<div class="wrap">
  <div class="card">
    <div class="hdr">
      <span class="hdr-icon">🔄</span>
      <h1>Modification demandée</h1>
      <p>AT Réservations — Algérie Télécom</p>
    </div>
    <div class="body">
      <p class="greeting">Bonjour {{ $nomComplet ?: 'Collaborateur' }},</p>
      <p class="intro">Votre directeur a demandé des <strong>modifications</strong> sur votre demande de mission avant de pouvoir l'approuver. Veuillez prendre connaissance du commentaire ci-dessous et corriger votre demande.</p>

      @if($commentaire)
      <div class="warn-banner">
        <div class="warn-banner-title">🔄 Commentaire du directeur :</div>
        <div class="warn-banner-text">{{ $commentaire }}</div>
      </div>
      @endif

      <table class="info-table">
        <tr>
          <td>Référence</td>
          <td>{{ $mission->numero_unique ?? '—' }}</td>
        </tr>
        <tr>
          <td>Objet</td>
          <td>{{ $mission->titre ?? $mission->objet ?? '—' }}</td>
        </tr>
        <tr>
          <td>Destination</td>
          <td>{{ $mission->destination_ville ?? '—' }}{{ $mission->destination_pays ? ', '.$mission->destination_pays : '' }}</td>
        </tr>
        <tr>
          <td>Date départ</td>
          <td>{{ \Carbon\Carbon::parse($mission->date_depart)->format('d/m/Y') }}</td>
        </tr>
        <tr>
          <td>Date retour</td>
          <td>{{ \Carbon\Carbon::parse($mission->date_retour)->format('d/m/Y') }}</td>
        </tr>
      </table>

      <a href="{{ $appUrl }}/missions/{{ $mission->id }}" class="btn">Modifier ma demande →</a>

      <p class="note">Après avoir apporté les modifications demandées, soumettez à nouveau votre mission pour validation. Si vous avez des questions, contactez votre directeur.</p>
    </div>
    <div class="footer">AT Réservations · Algérie Télécom · Tous droits réservés</div>
  </div>
</div>
</body>
</html>
