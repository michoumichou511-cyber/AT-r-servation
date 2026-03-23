<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('hebergements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reservation_id')->constrained('reservations')->cascadeOnDelete();
            $table->string('hotel_nom');
            $table->string('adresse_hotel')->nullable();
            $table->string('ville');
            $table->string('pays')->nullable();
            $table->date('date_checkin');
            $table->date('date_checkout');
            $table->unsignedInteger('nombre_nuits');
            $table->string('type_chambre')->nullable();
            $table->decimal('prix_nuit', 12, 2);
            $table->decimal('prix_total', 12, 2);
            $table->string('statut')->default('brouillon');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('hebergements');
    }
};
