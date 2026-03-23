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
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'matricule')) {
                $table->string('matricule')->unique()->after('email');
            }
            if (! Schema::hasColumn('users', 'service')) {
                $table->string('service')->nullable()->after('matricule');
            }
            if (! Schema::hasColumn('users', 'direction')) {
                $table->string('direction')->nullable()->after('service');
            }
            if (! Schema::hasColumn('users', 'poste')) {
                $table->string('poste')->nullable()->after('direction');
            }
            if (! Schema::hasColumn('users', 'telephone')) {
                $table->string('telephone')->nullable()->after('poste');
            }
            if (! Schema::hasColumn('users', 'avatar')) {
                $table->string('avatar')->nullable()->after('telephone');
            }
            if (! Schema::hasColumn('users', 'last_login_at')) {
                $table->timestamp('last_login_at')->nullable()->after('is_active');
            }
            if (! Schema::hasColumn('users', 'preferences')) {
                $table->json('preferences')->nullable()->after('last_login_at');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'matricule',
                'service',
                'direction',
                'poste',
                'telephone',
                'avatar',
                'last_login_at',
                'preferences',
            ]);
        });
    }
};
