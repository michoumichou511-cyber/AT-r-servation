<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport des Missions - Algérie Télécom</title>
    <style>
        body {
            font-family: 'DejaVu Sans', sans-serif;
            font-size: 10px;
            line-height: 1.4;
            color: #333;
            margin: 0;
            padding: 20px;
        }

        .header {
            text-align: center;
            border-bottom: 2px solid #00A650;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }

        .header h1 {
            color: #00A650;
            font-size: 18px;
            margin: 0;
            font-weight: bold;
        }

        .header p {
            margin: 5px 0;
            color: #666;
        }

        .periode {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 20px;
            text-align: center;
        }

        .periode strong {
            color: #00A650;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
            font-size: 8px;
        }

        th, td {
            border: 1px solid #ddd;
            padding: 6px;
            text-align: left;
            vertical-align: top;
        }

        th {
            background-color: #00A650;
            color: white;
            font-weight: bold;
            text-transform: uppercase;
            font-size: 7px;
        }

        tr:nth-child(even) {
            background-color: #f9f9f9;
        }

        .statut {
            padding: 2px 6px;
            border-radius: 3px;
            color: white;
            font-size: 7px;
            font-weight: bold;
            text-align: center;
        }

        .statut.approuve { background-color: #28a745; }
        .statut.rejete { background-color: #dc3545; }
        .statut.en_validation { background-color: #ffc107; color: #000; }
        .statut.soumis { background-color: #17a2b8; }
        .statut.brouillon { background-color: #6c757d; }
        .statut.termine { background-color: #20c997; }

        .budget-summary {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border-left: 4px solid #00A650;
        }

        .budget-summary h3 {
            margin: 0 0 10px 0;
            color: #00A650;
            font-size: 12px;
        }

        .budget-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px;
        }

        .budget-label {
            font-weight: bold;
        }

        .budget-value {
            color: #00A650;
            font-weight: bold;
        }

        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            text-align: center;
            font-size: 8px;
            color: #666;
        }

        .page-break {
            page-break-before: always;
        }

        .no-data {
            text-align: center;
            padding: 20px;
            color: #666;
            font-style: italic;
        }

        .text-right {
            text-align: right;
        }

        .text-center {
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>ALGÉRIE TÉLÉCOM</h1>
        <p>DIRECTION DES RESSOURCES HUMAINES</p>
        <h2>RAPPORT DES MISSIONS</h2>
    </div>

    @if($date_debut || $date_fin)
    <div class="periode">
        <strong>Période:</strong>
        @if($date_debut && $date_fin)
            Du {{ \Carbon\Carbon::parse($date_debut)->format('d/m/Y') }} au {{ \Carbon\Carbon::parse($date_fin)->format('d/m/Y') }}
        @elseif($date_debut)
            À partir du {{ \Carbon\Carbon::parse($date_debut)->format('d/m/Y') }}
        @elseif($date_fin)
            Jusqu'au {{ \Carbon\Carbon::parse($date_fin)->format('d/m/Y') }}
        @endif
    </div>
    @endif

    <div class="budget-summary">
        <h3>RÉSUMÉ BUDGÉTAIRE</h3>
        <div class="budget-row">
            <span class="budget-label">Nombre total de missions:</span>
            <span class="budget-value">{{ $missions->count() }}</span>
        </div>
        <div class="budget-row">
            <span class="budget-label">Budget total prévu:</span>
            <span class="budget-value">{{ number_format($total_budget_prevu, 2) }} DA</span>
        </div>
        <div class="budget-row">
            <span class="budget-label">Budget total réalisé:</span>
            <span class="budget-value">{{ number_format($total_budget_reel, 2) }} DA</span>
        </div>
        <div class="budget-row">
            <span class="budget-label">Écart budgétaire:</span>
            <span class="budget-value {{ ($total_budget_reel - $total_budget_prevu) < 0 ? 'text-success' : 'text-danger' }}">
                {{ number_format($total_budget_reel - $total_budget_prevu, 2) }} DA
            </span>
        </div>
    </div>

    @if($missions->count() > 0)
    <table>
        <thead>
            <tr>
                <th>N° Mission</th>
                <th>Demandeur</th>
                <th>Direction</th>
                <th>Destination</th>
                <th>Départ</th>
                <th>Retour</th>
                <th>Durée</th>
                <th>Type</th>
                <th>Statut</th>
                <th class="text-right">Budget Prévu</th>
                <th class="text-right">Budget Réel</th>
                <th>Écart</th>
            </tr>
        </thead>
        <tbody>
            @foreach($missions as $mission)
            <tr>
                <td>{{ $mission->numero_unique }}</td>
                <td>
                    {{ $mission->user ? $mission->user->prenom . ' ' . $mission->user->nom : '' }}<br>
                    <small>{{ $mission->user ? $mission->user->matricule : '' }}</small>
                </td>
                <td>{{ $mission->direction }}</td>
                <td>{{ $mission->destination_ville }}, {{ $mission->destination_pays }}</td>
                <td>{{ $mission->date_debut ? $mission->date_debut->format('d/m/Y') : '' }}</td>
                <td>{{ $mission->date_fin ? $mission->date_fin->format('d/m/Y') : '' }}</td>
                <td class="text-center">{{ $mission->duree_jours }} j.</td>
                <td>{{ $mission->type }}</td>
                <td>
                    <span class="statut {{ strtolower($mission->statut) }}">
                        {{ ucfirst($mission->statut) }}
                    </span>
                </td>
                <td class="text-right">{{ number_format($mission->budget_max, 2) }} DA</td>
                <td class="text-right">
                    {{ number_format($mission->reservations->where('statut', 'confirme')->sum('montant'), 2) }} DA
                </td>
                <td class="text-right">
                    @php
                        $budgetReel = $mission->reservations->where('statut', 'confirme')->sum('montant');
                        $ecart = $budgetReel - $mission->budget_max;
                    @endphp
                    <span style="color: {{ $ecart < 0 ? '#28a745' : '#dc3545' }}">
                        {{ number_format($ecart, 2) }} DA
                    </span>
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>
    @else
    <div class="no-data">
        <p>Aucune mission trouvée pour les critères sélectionnés.</p>
    </div>
    @endif

    <div class="footer">
        <p><strong>Document généré le:</strong> {{ $date_generation }}</p>
        <p><strong>Généré par:</strong> {{ $user->prenom }} {{ $user->nom }} ({{ $user->email }})</p>
        <p><em>Ce document est confidentiel et destiné à un usage interne uniquement.</em></p>
    </div>
</body>
</html>