<?php

namespace App\Console\Commands;

use App\Models\Mission;
use Illuminate\Console\Command;

class RappelRapportsMission extends Command
{
    protected $signature = 'rapports:rappel';

    protected $description = 'Rappel rapport mission non soumis';

    public function handle()
    {
        $missions = Mission::whereIn('statut', ['termine', 'approuve'])
            ->whereNull('rapport_soumis')
            ->where('date_retour', '<', now()->subHours(48))
            ->get();
        foreach ($missions as $mission) {
            // Envoyer email de rappel à l'employé
            // ...
            // Créer notification in-app urgente
            // ...
        }
        $this->info('Rappels envoyés : '.$missions->count());
    }
}
