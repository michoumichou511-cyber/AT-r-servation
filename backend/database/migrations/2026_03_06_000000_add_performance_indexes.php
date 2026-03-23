<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->index(['user_id', 'statut']);
            $table->index(['created_at']);
            $table->index(['date_depart']);
        });
        Schema::table('reservations', function (Blueprint $table) {
            $table->index(['mission_id', 'statut']);
            $table->index(['type']);
        });
        Schema::table('notifications_custom', function (Blueprint $table) {
            $table->index(['user_id', 'is_read']);
            $table->index(['created_at']);
        });
        Schema::table('audit_logs', function (Blueprint $table) {
            $table->index(['user_id', 'module']);
            $table->index(['created_at']);
        });
    }

    public function down(): void
    {
        // Drop indexes if needed
    }
};
