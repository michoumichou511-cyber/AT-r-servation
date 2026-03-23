<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class ResetDemoData extends Command
{
    protected $signature = 'demo:reset';

    protected $description = 'Réinitialise les données de démo';

    public function handle()
    {
        // 1. Truncate tables
        DB::table('missions')->truncate();
        DB::table('reservations')->truncate();
        DB::table('billets_avion')->truncate();
        DB::table('hebergements')->truncate();
        DB::table('restaurations')->truncate();
        DB::table('validations')->truncate();
        DB::table('documents')->truncate();
        DB::table('notifications_custom')->truncate();
        DB::table('audit_logs')->truncate();
        // 2. Recréer 5 missions de démo
        // ...
        // 3. Recréer réservations liées
        // ...
        $this->info('✅ Données de démo réinitialisées !');
    }
}
