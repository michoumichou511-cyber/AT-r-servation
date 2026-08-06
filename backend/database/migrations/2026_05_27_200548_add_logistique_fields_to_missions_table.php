<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->string('nom_hotel', 255)->nullable()->after('budget_previsionnel');
            $table->string('numero_billet', 100)->nullable()->after('nom_hotel');
            $table->string('compagnie', 100)->nullable()->after('numero_billet');
            $table->decimal('prix_hebergement_reel', 10, 2)->nullable()->after('compagnie');
            $table->text('observations_dml')->nullable()->after('prix_hebergement_reel');
        });
    }

    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->dropColumn([
                'nom_hotel',
                'numero_billet',
                'compagnie',
                'prix_hebergement_reel',
                'observations_dml',
            ]);
        });
    }
};
