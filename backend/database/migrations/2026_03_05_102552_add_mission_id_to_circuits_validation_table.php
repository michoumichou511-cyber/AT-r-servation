<?php

use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // mission_id already exists in validations table, nothing to do
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No changes to rollback
    }
};
