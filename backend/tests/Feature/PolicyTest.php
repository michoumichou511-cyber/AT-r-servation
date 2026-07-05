<?php

namespace Tests\Feature;

use App\Models\Mission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PolicyTest extends TestCase
{
    use RefreshDatabase;

    private User $owner;
    private User $other;
    private User $admin;
    private Mission $mission;

    protected function setUp(): void
    {
        parent::setUp();

        $roleUser = Role::firstOrCreate(['name' => 'utilisateur']);
        $roleAdmin = Role::firstOrCreate(['name' => 'admin']);

        $this->owner = User::factory()->create(['role_id' => $roleUser->id, 'is_active' => true]);
        $this->other = User::factory()->create(['role_id' => $roleUser->id, 'is_active' => true]);
        $this->admin = User::factory()->create(['role_id' => $roleAdmin->id, 'is_active' => true]);

        $this->mission = Mission::create([
            'user_id' => $this->owner->id,
            'created_by' => $this->owner->id,
            'titre' => 'Mission policy test',
            'objet_mission' => 'Test policies',
            'destination_ville' => 'Alger',
            'destination_pays' => 'Algérie',
            'destination' => 'Alger, Algérie',
            'date_depart' => now()->addDays(5)->toDateString(),
            'date_retour' => now()->addDays(10)->toDateString(),
            'type_mission' => 'formation',
            'statut' => 'brouillon',
            'numero_unique' => 'OM-2026-POL',
        ]);
    }

    public function test_owner_can_view_own_mission(): void
    {
        $this->actingAs($this->owner, 'sanctum')
            ->getJson("/api/missions/{$this->mission->id}")
            ->assertStatus(200);
    }

    public function test_other_user_cannot_view_mission(): void
    {
        $this->actingAs($this->other, 'sanctum')
            ->getJson("/api/missions/{$this->mission->id}")
            ->assertStatus(403);
    }

    public function test_admin_can_view_any_mission(): void
    {
        $this->actingAs($this->admin, 'sanctum')
            ->getJson("/api/missions/{$this->mission->id}")
            ->assertStatus(200);
    }

    public function test_other_user_cannot_update_mission(): void
    {
        $this->actingAs($this->other, 'sanctum')
            ->putJson("/api/missions/{$this->mission->id}", ['titre' => 'Hack'])
            ->assertStatus(403);
    }

    public function test_other_user_cannot_delete_mission(): void
    {
        $this->actingAs($this->other, 'sanctum')
            ->deleteJson("/api/missions/{$this->mission->id}")
            ->assertStatus(403);
    }

    public function test_owner_cannot_update_non_brouillon_mission(): void
    {
        $this->mission->update(['statut' => 'soumis']);

        $this->actingAs($this->owner, 'sanctum')
            ->putJson("/api/missions/{$this->mission->id}", ['titre' => 'Modif interdite'])
            ->assertStatus(403);
    }
}
