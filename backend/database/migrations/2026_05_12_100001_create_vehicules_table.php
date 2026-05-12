<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicules', function (Blueprint $table) {
            $table->id();
            $table->enum('type', ['voiture_service', 'minibus', 'berline']);
            $table->string('marque');
            $table->string('modele');
            $table->string('immatriculation')->unique();
            $table->year('annee')->nullable();
            $table->enum('statut', ['disponible', 'en_mission', 'maintenance'])->default('disponible');
            $table->integer('capacite')->default(5);
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicules');
    }
};
