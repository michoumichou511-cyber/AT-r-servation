<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Mission approuvée</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Segoe UI',Arial,sans-serif;background:#F4F6FA;padding:30px 16px}
    .wrap{max-width:620px;margin:0 auto}
    .card{background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08)}
    .hdr{background:linear-gradient(135deg,#00A650 0%,#003DA5 100%);padding:36px 32px;text-align:center}
    .hdr-icon{font-size:48px;display:block;margin-bottom:10px}
    .hdr h1{color:#fff;font-size:22px;font-weight:700}
    .hdr p{color:rgba(255,255,255,.8);font-size:13px;margin-top:6px}
    .body{padding:32px}
    .greeting{font-size:16px;color:#1A1D26;font-weight:600;margin-bottom:8px}
    .intro{font-size:14px;color:#5A6070;margin-bottom:24px;line-height:1.6}
    .success-banner{background:#E6F7EE;border-left:4px solid #00A650;border-radius:8px;padding:16px 20px;margin-bottom:24px;font-size:14px;color:#1A6635;font-weight:600}
    .info-table{width:100%;border-collapse:collapse;margin-bottom:24px}
    .info-table tr{border-bottom:1px solid #F0F2F7}
    .info-table tr:last-child{border-bottom:none}
    .info-table td{padding:11px 6px;font-size:14px}
    .info-table td:first-child{color:#9AA0AE;width:42%}
    .info-table td:last-child{color:#1A1D26;font-weight:600;text-align:right}
    .btn{display:block;text-align:center;background:linear-gradient(135deg,#00A650,#003DA5);color:#fff;text-decoration:none;padding:14px 28px;border-radius:8px;font-size:14px;font-weight:600;margin:24px 0 0}
    .note{font-size:12px;color:#9AA0AE;line-height:1.6;margin-top:20px;padding-top:16px;border-top:1px solid #F0F2F7}
    .footer{background:#F4F6FA;padding:18px 32px;text-align:center;font-size:11px;color:#9AA0AE}
  </style>
</head>
<body>
<div class="wrap">
  <div class="card">
    <div class="hdr">
      <span class="hdr-icon">✅</span>
      <h1>Mission approuvée !</h1>
      <p>AT Réservations — Algérie Télécom</p>
    </div>
    <div class="body">
      <p class="greeting">Bonjour {{ $nomComplet ?: 'Collaborateur' }},</p>
      <p class="intro">Bonne nouvelle ! Votre demande de mission a été examinée et <strong>approuvée</strong> par votre directeur. La logistique sera bientôt prise en charge par l'équipe DML.</p>

      <div class="success-banner">✅ Votre mission est officiellement approuvée</div>

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

      <a href="{{ $appUrl }}/missions/{{ $mission->id }}" class="btn">Voir ma mission →</a>

      <p class="note">Prochaine étape : l'équipe DML prendra en charge l'hébergement et le transport. Vous recevrez un e-mail de confirmation dès que la logistique est confirmée.</p>
    </div>
    <div class="footer">AT Réservations · Algérie Télécom · Tous droits réservés</div>
  </div>
</div>
</body>
</html>
