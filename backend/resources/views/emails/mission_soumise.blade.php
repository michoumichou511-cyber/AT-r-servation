<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Votre mission a été soumise</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Segoe UI',Arial,sans-serif;background:#F4F6FA;padding:30px 16px}
    .wrap{max-width:620px;margin:0 auto}
    .card{background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08)}
    .hdr{background:linear-gradient(135deg,#003DA5 0%,#00A650 100%);padding:36px 32px;text-align:center}
    .hdr-icon{font-size:44px;display:block;margin-bottom:10px}
    .hdr h1{color:#fff;font-size:22px;font-weight:700;letter-spacing:.3px}
    .hdr p{color:rgba(255,255,255,.8);font-size:13px;margin-top:6px}
    .body{padding:32px}
    .greeting{font-size:16px;color:#1A1D26;font-weight:600;margin-bottom:8px}
    .intro{font-size:14px;color:#5A6070;margin-bottom:24px;line-height:1.6}
    .info-table{width:100%;border-collapse:collapse;margin-bottom:24px}
    .info-table tr{border-bottom:1px solid #F0F2F7}
    .info-table tr:last-child{border-bottom:none}
    .info-table td{padding:11px 6px;font-size:14px}
    .info-table td:first-child{color:#9AA0AE;width:42%}
    .info-table td:last-child{color:#1A1D26;font-weight:600;text-align:right}
    .badge{display:inline-block;padding:4px 14px;border-radius:20px;font-size:12px;font-weight:700}
    .badge-pending{background:#FFF3CD;color:#B08000}
    .badge-ok{background:#E6F7EE;color:#00A650}
    .btn{display:block;text-align:center;background:linear-gradient(135deg,#003DA5,#00A650);color:#fff;text-decoration:none;padding:14px 28px;border-radius:8px;font-size:14px;font-weight:600;margin:24px 0 0}
    .note{font-size:12px;color:#9AA0AE;line-height:1.6;margin-top:20px;padding-top:16px;border-top:1px solid #F0F2F7}
    .footer{background:#F4F6FA;padding:18px 32px;text-align:center;font-size:11px;color:#9AA0AE}
  </style>
</head>
<body>
<div class="wrap">
  <div class="card">
    <div class="hdr">
      <span class="hdr-icon">📋</span>
      <h1>Mission soumise avec succès</h1>
      <p>AT Réservations — Algérie Télécom</p>
    </div>
    <div class="body">
      <p class="greeting">Bonjour {{ $nomComplet ?: 'Collaborateur' }},</p>
      <p class="intro">Votre demande de mission a bien été soumise et est en attente de validation par votre directeur. Vous serez notifié par e-mail dès qu'une décision sera prise.</p>

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
        <tr>
          <td>Statut</td>
          <td><span class="badge badge-pending">⏳ En attente</span></td>
        </tr>
      </table>

      <a href="{{ $appUrl }}/missions/{{ $mission->id }}" class="btn">Suivre ma mission →</a>

      <p class="note">Si vous n'avez pas soumis cette mission, veuillez contacter votre administrateur immédiatement.</p>
    </div>
    <div class="footer">AT Réservations · Algérie Télécom · Tous droits réservés</div>
  </div>
</div>
</body>
</html>
