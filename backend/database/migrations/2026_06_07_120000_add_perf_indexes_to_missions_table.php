<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * FIX-5 : indexes composites pour accelerer /api/missions
 * EXPLAIN montrait "Using where; Using filesort" sur la combinaison
 * WHERE user_id=X ORDER BY created_at DESC.
 * Avec un index (user_id, created_at) MySQL elimine le filesort.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            // Index pour le tri par date sur missions filtrees par user
            if (! self::indexExists('missions', 'missions_user_id_created_at_index')) {
                $table->index(['user_id', 'created_at'], 'missions_user_id_created_at_index');
            }
            // Index utile pour le filtre validateur (statut) + tri
            if (! self::indexExists('missions', 'missions_statut_created_at_index')) {
                $table->index(['statut', 'created_at'], 'missions_statut_created_at_index');
            }
        });

        // Reservations.mission_id devrait deja avoir un index (FK), verifions
        Schema::table('reservations', function (Blueprint $table) {
            if (! self::indexExists('reservations', 'reservations_mission_id_statut_index')) {
                $table->index(['mission_id', 'statut'], 'reservations_mission_id_statut_index');
            }
        });
    }

    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            if (self::indexExists('missions', 'missions_user_id_created_at_index')) {
                $table->dropIndex('missions_user_id_created_at_index');
            }
            if (self::indexExists('missions', 'missions_statut_created_at_index')) {
                $table->dropIndex('missions_statut_created_at_index');
            }
        });
        Schema::table('reservations', function (Blueprint $table) {
            if (self::indexExists('reservations', 'reservations_mission_id_statut_index')) {
                $table->dropIndex('reservations_mission_id_statut_index');
            }
        });
    }

    /**
     * Helper pour eviter "Duplicate key name" si l'index existe deja.
     */
    private static function indexExists(string $table, string $indexName): bool
    {
        $rows = \DB::select(
            "SELECT 1 FROM information_schema.statistics
             WHERE table_schema = DATABASE()
               AND table_name = ?
               AND index_name = ?
             LIMIT 1",
            [$table, $indexName]
        );
        return ! empty($rows);
    }
};
