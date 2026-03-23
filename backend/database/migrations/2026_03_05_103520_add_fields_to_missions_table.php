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
            if (! Schema::hasColumn('missions', 'objet_mission')) {
                $table->text('objet_mission')->nullable()->after('titre');
            }
            if (! Schema::hasColumn('missions', 'destination_ville')) {
                $table->string('destination_ville')->nullable()->after('destination');
            }
            if (! Schema::hasColumn('missions', 'destination_pays')) {
                $table->string('destination_pays')->nullable()->after('destination_ville');
            }
            if (! Schema::hasColumn('missions', 'priorite')) {
                $table->enum('priorite', ['normale', 'urgente', 'tres_urgente'])->default('normale')->after('statut');
            }
            if (! Schema::hasColumn('missions', 'budget_previsionnel')) {
                $table->decimal('budget_previsionnel', 12, 2)->nullable()->after('priorite');
            }
            if (! Schema::hasColumn('missions', 'soumis_le')) {
                $table->timestamp('soumis_le')->nullable()->after('budget_previsionnel');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $dropColumns = [];
            if (Schema::hasColumn('missions', 'objet_mission')) {
                $dropColumns[] = 'objet_mission';
            }
            if (Schema::hasColumn('missions', 'destination_ville')) {
                $dropColumns[] = 'destination_ville';
            }
            if (Schema::hasColumn('missions', 'destination_pays')) {
                $dropColumns[] = 'destination_pays';
            }
            if (Schema::hasColumn('missions', 'priorite')) {
                $dropColumns[] = 'priorite';
            }
            if (Schema::hasColumn('missions', 'budget_previsionnel')) {
                $dropColumns[] = 'budget_previsionnel';
            }
            if (Schema::hasColumn('missions', 'soumis_le')) {
                $dropColumns[] = 'soumis_le';
            }
            if (! empty($dropColumns)) {
                $table->dropColumn($dropColumns);
            }
        });
    }
};
