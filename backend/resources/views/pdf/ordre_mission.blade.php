<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ordre de Mission - {{ $mission->numero_unique }}</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.5; color: #1a1a1a; margin: 0; padding: 20px; }
        .header { text-align: center; border-bottom: 3px solid #00A650; padding-bottom: 15px; margin-bottom: 20px; }
        .header-top { display: flex; align-items: center; justify-content: center; margin-bottom: 8px; }
        .logo-text { font-size: 22px; font-weight: bold; color: #003DA5; letter-spacing: 1px; }
        .logo-sub { font-size: 11px; color: #666; margin-top: 2px; }
        .title { font-size: 18px; font-weight: bold; color: #00A650; margin: 10px 0 5px; text-transform: uppercase; letter-spacing: 2px; }
        .ref-num { font-size: 13px; color: #003DA5; font-weight: bold; }
        .date-creation { font-size: 11px; color: #888; margin-top: 3px; }
        .section { margin-bottom: 20px; page-break-inside: avoid; }
        .section-title {
            font-size: 12px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px;
            color: #fff; background-color: #003DA5; padding: 6px 12px; margin-bottom: 8px;
            border-left: 4px solid #00A650;
        }
        .row { margin-bottom: 5px; font-size: 12px; }
        .label { font-weight: bold; width: 160px; display: inline-block; color: #333; }
        .value { color: #1a1a1a; }
        table { width: 100%; border-collapse: collapse; margin-top: 8px; font-size: 11px; }
        th { background-color: #003DA5; color: #fff; padding: 6px 8px; text-align: left; font-size: 10px; text-transform: uppercase; }
        td { border: 1px solid #ddd; padding: 6px 8px; }
        tr:nth-child(even) td { background-color: #f9f9f9; }
        .badge {
            display: inline-block; padding: 2px 8px; border-radius: 10px;
            font-size: 10px; font-weight: bold; color: #fff;
        }
        .badge-green { background-color: #00A650; }
        .badge-blue { background-color: #003DA5; }
        .badge-gray { background-color: #6B7280; }
        .signatures { margin-top: 40px; page-break-inside: avoid; }
        .sig-row { display: flex; justify-content: space-between; }
        .sig-box { width: 30%; text-align: center; display: inline-block; }
        .sig-label { font-size: 11px; font-weight: bold; color: #003DA5; margin-bottom: 50px; }
        .sig-line { border-top: 1px solid #333; margin-top: 50px; padding-top: 5px; font-size: 10px; color: #666; }
        .footer {
            margin-top: 30px; padding-top: 10px; border-top: 2px solid #00A650;
            text-align: center; font-size: 9px; color: #888;
        }
        .footer strong { color: #003DA5; }
    </style>
</head>
<body>
    <div class="header">
        @if(file_exists(public_path('logo-at.jpg')))
            <img src="{{ public_path('logo-at.jpg') }}" alt="AT" style="height: 50px; margin-bottom: 5px;">
        @endif
        <div class="logo-text">ALGERIE TELECOM</div>
        <div class="logo-sub">Direction des Systemes d'Information</div>
        <div class="title">Ordre de Mission</div>
        <div class="ref-num">{{ $mission->numero_unique }}</div>
        <div class="date-creation">Cree le {{ $mission->created_at->format('d/m/Y') }}</div>
    </div>

    <div class="section">
        <div class="section-title">Demandeur</div>
        <div class="row"><span class="label">Nom :</span> <span class="value">{{ $mission->user->nom ?? '—' }}</span></div>
        <div class="row"><span class="label">Prenom :</span> <span class="value">{{ $mission->user->prenom ?? '—' }}</span></div>
        <div class="row"><span class="label">Matricule :</span> <span class="value">{{ $mission->user->matricule ?? '—' }}</span></div>
        <div class="row"><span class="label">Direction :</span> <span class="value">{{ $mission->user->direction ?? '—' }}</span></div>
        <div class="row"><span class="label">Service :</span> <span class="value">{{ $mission->user->service ?? '—' }}</span></div>
        <div class="row"><span class="label">Telephone :</span> <span class="value">{{ $mission->user->telephone ?? '—' }}</span></div>
    </div>

    <div class="section">
        <div class="section-title">Details de la Mission</div>
        <div class="row"><span class="label">Titre :</span> <span class="value">{{ $mission->titre }}</span></div>
        <div class="row"><span class="label">Objet :</span> <span class="value">{{ $mission->objet_mission }}</span></div>
        <div class="row"><span class="label">Destination :</span> <span class="value">{{ $mission->destination_ville }}, {{ $mission->destination_pays }}</span></div>
        <div class="row"><span class="label">Depart :</span> <span class="value">{{ $mission->date_depart->format('d/m/Y') }}</span></div>
        <div class="row"><span class="label">Retour :</span> <span class="value">{{ $mission->date_retour->format('d/m/Y') }}</span></div>
        <div class="row"><span class="label">Type de mission :</span> <span class="value">{{ $mission->type_mission ?? '—' }}</span></div>
        <div class="row"><span class="label">Transport :</span> <span class="value badge badge-blue">{{ $mission->transport_type ?? 'Non specifie' }}</span></div>
        <div class="row"><span class="label">Mode budget :</span> <span class="value badge badge-green">{{ $mission->budget_mode ?? 'Non specifie' }}</span></div>
        <div class="row"><span class="label">Priorite :</span> <span class="value">{{ $mission->priorite ?? 'Non specifiee' }}</span></div>
    </div>

    <div class="section">
        <div class="section-title">Reservations</div>
        <table>
            <thead>
                <tr>
                    <th>Type</th>
                    <th>Prestataire</th>
                    <th>Montant Estime</th>
                    <th>Montant Reel</th>
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
                        <td colspan="5" style="text-align: center; color: #999;">Aucune reservation</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($mission->logistique_ok ?? false)
    <div class="section">
        <div class="section-title">Logistique</div>
        <div class="row"><span class="label">Hotel :</span> <span class="value">{{ $mission->hotel ?? 'Non specifie' }}</span></div>
        <div class="row"><span class="label">Vehicule :</span> <span class="value">{{ $mission->vehicule ?? 'Non specifie' }}</span></div>
        <div class="row"><span class="label">Billet Air Algerie :</span> <span class="value">{{ $mission->billet_avion ?? 'Non specifie' }}</span></div>
    </div>
    @endif

    <div class="section">
        <div class="section-title">Budget</div>
        <div class="row"><span class="label">Previsionnel :</span> <span class="value">{{ number_format($mission->budget_previsionnel ?? 0, 2, ',', ' ') }} DA</span></div>
        <div class="row"><span class="label">Consomme :</span> <span class="value">{{ number_format($budgetConsomme ?? 0, 2, ',', ' ') }} DA</span></div>
        <div class="row"><span class="label">Reel :</span> <span class="value">{{ number_format($mission->budget_reel ?? 0, 2, ',', ' ') }} DA</span></div>
    </div>

    <div class="section">
        <div class="section-title">Circuit de Validation</div>
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
                        <td colspan="3" style="text-align: center; color: #999;">Aucune validation</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="signatures">
        <div class="sig-box">
            <div class="sig-label">Le Demandeur</div>
            <div class="sig-line">Signature</div>
        </div>
        <div class="sig-box">
            <div class="sig-label">Le Directeur</div>
            <div class="sig-line">Signature</div>
        </div>
        <div class="sig-box">
            <div class="sig-label">DML</div>
            <div class="sig-line">Signature</div>
        </div>
    </div>

    <div class="footer">
        <p>Document genere le {{ now()->format('d/m/Y') }} &mdash; <strong>AT Reservations v2.0</strong></p>
        <p>&copy; {{ date('Y') }} Algerie Telecom &mdash; Direction des Systemes d'Information</p>
    </div>
</body>
</html>
