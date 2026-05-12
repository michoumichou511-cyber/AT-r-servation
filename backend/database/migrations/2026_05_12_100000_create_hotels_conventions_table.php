<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('hotels_conventions', function (Blueprint $table) {
            $table->id();
            $table->string('nom');
            $table->string('ville');
            $table->string('wilaya')->nullable();
            $table->string('adresse')->nullable();
            $table->string('telephone')->nullable();
            $table->string('email_contact')->nullable();
            $table->date('date_debut_convention')->nullable();
            $table->date('date_fin_convention')->nullable();
            $table->decimal('tarif_chambre_simple', 10, 2)->nullable();
            $table->decimal('tarif_chambre_double', 10, 2)->nullable();
            $table->enum('statut', ['active', 'expiree', 'suspendue'])->default('active');
            $table->text('notes')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('hotels_conventions');
    }
};
