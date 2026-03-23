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
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('participant_1_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('participant_2_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('mission_id')->nullable()->constrained('missions')->nullOnDelete();
            $table->text('dernier_message')->nullable();
            $table->timestamp('dernier_message_at')->nullable();
            $table->timestamps();
            // Nom court : MySQL limite les identifiants à 64 caractères
            $table->unique(
                ['participant_1_id', 'participant_2_id', 'mission_id'],
                'conv_part_mission_unique'
            );
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('conversations');
    }
};
