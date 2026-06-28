<?php

namespace App\Listeners;

use App\Events\MissionApproved;
use App\Models\NotificationCustom;

class NotifyOwnerOnApproval
{
    public function handle(MissionApproved $event): void
    {
        $mission = $event->mission;

        NotificationCustom::create([
            'user_id' => $mission->user_id,
            'titre' => 'Mission approuvée',
            'message' => "Votre mission {$mission->numero_unique} « {$mission->titre} » a été approuvée.",
            'type' => 'success',
            'is_read' => false,
            'lue' => false,
        ]);
    }
}
