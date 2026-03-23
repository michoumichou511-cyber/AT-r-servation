<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            if (! Schema::hasColumn('missions', 'approuve_par')) {
                $table->foreignId('approuve_par')
                    ->nullable()
                    ->constrained('users')
                    ->nullOnDelete()
                    ->after('statut');
            }
            if (! Schema::hasColumn('missions', 'approuve_le')) {
                $table->timestamp('approuve_le')
                    ->nullable()
                    ->after('approuve_par');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->dropForeign(['approuve_par']);
            $table->dropColumn(['approuve_par', 'approuve_le']);
        });
    }
};
