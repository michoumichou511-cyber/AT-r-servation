<?php

namespace Tests\Feature;

use App\Mail\MissionSoumise;
use App\Models\Reservation;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class MissionApiTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;

    protected function setUp(): void
    {
        parent::setUp();

        // create necessity roles
        Role::firstOrCreate(['name' => Role::ADMIN], ['description' => 'Administrator']);
        Role::firstOrCreate(['name' => Role::VALIDATEUR], ['description' => 'Validator']);
        Role::firstOrCreate(['name' => Role::UTILISATEUR], ['description' => 'Utilisateur']);

        $roleValidateur = Role::where('name', Role::VALIDATEUR)->first();

        // create an admin user
        $this->admin = User::factory()->create([
            'role_id' => Role::where('name', Role::ADMIN)->first()->id,
        ]);

        // create a validator user
        User::factory()->create([
            'role_id' => $roleValidateur->id,
            'email' => 'validateur@at.dz',
        ]);

        Mail::fake();
    }

    public function test_crud_and_actions_for_missions()
    {
        // create mission
        $payload = [
            'titre' => 'Test mission',
            'objet_mission' => 'Objet',
            'destination_ville' => 'Paris',
            'destination_pays' => 'France',
            'date_depart' => now()->addDay()->toDateString(),
            'date_retour' => now()->addDays(2)->toDateString(),
            'type_mission' => 'formation',
            'budget_previsionnel' => 1000,
        ];

        $response = $this->actingAs($this->admin, 'sanctum')
            ->postJson('/api/missions', $payload);

        $response->assertStatus(201)->assertJson(['success' => true]);
        $missionId = $response->json('data.id');

        // list
        $this->actingAs($this->admin, 'sanctum')
            ->getJson('/api/missions')
            ->assertStatus(200)
            ->assertJsonStructure(['data', 'pagination']);

        // show
        $this->actingAs($this->admin, 'sanctum')
            ->getJson("/api/missions/{$missionId}")
            ->assertStatus(200)
            ->assertJson(['success' => true]);

        // update
        $this->actingAs($this->admin, 'sanctum')
            ->putJson("/api/missions/{$missionId}", ['titre' => 'Modifié'])
            ->assertStatus(200)
            ->assertJsonPath('data.titre', 'Modifié');

        // duplicate
        $dupId = $this->actingAs($this->admin, 'sanctum')
            ->postJson("/api/missions/{$missionId}/duplicate")
            ->assertStatus(201)
            ->json('data.id');

        // cancel original
        $this->actingAs($this->admin, 'sanctum')
            ->postJson("/api/missions/{$missionId}/cancel")
            ->assertStatus(200);

        // add reservation to duplicated mission so submission will succeed
        Reservation::create([
            'mission_id' => $dupId,
            'user_id' => $this->admin->id,
            'type' => 'billet',
            'statut' => 'brouillon',
        ]);

        // submit duplicated
        $this->actingAs($this->admin, 'sanctum')
            ->postJson("/api/missions/{$dupId}/submit")
            ->assertStatus(200)
            ->assertJson(['success' => true]);

        Mail::assertQueued(MissionSoumise::class);

        // export pdf
        $this->actingAs($this->admin, 'sanctum')
            ->get("/api/missions/{$dupId}/export/pdf")
            ->assertStatus(200)
            ->assertHeader('content-type', 'application/pdf');

        // destroy original
        $this->actingAs($this->admin, 'sanctum')
            ->delete("/api/missions/{$missionId}")
            ->assertStatus(200);
    }
}
