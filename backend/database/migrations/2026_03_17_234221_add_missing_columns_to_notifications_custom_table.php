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
        Schema::table('notifications_custom', function (Blueprint $table) {
            if (! Schema::hasColumn('notifications_custom', 'lue')) {
                $table->boolean('lue')->default(false)->after('is_read');
            }
            if (! Schema::hasColumn('notifications_custom', 'read_at')) {
                $table->timestamp('read_at')->nullable()->after('lue');
            }
            if (! Schema::hasColumn('notifications_custom', 'action_url')) {
                $table->string('action_url')->nullable()->after('read_at');
            }
            if (! Schema::hasColumn('notifications_custom', 'categorie')) {
                $table->string('categorie')->nullable()->after('action_url');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('notifications_custom', function (Blueprint $table) {
            $cols = ['lue', 'read_at', 'action_url', 'categorie'];
            foreach ($cols as $col) {
                if (Schema::hasColumn('notifications_custom', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
