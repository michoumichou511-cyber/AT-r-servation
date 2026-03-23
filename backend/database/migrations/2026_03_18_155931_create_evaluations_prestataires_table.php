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
        Schema::create('evaluations_prestataires', function (Blueprint $table) {
            $table->id();
            $table->foreignId('prestataire_id')->constrained('prestataires')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('reservation_id')->nullable()->constrained('reservations')->onDelete('set null');
            $table->decimal('ponctualite', 3, 2)->comment('Note /5');
            $table->decimal('qualite_service', 3, 2)->comment('Note /5');
            $table->decimal('rapport_qualite_prix', 3, 2)->comment('Note /5');
            $table->decimal('communication', 3, 2)->comment('Note /5');
            $table->decimal('note_globale', 3, 2)->comment('Moyenne automatique /5');
            $table->text('commentaire')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'reservation_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('evaluations_prestataires');
    }
};
