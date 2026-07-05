<?php

namespace Tests\Feature;

use App\Models\Mission;
use App\Models\Reservation;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReservationApiTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private Mission $mission;

    protected function setUp(): void
    {
        parent::setUp();

        $role = Role::firstOrCreate(['name' => 'utilisateur']);
        $this->user = User::factory()->create(['role_id' => $role->id, 'is_active' => true]);

        $this->mission = Mission::create([
            'user_id' => $this->user->id,
            'created_by' => $this->user->id,
            'titre' => 'Mission test résa',
            'objet_mission' => 'Test réservations',
            'destination_ville' => 'Oran',
            'destination_pays' => 'Algérie',
            'destination' => 'Oran, Algérie',
            'date_depart' => now()->addDays(5)->toDateString(),
            'date_retour' => now()->addDays(10)->toDateString(),
            'type_mission' => 'reunion',
            'statut' => 'brouillon',
            'numero_unique' => 'OM-2026-TEST-R',
        ]);
    }

    public function test_user_can_list_reservations_for_own_mission(): void
    {
        $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/missions/{$this->mission->id}/reservations")
            ->assertStatus(200);
    }

    public function test_user_can_create_reservation(): void
    {
        $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/missions/{$this->mission->id}/reservations", [
                'type' => 'billet',
                'montant_estime' => 15000,
                'notes' => 'Vol Alger-Oran',
            ])
            ->assertStatus(201);
    }

    public function test_reservation_requires_type(): void
    {
        $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/missions/{$this->mission->id}/reservations", [
                'notes' => 'Sans type',
            ])
            ->assertStatus(422);
    }
}
