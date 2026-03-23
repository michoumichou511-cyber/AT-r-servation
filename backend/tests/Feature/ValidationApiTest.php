<?php

namespace Tests\Feature;

use App\Models\CircuitValidation;
use App\Models\Mission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ValidationApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->roleAdmin = Role::firstOrCreate(['name' => 'admin']);
        $this->roleValidateur = Role::firstOrCreate(['name' => 'validateur']);
        $this->roleUtilisateur = Role::firstOrCreate(['name' => 'utilisateur']);

        $this->admin = User::factory()->create(['role_id' => $this->roleAdmin->id]);
        $this->validateur = User::factory()->create(['role_id' => $this->roleValidateur->id]);
        $this->utilisateur = User::factory()->create(['role_id' => $this->roleUtilisateur->id]);

        $this->mission = Mission::create([
            'user_id' => $this->utilisateur->id,
            'titre' => 'Mission test validation',
            'description' => 'Description de la mission',
            'numero_unique' => 'MISS-VAL-001',
            'destination' => 'Paris',
            'destination_ville' => 'Paris',
            'destination_pays' => 'France',
            'date_depart' => '2025-05-01',
            'date_retour' => '2025-05-05',
            'type_mission' => 'reunion',
            'priorite' => 'normale',
            'statut' => 'soumis',
        ]);

        $this->validation = CircuitValidation::create([
            'mission_id' => $this->mission->id,
            'validateur_id' => $this->validateur->id,
            'ordre_validation' => 1,
            'statut' => 'en_attente',
        ]);
    }

    public function test_validateur_can_list_his_validations()
    {
        $response = $this->actingAs($this->validateur, 'sanctum')
            ->getJson('/api/validations');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals($this->validation->id, $response->json('data.0.id'));
    }

    public function test_validateur_can_approve_validation()
    {
        $response = $this->actingAs($this->validateur, 'sanctum')
            ->postJson("/api/validations/{$this->validation->id}/approuver", [
                'commentaire' => 'OK pour moi',
            ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('validations', [
            'id' => $this->validation->id,
            'statut' => 'approuve',
            'commentaire' => 'OK pour moi',
        ]);
    }

    public function test_validateur_can_reject_validation_with_comment()
    {
        $response = $this->actingAs($this->validateur, 'sanctum')
            ->postJson("/api/validations/{$this->validation->id}/rejeter", [
                'commentaire' => 'Il manque des pieces justificatives',
            ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('validations', [
            'id' => $this->validation->id,
            'statut' => 'rejete',
            'commentaire' => 'Il manque des pieces justificatives',
        ]);
    }

    public function test_validateur_cannot_reject_validation_without_comment()
    {
        $response = $this->actingAs($this->validateur, 'sanctum')
            ->postJson("/api/validations/{$this->validation->id}/rejeter", []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('commentaire');
    }
}
