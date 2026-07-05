<?php

namespace Tests\Feature;

use App\Models\Mission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardApiTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $utilisateur;

    protected function setUp(): void
    {
        parent::setUp();
        $adminRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        $userRole = Role::firstOrCreate(['name' => 'utilisateur'], ['description' => 'Employé']);
        Role::firstOrCreate(['name' => 'validateur'], ['description' => 'Validateur']);

        $this->admin = User::factory()->create(['role_id' => $adminRole->id, 'direction' => 'DSI']);
        $this->utilisateur = User::factory()->create(['role_id' => $userRole->id, 'direction' => 'RH']);
    }

    public function test_missions_du_mois()
    {
        Mission::factory()->create([
            'user_id' => $this->utilisateur->id,
            'created_by' => $this->utilisateur->id,
            'statut' => 'brouillon',
        ]);

        $response = $this->actingAs($this->utilisateur, 'sanctum')
            ->getJson('/api/dashboard/missions-du-mois');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_depenses_par_direction()
    {
        $response = $this->actingAs($this->admin, 'sanctum')
            ->getJson('/api/dashboard/depenses-par-direction');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_alertes()
    {
        $response = $this->actingAs($this->admin, 'sanctum')
            ->getJson('/api/dashboard/alertes');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_unauthenticated_dashboard_returns_401()
    {
        $this->getJson('/api/dashboard/stats')->assertStatus(401);
        $this->getJson('/api/dashboard/alertes')->assertStatus(401);
    }
}
