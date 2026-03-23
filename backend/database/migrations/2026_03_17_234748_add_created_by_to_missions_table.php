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
            if (! Schema::hasColumn('missions', 'created_by')) {
                $table->foreignId('created_by')
                    ->nullable()
                    ->constrained('users')
                    ->nullOnDelete()
                    ->after('user_id');
            }
            if (! Schema::hasColumn('missions', 'pour_user_id')) {
                $table->foreignId('pour_user_id')
                    ->nullable()
                    ->constrained('users')
                    ->nullOnDelete()
                    ->after('created_by');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->dropForeign(['created_by']);
            $table->dropForeign(['pour_user_id']);
            $table->dropColumn(['created_by', 'pour_user_id']);
        });
    }
};
