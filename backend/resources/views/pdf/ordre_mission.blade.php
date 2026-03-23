<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ordre de Mission</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.4; color: #333; }
        .header { text-align: center; border-bottom: 2px solid #007bff; padding-bottom: 20px; margin-bottom: 30px; }
        .logo { font-size: 24px; font-weight: bold; color: #007bff; }
        .title { font-size: 20px; font-weight: bold; margin: 10px 0; }
        .section { margin-bottom: 25px; }
        .section-title { font-size: 14px; font-weight: bold; background-color: #f0f0f0; padding: 8px; margin-bottom: 10px; }
        .row { margin-bottom: 8px; }
        .label { font-weight: bold; width: 150px; display: inline-block; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f0f0f0; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 10px; color: #666; }
        .signature-box { display: inline-block; width: 30%; text-align: center; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">📱 ALGÉRIE TÉLÉCOM</div>
        <div class="title">ORDRE DE MISSION</div>
        <div>{{ $mission->numero_unique }}</div>
    </div>

    <div class="section">
        <div class="section-title">INFORMATIONS AGENT</div>
        <div class="row"><span class="label">Nom :</span> {{ $mission->user->nom }}</div>
        <div class="row"><span class="label">Prénom :</span> {{ $mission->user->prenom }}</div>
        <div class="row"><span class="label">Matricule :</span> {{ $mission->user->matricule }}</div>
        <div class="row"><span class="label">Direction :</span> {{ $mission->user->direction }}</div>
        <div class="row"><span class="label">Service :</span> {{ $mission->user->service }}</div>
    </div>

    <div class="section">
        <div class="section-title">DÉTAILS DE LA MISSION</div>
        <div class="row"><span class="label">Titre :</span> {{ $mission->titre }}</div>
        <div class="row"><span class="label">Objet :</span> {{ $mission->objet_mission }}</div>
        <div class="row"><span class="label">Destination :</span> {{ $mission->destination_ville }}, {{ $mission->destination_pays }}</div>
        <div class="row"><span class="label">Départ :</span> {{ $mission->date_depart->format('d/m/Y') }}</div>
        <div class="row"><span class="label">Retour :</span> {{ $mission->date_retour->format('d/m/Y') }}</div>
        <div class="row"><span class="label">Type :</span> {{ $mission->type_mission }}</div>
        <div class="row"><span class="label">Priorité :</span> {{ $mission->priorite ?? 'Non spécifiée' }}</div>
    </div>

    <div class="section">
        <div class="section-title">RÉSERVATIONS</div>
        <table>
            <thead>
                <tr>
                    <th>Type</th>
                    <th>Prestataire</th>
                    <th>Montant Estimé</th>
                    <th>Montant Réel</th>
                    <th>Statut</th>
                </tr>
            </thead>
            <tbody>
                @forelse($mission->reservations as $res)
                    <tr>
                        <td>{{ $res->type }}</td>
                        <td>{{ $res->prestataire?->nom ?? 'N/A' }}</td>
                        <td>{{ number_format($res->montant_estime, 2, ',', ' ') }} DA</td>
                        <td>{{ number_format($res->montant_reel ?? 0, 2, ',', ' ') }} DA</td>
                        <td>{{ $res->statut }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" style="text-align: center;">Aucune réservation</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="section">
        <div class="section-title">BUDGET</div>
        <div class="row"><span class="label">Prévisionnel :</span> {{ number_format($mission->budget_previsionnel ?? 0, 2, ',', ' ') }} DA</div>
        <div class="row"><span class="label">Consommé :</span> {{ number_format($budgetConsomme, 2, ',', ' ') }} DA</div>
        <div class="row"><span class="label">Réel :</span> {{ number_format($mission->budget_reel ?? 0, 2, ',', ' ') }} DA</div>
    </div>

    <div class="section">
        <div class="section-title">CIRCUIT DE VALIDATION</div>
        <table>
            <thead>
                <tr>
                    <th>Ordre</th>
                    <th>Validateur</th>
                    <th>Statut</th>
                </tr>
            </thead>
            <tbody>
                @forelse($mission->circuitsValidation as $circuit)
                    <tr>
                        <td>{{ $circuit->ordre_etape }}</td>
                        <td>{{ $circuit->validateur?->prenom }} {{ $circuit->validateur?->nom }}</td>
                        <td>{{ $circuit->statut }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="3" style="text-align: center;">Aucune validation</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="footer">
        <p>&copy; 2026 Algérie Télécom. Tous droits réservés.</p>
        <p>Ce document est généré automatiquement par la plateforme de réservation.</p>
    </div>
</body>
</html>
