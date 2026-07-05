<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Les colonnes ENUM d'audit_logs rejetaient silencieusement des valeurs
 * réellement utilisées par le code ("Data truncated" → 500) :
 *   - module : billet, hebergement, restauration, depense, prestataire
 *   - action : request_modification
 * On passe en VARCHAR : l'audit ne doit jamais faire échouer une action métier.
 */
return new class extends Migration
{
    public function up(): void
    {
        // ALTER MODIFY est du MySQL/MariaDB. Sous sqlite (tests :memory:),
        // la migration d'origine crée déjà des colonnes string : rien à faire.
        if (DB::getDriverName() !== 'mysql') {
            return;
        }
        DB::statement('ALTER TABLE audit_logs MODIFY action VARCHAR(50) NOT NULL');
        DB::statement('ALTER TABLE audit_logs MODIFY module VARCHAR(50) NOT NULL');
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'mysql') {
            return;
        }
        DB::statement("ALTER TABLE audit_logs MODIFY action ENUM('login','create','update','delete','approve','reject','export') NOT NULL");
        DB::statement("ALTER TABLE audit_logs MODIFY module ENUM('mission','reservation','validation','user','budget') NOT NULL");
    }
};
