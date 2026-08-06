<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Bug 2 — Step 1 wizard mission n'avait pas de "Ville de depart".
     * On ajoute la colonne pour permettre de saisir l'origine du deplacement.
     */
    public function up(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            if (! Schema::hasColumn('missions', 'ville_depart')) {
                $table->string('ville_depart', 100)->nullable()->after('destination_pays');
            }
        });
    }

    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            if (Schema::hasColumn('missions', 'ville_depart')) {
                $table->dropColumn('ville_depart');
            }
        });
    }
};
