<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Logistique confirmée</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Segoe UI',Arial,sans-serif;background:#F4F6FA;padding:30px 16px}
    .wrap{max-width:620px;margin:0 auto}
    .card{background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08)}
    .hdr{background:linear-gradient(135deg,#003DA5 0%,#00A650 100%);padding:36px 32px;text-align:center}
    .hdr-icon{font-size:48px;display:block;margin-bottom:10px}
    .hdr h1{color:#fff;font-size:22px;font-weight:700}
    .hdr p{color:rgba(255,255,255,.8);font-size:13px;margin-top:6px}
    .body{padding:32px}
    .greeting{font-size:16px;color:#1A1D26;font-weight:600;margin-bottom:8px}
    .intro{font-size:14px;color:#5A6070;margin-bottom:24px;line-height:1.6}
    .success-banner{background:#E6F7EE;border-left:4px solid #00A650;border-radius:8px;padding:16px 20px;margin-bottom:24px;font-size:14px;color:#1A6635;font-weight:600}
    .section-title{font-size:13px;font-weight:700;color:#003DA5;text-transform:uppercase;letter-spacing:.5px;margin-bottom:12px;padding-bottom:6px;border-bottom:2px solid #003DA520}
    .logistic-block{background:#F8FAFF;border-radius:10px;padding:18px;margin-bottom:20px}
    .info-table{width:100%;border-collapse:collapse}
    .info-table tr{border-bottom:1px solid #EAECF0}
    .info-table tr:last-child{border-bottom:none}
    .info-table td{padding:10px 6px;font-size:14px}
    .info-table td:first-child{color:#9AA0AE;width:45%}
    .info-table td:last-child{color:#1A1D26;font-weight:600;text-align:right}
    .mission-block{background:#F8F9FC;border-radius:10px;padding:18px;margin-bottom:24px}
    .btn{display:block;text-align:center;background:linear-gradient(135deg,#003DA5,#00A650);color:#fff;text-decoration:none;padding:14px 28px;border-radius:8px;font-size:14px;font-weight:600;margin:24px 0 0}
    .note{font-size:12px;color:#9AA0AE;line-height:1.6;margin-top:20px;padding-top:16px;border-top:1px solid #F0F2F7}
    .footer{background:#F4F6FA;padding:18px 32px;text-align:center;font-size:11px;color:#9AA0AE}
  </style>
</head>
<body>
<div class="wrap">
  <div class="card">
    <div class="hdr">
      <span class="hdr-icon">🚀</span>
      <h1>Logistique confirmée !</h1>
      <p>AT Réservations — Algérie Télécom</p>
    </div>
    <div class="body">
      <p class="greeting">Bonjour {{ $nomComplet ?: 'Collaborateur' }},</p>
      <p class="intro">Votre mission est prête ! L'équipe DML a finalisé tous les arrangements logistiques. Voici le récapitulatif complet.</p>

      <div class="success-banner">🚀 Logistique confirmée — Vous êtes prêt pour votre mission</div>

      <div class="mission-block">
        <div class="section-title">Détails de la mission</div>
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
      </div>

      @if($traitement)
      <div class="logistic-block">
        <div class="section-title">Logistique DML</div>
        <table class="info-table">
          @if($traitement->hotel_convention_id && $traitement->hotel)
          <tr>
            <td>Hôtel</td>
            <td>{{ $traitement->hotel->nom }} — {{ $traitement->hotel->ville }}</td>
          </tr>
          @elseif($traitement->hotel_nom_libre)
          <tr>
            <td>Hébergement</td>
            <td>{{ $traitement->hotel_nom_libre }}</td>
          </tr>
          @endif
          @if($traitement->vehicule_id && $traitement->vehicule)
          <tr>
            <td>Véhicule</td>
            <td>{{ $traitement->vehicule->marque }} {{ $traitement->vehicule->modele }} ({{ $traitement->vehicule->immatriculation }})</td>
          </tr>
          @endif
          @if($traitement->type_transport)
          <tr>
            <td>Transport</td>
            <td>{{ ucfirst(str_replace('_', ' ', $traitement->type_transport)) }}</td>
          </tr>
          @endif
          @if($traitement->numero_bon)
          <tr>
            <td>N° bon</td>
            <td>{{ $traitement->numero_bon }}</td>
          </tr>
          @endif
          @if($traitement->observations)
          <tr>
            <td>Observations</td>
            <td>{{ $traitement->observations }}</td>
          </tr>
          @endif
        </table>
      </div>
      @endif

      <a href="{{ $appUrl }}/missions/{{ $mission->id }}" class="btn">Voir ma mission →</a>

      <p class="note">Pour toute question concernant votre logistique, contactez l'équipe DML. Bon voyage !</p>
    </div>
    <div class="footer">AT Réservations · Algérie Télécom · Tous droits réservés</div>
  </div>
</div>
</body>
</html>
