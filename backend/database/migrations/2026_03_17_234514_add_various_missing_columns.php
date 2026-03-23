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
            if (! Schema::hasColumn('prestataires', 'ville')) {
                $table->string('ville')->nullable()->after('adresse');
            }
        });

        Schema::table('budgets', function (Blueprint $table) {
            if (! Schema::hasColumn('budgets', 'alerte_seuil')) {
                $table->integer('alerte_seuil')->default(80)->after('montant_consomme');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('prestataires', function (Blueprint $table) {
            if (Schema::hasColumn('prestataires', 'ville')) {
                $table->dropColumn('ville');
            }
        });
        Schema::table('budgets', function (Blueprint $table) {
            if (Schema::hasColumn('budgets', 'alerte_seuil')) {
                $table->dropColumn('alerte_seuil');
            }
        });
    }
};
