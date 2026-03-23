<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('restaurations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reservation_id')->constrained('reservations')->cascadeOnDelete();
            $table->foreignId('prestataire_id')->constrained('prestataires')->cascadeOnDelete();
            $table->date('date_repas');
            $table->enum('type_repas', ['petit_dejeuner', 'dejeuner', 'diner']);
            $table->string('lieu')->nullable();
            $table->unsignedInteger('nombre_personnes');
            $table->decimal('prix_par_personne', 12, 2);
            $table->decimal('prix_total', 12, 2);
            $table->string('statut')->default('brouillon');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('restaurations');
    }
};
