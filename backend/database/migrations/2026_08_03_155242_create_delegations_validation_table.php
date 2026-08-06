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
        Schema::create('delegations_validation', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delegant_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('delegue_id')->constrained('users')->cascadeOnDelete();
            $table->date('date_debut');
            $table->date('date_fin');
            $table->string('motif', 500)->nullable();
            $table->boolean('active')->default(true);
            $table->timestamps();
            $table->index(['delegue_id', 'date_debut', 'date_fin']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('delegations_validation');
    }
};
