<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // MySQL : modifier l'ENUM en place (sans perte de données)
        DB::statement("
            ALTER TABLE missions
            MODIFY statut ENUM(
                'brouillon',
                'soumis',
                'en_validation',
                'approuve',
                'rejete',
                'annule',
                'termine',
                'en_traitement_logistique'
            ) NOT NULL DEFAULT 'brouillon'
        ");
    }

    public function down(): void
    {
        DB::statement("
            ALTER TABLE missions
            MODIFY statut ENUM(
                'brouillon',
                'soumis',
                'en_validation',
                'approuve',
                'rejete',
                'annule'
            ) NOT NULL DEFAULT 'brouillon'
        ");
    }
};
