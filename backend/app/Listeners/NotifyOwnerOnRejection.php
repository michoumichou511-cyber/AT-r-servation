<?php

namespace App\Listeners;

use App\Events\MissionRejected;
use App\Models\NotificationCustom;

class NotifyOwnerOnRejection
{
    public function handle(MissionRejected $event): void
    {
        $mission = $event->mission;

        NotificationCustom::create([
            'user_id' => $mission->user_id,
            'titre' => 'Mission rejetée',
            'message' => "Votre mission {$mission->numero_unique} « {$mission->titre} » a été rejetée. Motif : {$event->motif}",
            'type' => 'danger',
            'is_read' => false,
            'lue' => false,
        ]);
    }
}
