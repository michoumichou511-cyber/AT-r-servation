<?php

namespace App\Exports;

use Carbon\Carbon;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;

class MissionsExportCompact implements FromCollection, ShouldAutoSize, WithHeadings
{
    protected Collection $missions;

    public function __construct($missions)
    {
        $this->missions = $missions instanceof Collection
            ? $missions
            : collect($missions);
    }

    public function headings(): array
    {
        return [
            'ID',
            'Demandeur',
            'Structure',
            'Destination',
            'Date départ',
            'Date retour',
            'Statut',
            'Type mission',
        ];
    }

    public function collection(): Collection
    {
        return $this->missions->map(function ($mission) {
            $demandeur = $mission->user
                ? trim(($mission->user->prenom ?? '').' '.($mission->user->nom ?? ''))
                : '';

            $structure = $mission->user->direction ?? '';

            $destination = $mission->destination
                ?? trim(($mission->destination_ville ?? '').(isset($mission->destination_pays) ? ', '.$mission->destination_pays : ''));

            return [
                $mission->id,
                $demandeur,
                $structure,
                $destination,
                $mission->date_depart ? Carbon::parse($mission->date_depart)->format('d/m/Y') : '',
                $mission->date_retour ? Carbon::parse($mission->date_retour)->format('d/m/Y') : '',
                $mission->statut ?? '',
                $mission->type_mission ?? '',
            ];
        });
    }
}

