<?php

namespace App\Listeners;

use App\Events\MissionSubmitted;
use App\Models\NotificationCustom;
use App\Models\User;

class NotifyValidateursOnSubmission
{
    public function handle(MissionSubmitted $event): void
    {
        $mission = $event->mission;
        $mission->loadMissing('user');

        $validateurs = User::whereHas('role', fn ($q) => $q->whereIn('name', ['admin', 'validateur']))
            ->where('is_active', true)
            ->pluck('id');

        if ($validateurs->isEmpty()) {
            return;
        }

        $now = now();
        NotificationCustom::insert($validateurs->map(fn ($id) => [
            'user_id' => $id,
            'titre' => 'Mission soumise pour validation',
            'message' => "La mission {$mission->numero_unique} « {$mission->titre} » a été soumise par {$mission->user->prenom} {$mission->user->nom}.",
            'type' => 'info',
            'is_read' => false,
            'lue' => false,
            'created_at' => $now,
            'updated_at' => $now,
        ])->all());
    }
}
