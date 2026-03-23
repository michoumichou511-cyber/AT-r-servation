<?php

namespace Tests\Feature;

use App\Models\Mission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RolePermissionsTest extends TestCase
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
    }

    public function test_utilisateur_cannot_access_admin_dashboard()
    {
        $response = $this->actingAs($this->utilisateur, 'sanctum')
            ->getJson('/api/admin/utilisateurs');

        $response->assertStatus(403);
    }

    public function test_admin_can_access_admin_dashboard()
    {
        $response = $this->actingAs($this->admin, 'sanctum')
            ->getJson('/api/admin/utilisateurs');

        $response->assertStatus(200);
    }

    public function test_utilisateur_cannot_access_validations_list()
    {
        $response = $this->actingAs($this->utilisateur, 'sanctum')
            ->getJson('/api/validations');

        $response->assertStatus(403);
    }

    public function test_validateur_can_access_validations_list()
    {
        $response = $this->actingAs($this->validateur, 'sanctum')
            ->getJson('/api/validations');

        $response->assertStatus(200);
    }

    public function test_utilisateur_can_only_see_own_missions()
    {
        // Mission owned by user
        Mission::create([
            'user_id' => $this->utilisateur->id,
            'titre' => 'Mission user',
            'description' => 'Desc',
            'numero_unique' => 'MISS-USER-1',
            'lieu' => 'Paris',
            'destination' => 'Paris',
            'date_depart' => '2025-05-01',
            'date_retour' => '2025-05-05',
            'statut' => 'brouillon',
        ]);
        // Mission owned by someone else
        Mission::create([
            'user_id' => $this->admin->id,
            'titre' => 'Mission admin',
            'description' => 'Desc',
            'numero_unique' => 'MISS-ADMIN-1',
            'lieu' => 'Lyon',
            'destination' => 'Lyon',
            'date_depart' => '2025-06-01',
            'date_retour' => '2025-06-05',
            'statut' => 'brouillon',
        ]);

        $response = $this->actingAs($this->utilisateur, 'sanctum')
            ->getJson('/api/missions');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
    }

    public function test_admin_can_see_all_missions()
    {
        Mission::create([
            'user_id' => $this->utilisateur->id,
            'titre' => 'Mission user',
            'description' => 'Desc',
            'numero_unique' => 'MISS-USER-2',
            'lieu' => 'Paris',
            'destination' => 'Paris',
            'date_depart' => '2025-05-01',
            'date_retour' => '2025-05-05',
            'statut' => 'brouillon',
        ]);
        Mission::create([
            'user_id' => $this->admin->id,
            'titre' => 'Mission admin',
            'description' => 'Desc',
            'numero_unique' => 'MISS-ADMIN-2',
            'lieu' => 'Lyon',
            'destination' => 'Lyon',
            'date_depart' => '2025-06-01',
            'date_retour' => '2025-06-05',
            'statut' => 'brouillon',
        ]);

        $response = $this->actingAs($this->admin, 'sanctum')
            ->getJson('/api/missions');

        $response->assertStatus(200);
        $this->assertCount(2, $response->json('data'));
    }
}
