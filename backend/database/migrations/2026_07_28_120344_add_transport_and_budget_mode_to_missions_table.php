<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            if (!Schema::hasColumn('missions', 'transport_type')) {
                $table->enum('transport_type', ['avion', 'terrestre'])->nullable()->after('type_mission');
            }
            if (!Schema::hasColumn('missions', 'budget_mode')) {
                $table->enum('budget_mode', ['avance', 'remboursement'])->nullable()->after('budget_previsionnel');
            }
        });
    }

    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            if (Schema::hasColumn('missions', 'transport_type')) {
                $table->dropColumn('transport_type');
            }
            if (Schema::hasColumn('missions', 'budget_mode')) {
                $table->dropColumn('budget_mode');
            }
        });
    }
};
