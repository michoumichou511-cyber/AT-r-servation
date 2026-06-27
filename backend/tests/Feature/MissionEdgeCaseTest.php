<?php

namespace Tests\Feature;

use App\Models\Mission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MissionEdgeCaseTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $adminRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        $userRole = Role::firstOrCreate(['name' => 'utilisateur'], ['description' => 'Employé']);
        Role::firstOrCreate(['name' => 'validateur'], ['description' => 'Validateur']);
        Role::firstOrCreate(['name' => 'demandeur'], ['description' => 'Demandeur']);

        $this->admin = User::factory()->create(['role_id' => $adminRole->id]);
        $this->user = User::factory()->create(['role_id' => $userRole->id]);
    }

    public function test_list_missions_with_filters()
    {
        Mission::factory()->create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
            'statut' => 'brouillon',
            'titre' => 'Voyage Alger',
        ]);
        Mission::factory()->create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
            'statut' => 'approuve',
            'titre' => 'Mission Oran',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/missions?statut=brouillon');

        $response->assertOk()->assertJsonPath('success', true);
        $items = $response->json('data');
        $this->assertTrue(count($items) >= 1);
    }

    public function test_list_missions_search()
    {
        Mission::factory()->create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
            'titre' => 'Formation Paris',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/missions?search=Paris');

        $response->assertOk();
    }

    public function test_show_mission()
    {
        $mission = Mission::factory()->create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/missions/{$mission->id}");

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_delete_brouillon_mission()
    {
        $mission = Mission::factory()->create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
            'statut' => 'brouillon',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->deleteJson("/api/missions/{$mission->id}");

        $response->assertOk();
        $this->assertDatabaseMissing('missions', ['id' => $mission->id]);
    }

    public function test_cancel_mission()
    {
        $mission = Mission::factory()->create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
            'statut' => 'brouillon',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/missions/{$mission->id}/cancel");

        $response->assertOk();
    }

    public function test_mission_not_found()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/missions/99999');

        $response->assertStatus(404);
    }

    public function test_admin_sees_all_missions()
    {
        Mission::factory()->create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
        ]);

        $response = $this->actingAs($this->admin, 'sanctum')
            ->getJson('/api/missions');

        $response->assertOk();
        $this->assertTrue(count($response->json('data')) >= 1);
    }

    public function test_store_mission_validation()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/missions', []);

        $response->assertStatus(422);
    }
}
