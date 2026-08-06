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
        Schema::table('mission_traitements_dml', function (Blueprint $table) {
            if (!Schema::hasColumn('mission_traitements_dml', 'ticket_number')) {
                $table->string('ticket_number', 100)->nullable()->after('traite_le');
            }
            if (!Schema::hasColumn('mission_traitements_dml', 'ticket_scan_path')) {
                $table->string('ticket_scan_path', 500)->nullable()->after('ticket_number');
            }
            if (!Schema::hasColumn('mission_traitements_dml', 'transport_company')) {
                $table->string('transport_company', 255)->nullable()->default('Air Algérie')->after('ticket_scan_path');
            }
            if (!Schema::hasColumn('mission_traitements_dml', 'transport_date')) {
                $table->date('transport_date')->nullable()->after('transport_company');
            }
            if (!Schema::hasColumn('mission_traitements_dml', 'montant_transport')) {
                $table->decimal('montant_transport', 12, 2)->nullable()->after('transport_date');
            }
        });
    }

    public function down(): void
    {
        Schema::table('mission_traitements_dml', function (Blueprint $table) {
            $cols = ['ticket_number', 'ticket_scan_path', 'transport_company', 'transport_date', 'montant_transport'];
            foreach ($cols as $col) {
                if (Schema::hasColumn('mission_traitements_dml', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
