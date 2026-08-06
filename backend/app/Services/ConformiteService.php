<?php

namespace App\Services;

use App\Models\Budget;
use App\Models\Mission;
use Carbon\Carbon;

class ConformiteService
{
    public function verifierMission(Mission $mission): array
    {
        $alertes = [];

        if ($mission->date_depart && $mission->date_depart->diffInHours(now()) < 48) {
            $alertes[] = [
                'code' => 'DELAI_COURT',
                'niveau' => 'warning',
                'message' => 'Mission soumise moins de 48h avant le départ',
            ];
        }

        if ($mission->date_depart && $mission->date_retour) {
            $duree = $mission->date_depart->diffInDays($mission->date_retour);
            if ($duree > 30) {
                $alertes[] = [
                    'code' => 'DUREE_LONGUE',
                    'niveau' => 'warning',
                    'message' => "Durée de mission exceptionnelle ({$duree} jours)",
                ];
            }
        }

        $user = $mission->user;
        if ($user && $mission->budget_previsionnel) {
            $budget = Budget::where('direction', $user->direction)
                ->where('annee', now()->year)
                ->first();
            if ($budget) {
                $disponible = $budget->montant_alloue - $budget->montant_consomme;
                if ($mission->budget_previsionnel > $disponible) {
                    $alertes[] = [
                        'code' => 'BUDGET_DEPASSE',
                        'niveau' => 'danger',
                        'message' => "Budget direction dépassé (disponible: {$disponible} DA)",
                    ];
                }
            }
        }

        $doublon = Mission::where('id', '!=', $mission->id)
            ->where('user_id', $mission->user_id)
            ->where('destination', $mission->destination)
            ->whereIn('statut', ['soumis', 'en_validation', 'approuve'])
            ->where(function ($q) use ($mission) {
                $q->whereBetween('date_depart', [$mission->date_depart, $mission->date_retour])
                  ->orWhereBetween('date_retour', [$mission->date_depart, $mission->date_retour]);
            })
            ->exists();

        if ($doublon) {
            $alertes[] = [
                'code' => 'DOUBLON',
                'niveau' => 'warning',
                'message' => 'Une mission similaire existe déjà pour cette destination et période',
            ];
        }

        if ($mission->date_depart && $mission->date_retour) {
            $current = $mission->date_depart->copy();
            $includesWeekend = false;
            while ($current->lte($mission->date_retour)) {
                if ($current->isWeekend()) {
                    $includesWeekend = true;
                    break;
                }
                $current->addDay();
            }
            if ($includesWeekend) {
                $alertes[] = [
                    'code' => 'WEEKEND',
                    'niveau' => 'info',
                    'message' => 'Les dates de mission incluent un week-end',
                ];
            }
        }

        return $alertes;
    }
}
