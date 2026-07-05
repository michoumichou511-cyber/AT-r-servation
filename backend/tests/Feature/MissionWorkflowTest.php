<?php

namespace Tests\Feature;

use App\Models\Mission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MissionWorkflowTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private User $validateur;

    protected function setUp(): void
    {
        parent::setUp();

        $roleUser = Role::firstOrCreate(['name' => 'utilisateur']);
        $roleValid = Role::firstOrCreate(['name' => 'validateur']);

        $this->user = User::factory()->create(['role_id' => $roleUser->id, 'is_active' => true]);
        $this->validateur = User::factory()->create(['role_id' => $roleValid->id, 'is_active' => true]);
    }

    public function test_full_mission_lifecycle_create_submit(): void
    {
        $res = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/missions', [
                'titre' => 'Mission lifecycle',
                'objet_mission' => 'Test workflow complet',
                'destination_ville' => 'Annaba',
                'destination_pays' => 'Algérie',
                'date_depart' => now()->addDays(5)->toDateString(),
                'date_retour' => now()->addDays(10)->toDateString(),
                'type_mission' => 'formation',
            ])
            ->assertStatus(201);

        $missionId = $res->json('data.id');

        // Submit requires reservation + validateur — test returns 422 without them
        $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/missions/{$missionId}/submit")
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_cannot_submit_already_submitted_mission(): void
    {
        $mission = Mission::create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
            'titre' => 'Déjà soumise',
            'objet_mission' => 'Test doublon',
            'destination_ville' => 'Tizi',
            'destination_pays' => 'Algérie',
            'destination' => 'Tizi, Algérie',
            'date_depart' => now()->addDays(5)->toDateString(),
            'date_retour' => now()->addDays(10)->toDateString(),
            'type_mission' => 'reunion',
            'statut' => 'soumis',
            'numero_unique' => 'OM-2026-DUP',
        ]);

        $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/missions/{$mission->id}/submit")
            ->assertStatus(422);
    }

    public function test_mission_duplicate_creates_brouillon(): void
    {
        $mission = Mission::create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
            'titre' => 'A dupliquer',
            'objet_mission' => 'Source',
            'destination_ville' => 'Alger',
            'destination_pays' => 'Algérie',
            'destination' => 'Alger, Algérie',
            'date_depart' => now()->addDays(5)->toDateString(),
            'date_retour' => now()->addDays(10)->toDateString(),
            'type_mission' => 'formation',
            'statut' => 'approuve',
            'numero_unique' => 'OM-2026-SRC',
        ]);

        $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/missions/{$mission->id}/duplicate")
            ->assertStatus(201)
            ->assertJsonPath('data.statut', 'brouillon');
    }

    public function test_inactive_user_cannot_create_mission(): void
    {
        $role = Role::firstOrCreate(['name' => 'utilisateur']);
        $inactive = User::factory()->create(['role_id' => $role->id, 'is_active' => false]);

        $this->actingAs($inactive, 'sanctum')
            ->postJson('/api/missions', [
                'titre' => 'Interdit',
                'objet_mission' => 'Compte désactivé',
                'destination_ville' => 'Oran',
                'destination_pays' => 'Algérie',
                'date_depart' => now()->addDays(5)->toDateString(),
                'date_retour' => now()->addDays(10)->toDateString(),
                'type_mission' => 'audit',
            ])
            ->assertStatus(403);
    }
}
