<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('missions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('titre');
            $table->text('description')->nullable();
            $table->string('destination');
            $table->date('date_depart');
            $table->date('date_retour');
            $table->string('type_mission')->nullable();
            $table->enum('statut', ['brouillon', 'soumis', 'en_validation', 'approuve', 'rejete'])->default('brouillon');
            $table->string('numero_unique')->unique();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('missions');
    }
};
