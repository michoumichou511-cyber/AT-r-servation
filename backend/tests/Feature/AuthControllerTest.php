<?php

namespace Tests\Feature;

use App\Models\Mission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private Role $role;

    protected function setUp(): void
    {
        parent::setUp();
        $this->role = Role::firstOrCreate(['name' => 'utilisateur'], ['description' => 'Employé']);
        Role::firstOrCreate(['name' => 'admin'], ['description' => 'Administrateur']);
        $this->user = User::factory()->create([
            'role_id' => $this->role->id,
            'password' => bcrypt('OldPass1!'),
        ]);
    }

    public function test_change_password_success()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/auth/change-password', [
                'current_password' => 'OldPass1!',
                'new_password' => 'NewPass2@',
                'new_password_confirmation' => 'NewPass2@',
            ]);

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_change_password_wrong_current()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/auth/change-password', [
                'current_password' => 'WrongPass!',
                'new_password' => 'NewPass2@',
                'new_password_confirmation' => 'NewPass2@',
            ]);

        $response->assertStatus(400)->assertJsonPath('success', false);
    }

    public function test_change_password_weak_rejected()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/auth/change-password', [
                'current_password' => 'OldPass1!',
                'new_password' => 'weak',
                'new_password_confirmation' => 'weak',
            ]);

        $response->assertStatus(422);
    }

    public function test_me_returns_user_and_stats()
    {
        Mission::factory()->create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
            'statut' => 'brouillon',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/auth/me');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['user', 'stats'],
            ]);

        $stats = $response->json('data.stats');
        $this->assertArrayHasKey('total_missions', $stats);
        $this->assertArrayHasKey('missions_brouillon', $stats);
    }

    public function test_register_validation_fails()
    {
        $response = $this->postJson('/api/auth/register', [
            'nom' => '',
            'email' => 'invalid',
        ]);

        $response->assertStatus(422);
    }

    public function test_login_invalid_credentials()
    {
        $response = $this->postJson('/api/auth/login', [
            'email' => 'nope@example.com',
            'password' => 'WrongPass1!',
        ]);

        $response->assertStatus(401);
    }

    public function test_unauthenticated_me_returns_401()
    {
        $response = $this->getJson('/api/auth/me');

        $response->assertStatus(401);
    }

}
