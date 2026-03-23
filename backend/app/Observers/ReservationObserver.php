<?php

namespace App\Observers;

use App\Models\AuditLog;
use App\Models\Reservation;

class ReservationObserver
{
    /**
     * Handle the Reservation "created" event.
     */
    public function created(Reservation $reservation): void
    {
        AuditLog::log(
            'create',
            'reservation',
            "Nouvelle réservation #{$reservation->id} ({$reservation->type}) pour la mission #{$reservation->mission_id}"
        );
    }

    /**
     * Handle the Reservation "updated" event.
     */
    public function updated(Reservation $reservation): void
    {
        if ($reservation->wasChanged('statut')) {
            AuditLog::log(
                'update',
                'reservation',
                "Statut de la réservation #{$reservation->id} passé à {$reservation->statut}"
            );
        }
    }

    /**
     * Handle the Reservation "deleted" event.
     */
    public function deleted(Reservation $reservation): void
    {
        AuditLog::log(
            'delete',
            'reservation',
            "Réservation #{$reservation->id} de type {$reservation->type} supprimée"
        );
    }
}
