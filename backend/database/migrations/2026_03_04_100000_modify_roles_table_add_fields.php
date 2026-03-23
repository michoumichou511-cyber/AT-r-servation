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
        Schema::table('roles', function (Blueprint $table) {
            if (! Schema::hasColumn('roles', 'description')) {
                $table->string('description')->nullable()->after('name');
            }
            if (! Schema::hasColumn('roles', 'permissions')) {
                $table->json('permissions')->nullable()->after('description');
            }
            if (! Schema::hasColumn('roles', 'created_at')) {
                $table->timestamps();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('roles', function (Blueprint $table) {
            $table->dropColumn(['description', 'permissions', 'created_at', 'updated_at']);
        });
    }
};
