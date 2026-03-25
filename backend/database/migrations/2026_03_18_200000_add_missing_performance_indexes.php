<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Index sur validations (CircuitValidation) : utilisé dans tous les dashboards validateur
        Schema::table('validations', function (Blueprint $table) {
            if (! $this->indexExists('validations', 'validations_validateur_id_statut_index')) {
                $table->index(['validateur_id', 'statut'], 'validations_validateur_id_statut_index');
            }
        });

        // Index sur evaluations_prestataires : recherches fréquentes par prestataire_id et user_id
        Schema::table('evaluations_prestataires', function (Blueprint $table) {
            if (! $this->indexExists('evaluations_prestataires', 'eval_prestataire_id_index')) {
                $table->index('prestataire_id', 'eval_prestataire_id_index');
            }
            if (! $this->indexExists('evaluations_prestataires', 'eval_user_prestataire_index')) {
                $table->index(['user_id', 'prestataire_id'], 'eval_user_prestataire_index');
            }
        });

        // Index sur notifications_custom.lue (nouvelle colonne ajoutée après la migration initiale)
        Schema::table('notifications_custom', function (Blueprint $table) {
            if (! $this->indexExists('notifications_custom', 'notif_user_lue_index')) {
                $table->index(['user_id', 'lue'], 'notif_user_lue_index');
            }
        });

        // Index missions.statut + date_depart pour les alertes urgentes
        Schema::table('missions', function (Blueprint $table) {
            if (! $this->indexExists('missions', 'missions_statut_date_depart_index')) {
                $table->index(['statut', 'date_depart'], 'missions_statut_date_depart_index');
            }
        });
    }

    public function down(): void
    {
        Schema::table('validations', function (Blueprint $table) {
            $table->dropIndex('validations_validateur_id_statut_index');
        });
        Schema::table('evaluations_prestataires', function (Blueprint $table) {
            $table->dropIndex('eval_prestataire_id_index');
            $table->dropIndex('eval_user_prestataire_index');
        });
        Schema::table('notifications_custom', function (Blueprint $table) {
            $table->dropIndex('notif_user_lue_index');
        });
        Schema::table('missions', function (Blueprint $table) {
            $table->dropIndex('missions_statut_date_depart_index');
        });
    }

    private function indexExists(string $table, string $indexName): bool
    {
        return Schema::hasIndex($table, $indexName);
    }
};
