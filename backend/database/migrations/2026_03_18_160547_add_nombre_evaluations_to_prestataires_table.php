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
        Schema::table('prestataires', function (Blueprint $table) {
            if (! Schema::hasColumn('prestataires', 'nombre_evaluations')) {
                $table->unsignedInteger('nombre_evaluations')->default(0)->after('note_performance');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('prestataires', function (Blueprint $table) {
            if (Schema::hasColumn('prestataires', 'nombre_evaluations')) {
                $table->dropColumn('nombre_evaluations');
            }
        });
    }
};
