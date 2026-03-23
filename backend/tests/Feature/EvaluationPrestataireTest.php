<?php

namespace Tests\Feature;

use App\Models\Prestataire;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EvaluationPrestataireTest extends TestCase
{
    use RefreshDatabase;

    public function test_duplicate_evaluation_is_blocked_when_reservation_id_is_null(): void
    {
        $role = Role::firstOrCreate(['name' => 'utilisateur']);

        $user = User::factory()->create([
            'role_id' => $role->id,
            'is_active' => true,
        ]);

        $prestataire = Prestataire::create([
            'nom' => 'Prestataire test',
            'type' => 'hotel',
            'ville' => 'Alger',
            'pays' => 'Algerie',
            'adresse' => 'Test',
            'note_performance' => 0,
            'nombre_evaluations' => 0,
            'is_active' => true,
        ]);

        Sanctum::actingAs($user, ['*']);

        $payload = [
            'reservation_id' => null,
            'ponctualite' => 4,
            'qualite_service' => 5,
            'rapport_qualite_prix' => 4,
            'communication' => 3,
            'commentaire' => 'Test duplicate',
        ];

        $first = $this->postJson('/api/prestataires/'.$prestataire->id.'/evaluer', $payload);
        $first->assertStatus(201);

        $second = $this->postJson('/api/prestataires/'.$prestataire->id.'/evaluer', $payload);
        $second->assertStatus(409);
        $second->assertJsonPath('success', false);
        $second->assertJsonPath('message', 'Vous avez déjà évalué ce prestataire.');
    }
}
