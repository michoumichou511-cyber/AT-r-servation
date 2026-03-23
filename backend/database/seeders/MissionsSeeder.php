<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MissionsSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Aucune mission fictive : uniquement alignement enum métier si besoin.
     * Les missions seront créées par les utilisateurs en production.
     */
    public function run(): void
    {
        DB::statement("ALTER TABLE missions MODIFY statut ENUM(
            'brouillon','soumis','en_validation','approuve','rejete','annule','termine'
        ) NOT NULL DEFAULT 'brouillon'");
    }
}
