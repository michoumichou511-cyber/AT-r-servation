<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mission_traitements_dml', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mission_id')->constrained('missions')->cascadeOnDelete();
            $table->foreignId('agent_dml_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('hotel_convention_id')->nullable()->constrained('hotels_conventions')->nullOnDelete();
            $table->string('hotel_nom_libre')->nullable();
            $table->foreignId('vehicule_id')->nullable()->constrained('vehicules')->nullOnDelete();
            $table->enum('type_transport', ['vehicule_service', 'avion', 'train', 'taxi', 'autre'])->nullable();
            $table->string('numero_bon')->nullable();
            $table->text('observations')->nullable();
            $table->enum('statut', ['en_attente', 'en_traitement', 'logistique_ok'])->default('en_attente');
            $table->timestamp('traite_le')->nullable();
            $table->timestamps();

            $table->index('mission_id');
            $table->index('agent_dml_id');
            $table->index('statut');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mission_traitements_dml');
    }
};
