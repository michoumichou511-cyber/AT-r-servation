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
        Schema::create('bons_commande', function (Blueprint $table) {
            $table->id();
            $table->string('numero')->unique();
            $table->foreignId('mission_id')->constrained('missions')->cascadeOnDelete();
            $table->enum('type', ['billet', 'hebergement', 'restauration']);
            $table->string('prestataire_nom');
            $table->decimal('montant_total', 12, 2)->default(0);
            $table->enum('statut', ['genere', 'envoye', 'confirme'])->default('genere');
            $table->string('pdf_path')->nullable();
            $table->foreignId('genere_par')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bons_commande');
    }
};
