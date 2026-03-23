<?php

namespace App\Observers;

use App\Models\AuditLog;
use App\Models\Mission;
use Illuminate\Support\Facades\Auth;

class MissionObserver
{
    /**
     * Handle the Mission "created" event.
     */
    public function created(Mission $mission): void
    {
        AuditLog::log(
            'create',
            'mission',
            "La mission #{$mission->id} ({$mission->numero_unique}) a été créée par ".(Auth::user()?->nom_complet ?? 'Système')
        );
    }

    /**
     * Handle the Mission "updated" event.
     */
    public function updated(Mission $mission): void
    {
        if ($mission->wasChanged('statut')) {
            AuditLog::log(
                'update',
                'mission',
                "Statut de la mission #{$mission->id} changé de {$mission->getOriginal('statut')} à {$mission->statut}"
            );
        } else {
            // Log general updates with old and new values for auditing
            $changes = $mission->getChanges();
            unset($changes['updated_at']); // Skip updated_at

            if (! empty($changes)) {
                $oldValues = array_intersect_key($mission->getOriginal(), $changes);
                AuditLog::log(
                    'update',
                    'mission',
                    "Mission #{$mission->id} modifiée",
                    $oldValues,
                    $changes
                );
            }
        }
    }

    /**
     * Handle the Mission "deleted" event.
     */
    public function deleted(Mission $mission): void
    {
        AuditLog::log(
            'delete',
            'mission',
            "Mission #{$mission->id} ({$mission->numero_unique}) supprimée"
        );
    }
}
