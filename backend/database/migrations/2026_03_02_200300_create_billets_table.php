<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('billets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reservation_id')->constrained('reservations')->cascadeOnDelete();
            $table->string('compagnie');
            $table->string('numero_vol');
            $table->string('aeroport_depart');
            $table->string('aeroport_arrivee');
            $table->date('date_vol');
            $table->time('heure_depart');
            $table->time('heure_arrivee');
            $table->enum('classe', ['economique', 'business']);
            $table->string('numero_billet')->nullable();
            $table->decimal('prix', 12, 2);
            $table->string('statut')->default('brouillon');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('billets');
    }
};
