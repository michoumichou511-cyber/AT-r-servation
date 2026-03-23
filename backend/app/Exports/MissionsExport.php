<?php

namespace App\Exports;

use Carbon\Carbon;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class MissionsExport implements FromCollection, ShouldAutoSize, WithHeadings, WithStyles
{
    protected Collection $missions;

    public function __construct($missions)
    {
        $this->missions = $missions instanceof Collection
            ? $missions
            : collect($missions);
    }

    public function collection(): Collection
    {
        return $this->missions->map(function ($mission) {
            $demandeur = $mission->user
                ? trim(($mission->user->prenom ?? '').' '.($mission->user->nom ?? ''))
                : '';

            $montantReel = 0;
            if (! empty($mission->reservations)) {
                $montantReel = $mission->reservations
                    ->where('statut', 'confirme')
                    ->sum('montant_reel');
            }

            return [
                $mission->id,
                $mission->objet_mission ?? '',
                // La table missions ne stocke pas direction/service : on les prend sur l'utilisateur
                $mission->user->direction ?? '',
                $mission->user->service ?? '',
                // Pas de champ "lieu_mission" : on exporte destination_ville
                $mission->destination_ville ?? '',
                $mission->date_depart ? Carbon::parse($mission->date_depart)->format('d/m/Y') : '',
                $mission->date_retour ? Carbon::parse($mission->date_retour)->format('d/m/Y') : '',
                $mission->statut ?? '',
                $mission->budget_previsionnel ?? 0,
                $demandeur,
                $montantReel,
            ];
        });
    }

    public function headings(): array
    {
        return [
            'ID',
            'Objet Mission',
            'Direction',
            'Service',
            'Lieu',
            'Date Départ',
            'Date Retour',
            'Statut',
            'Budget Prévu (DZD)',
            'Demandeur',
            'Montant Réel Consommé (DZD)',
        ];
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => [
                'font' => ['bold' => true, 'color' => ['argb' => 'FFFFFFFF']],
                'fill' => ['fillType' => 'solid', 'startColor' => ['argb' => 'FF1E40AF']],
            ],
        ];
    }
}
