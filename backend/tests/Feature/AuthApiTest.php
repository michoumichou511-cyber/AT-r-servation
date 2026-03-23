<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Create necessary roles
        Role::firstOrCreate(['name' => 'utilisateur'], ['description' => 'Employé']);
        Role::firstOrCreate(['name' => 'admin'], ['description' => 'Administrateur']);
    }

    public function test_user_can_register()
    {
        // First get the role that the controller applies by default
        $roleInfo = Role::where('name', 'utilisateur')->first();
        $this->assertNotNull($roleInfo, 'The utilisateur role should exist.');
        $payload = [
            'nom' => 'Doe',
            'prenom' => 'John',
            'email' => 'john.doe@example.com',
            'password' => 'Password123!',
            'matricule' => 'M12345',
            'service' => 'Informatique',
            'direction' => 'Technique',
        ];

        $response = $this->postJson('/api/auth/register', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['user', 'token'],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john.doe@example.com',
            'matricule' => 'M12345',
        ]);
    }

    public function test_user_can_login()
    {
        $role = Role::where('name', 'utilisateur')->first();
        $user = User::factory()->create([
            'email' => 'jane.doe@example.com',
            'password' => bcrypt('Password123!'),
            'is_active' => true,
            'role_id' => $role->id,
        ]);

        $payload = [
            'email' => 'jane.doe@example.com',
            'password' => 'Password123!',
        ];

        $response = $this->postJson('/api/auth/login', $payload);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['user', 'token'],
            ]);
    }

    public function test_inactive_user_cannot_login()
    {
        $role = Role::where('name', 'utilisateur')->first();
        $user = User::factory()->create([
            'email' => 'blocked@example.com',
            'password' => bcrypt('Password123!'),
            'is_active' => false,
            'role_id' => $role->id,
        ]);

        $payload = [
            'email' => 'blocked@example.com',
            'password' => 'Password123!',
        ];

        $response = $this->postJson('/api/auth/login', $payload);

        $response->assertStatus(403)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Votre compte a été désactivé');
    }

    public function test_user_can_update_profile()
    {
        $role = Role::where('name', 'utilisateur')->first();
        $user = User::factory()->create(['role_id' => $role->id]);

        $payload = [
            'nom' => 'Updated Name',
            'telephone' => '0600000000',
        ];

        $response = $this->actingAs($user, 'sanctum')
            ->putJson('/api/auth/profile', $payload);

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'nom' => 'Updated Name',
            'telephone' => '0600000000',
        ]);
    }

    public function test_user_can_logout()
    {
        $role = Role::where('name', 'utilisateur')->first();
        $user = User::factory()->create(['role_id' => $role->id]);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeaders(['Authorization' => 'Bearer '.$token])
            ->postJson('/api/auth/logout');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }
}
