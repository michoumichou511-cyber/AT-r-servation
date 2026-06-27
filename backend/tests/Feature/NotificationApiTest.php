<?php

namespace Tests\Feature;

use App\Models\NotificationCustom;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationApiTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $role = Role::firstOrCreate(['name' => 'utilisateur'], ['description' => 'Employé']);
        $this->user = User::factory()->create(['role_id' => $role->id]);
    }

    public function test_list_notifications()
    {
        NotificationCustom::create([
            'user_id' => $this->user->id,
            'titre' => 'Test notif',
            'message' => 'Corps du message',
            'type' => 'info',
            'lue' => false,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/notifications');

        $response->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_mark_notification_read()
    {
        $notif = NotificationCustom::create([
            'user_id' => $this->user->id,
            'titre' => 'A lire',
            'message' => 'Contenu',
            'type' => 'info',
            'lue' => false,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/notifications/{$notif->id}/lire");

        $response->assertOk();
        $this->assertDatabaseHas('notifications_custom', [
            'id' => $notif->id,
            'lue' => true,
        ]);
    }

    public function test_mark_all_read()
    {
        NotificationCustom::create([
            'user_id' => $this->user->id,
            'titre' => 'N1',
            'message' => 'M1',
            'type' => 'info',
            'lue' => false,
        ]);
        NotificationCustom::create([
            'user_id' => $this->user->id,
            'titre' => 'N2',
            'message' => 'M2',
            'type' => 'info',
            'lue' => false,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson('/api/notifications/tout-lire');

        $response->assertOk();
        $this->assertEquals(0,
            NotificationCustom::where('user_id', $this->user->id)->where('lue', false)->count()
        );
    }

    public function test_count_unread()
    {
        NotificationCustom::create([
            'user_id' => $this->user->id,
            'titre' => 'Unread',
            'message' => 'Body',
            'type' => 'info',
            'lue' => false,
        ]);
        NotificationCustom::create([
            'user_id' => $this->user->id,
            'titre' => 'Read',
            'message' => 'Body',
            'type' => 'info',
            'lue' => true,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/notifications/non-lues/count');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.count', 1);
    }

    public function test_delete_notification()
    {
        $notif = NotificationCustom::create([
            'user_id' => $this->user->id,
            'titre' => 'To delete',
            'message' => 'Will be removed',
            'type' => 'info',
            'lue' => false,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->deleteJson("/api/notifications/{$notif->id}");

        $response->assertOk();
        $this->assertDatabaseMissing('notifications_custom', ['id' => $notif->id]);
    }

    public function test_cannot_access_other_users_notification()
    {
        $otherRole = Role::firstOrCreate(['name' => 'admin'], ['description' => 'Admin']);
        $other = User::factory()->create(['role_id' => $otherRole->id]);
        $notif = NotificationCustom::create([
            'user_id' => $other->id,
            'titre' => 'Secret',
            'message' => 'Private',
            'type' => 'info',
            'lue' => false,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/notifications/{$notif->id}/lire");

        $response->assertStatus(404);
    }
}
