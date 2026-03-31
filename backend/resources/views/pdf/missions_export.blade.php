<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Export Missions - Algérie Télécom</title>
    <style>
        body { font-family: 'DejaVu Sans', sans-serif; font-size: 10px; color: #111827; margin: 0; padding: 20px; }
        .header { border-bottom: 2px solid #00A650; padding-bottom: 12px; margin-bottom: 16px; }
        .header h1 { margin: 0; font-size: 16px; color: #003DA5; }
        .meta { margin-top: 6px; color: #6b7280; font-size: 9px; }
        table { width: 100%; border-collapse: collapse; font-size: 8px; }
        th, td { border: 1px solid #e5e7eb; padding: 6px; vertical-align: top; }
        th { background: #003DA5; color: #fff; font-weight: 700; text-transform: uppercase; font-size: 7px; }
        tr:nth-child(even) { background: #f9fafb; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Export des missions</h1>
        <div class="meta">
            Généré le {{ $date_generation ?? '' }}
            @if(!empty($user))
                — Par {{ $user->prenom ?? '' }} {{ $user->nom ?? '' }}
            @endif
        </div>
    </div>

    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Demandeur</th>
                <th>Structure</th>
                <th>Destination</th>
                <th>Date départ</th>
                <th>Date retour</th>
                <th>Statut</th>
                <th>Type mission</th>
            </tr>
        </thead>
        <tbody>
            @foreach($missions as $mission)
                <tr>
                    <td>{{ $mission->id }}</td>
                    <td>{{ $mission->user ? ($mission->user->prenom . ' ' . $mission->user->nom) : '' }}</td>
                    <td>{{ $mission->user ? ($mission->user->direction ?? '') : '' }}</td>
                    <td>
                        {{ $mission->destination ?? '' }}
                        @if(empty($mission->destination) && ($mission->destination_ville || $mission->destination_pays))
                            {{ $mission->destination_ville }}@if($mission->destination_pays), {{ $mission->destination_pays }}@endif
                        @endif
                    </td>
                    <td>{{ $mission->date_depart ? \Carbon\Carbon::parse($mission->date_depart)->format('d/m/Y') : '' }}</td>
                    <td>{{ $mission->date_retour ? \Carbon\Carbon::parse($mission->date_retour)->format('d/m/Y') : '' }}</td>
                    <td>{{ $mission->statut ?? '' }}</td>
                    <td>{{ $mission->type_mission ?? '' }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>

