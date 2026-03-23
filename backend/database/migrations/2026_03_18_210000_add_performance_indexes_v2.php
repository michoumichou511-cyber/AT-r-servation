<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Index messages : lecture par conversation + compteur non lus par destinataire
        Schema::table('messages', function (Blueprint $table) {
            if (! $this->indexExists('messages', 'msg_conv_read_idx')) {
                $table->index(['conversation_id', 'lu'], 'msg_conv_read_idx');
            }
            if (! $this->indexExists('messages', 'msg_receiver_lu_idx')) {
                $table->index(['receiver_id', 'lu'], 'msg_receiver_lu_idx');
            }
        });

        // Index notifications (user_id, is_read) si pas déjà présent sous un autre nom
        Schema::table('notifications_custom', function (Blueprint $table) {
            if (
                ! $this->indexExists('notifications_custom', 'notif_user_read_idx')
                && ! $this->indexExists('notifications_custom', 'notifications_custom_user_id_is_read_index')
            ) {
                $table->index(['user_id', 'is_read'], 'notif_user_read_idx');
            }
        });

        // Table métier = missions (pas ordres_de_mission)
        Schema::table('missions', function (Blueprint $table) {
            if (
                ! $this->indexExists('missions', 'mission_user_statut_idx')
                && ! $this->indexExists('missions', 'missions_user_id_statut_index')
            ) {
                $table->index(['user_id', 'statut'], 'mission_user_statut_idx');
            }
        });
    }

    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            if ($this->indexExists('messages', 'msg_conv_read_idx')) {
                $table->dropIndex('msg_conv_read_idx');
            }
            if ($this->indexExists('messages', 'msg_receiver_lu_idx')) {
                $table->dropIndex('msg_receiver_lu_idx');
            }
        });

        Schema::table('notifications_custom', function (Blueprint $table) {
            if ($this->indexExists('notifications_custom', 'notif_user_read_idx')) {
                $table->dropIndex('notif_user_read_idx');
            }
        });

        Schema::table('missions', function (Blueprint $table) {
            if ($this->indexExists('missions', 'mission_user_statut_idx')) {
                $table->dropIndex('mission_user_statut_idx');
            }
        });
    }

    private function indexExists(string $table, string $indexName): bool
    {
        try {
            $indexes = \DB::select('SHOW INDEX FROM `'.$table.'` WHERE Key_name = ?', [$indexName]);

            return count($indexes) > 0;
        } catch (\Throwable $e) {
            return false;
        }
    }
};
