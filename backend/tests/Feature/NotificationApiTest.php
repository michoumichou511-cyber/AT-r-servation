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

        $role = Role::firstOrCreate(['name' => 'utilisateur']);
        $this->user = User::factory()->create(['role_id' => $role->id, 'is_active' => true]);
    }

    public function test_user_can_list_notifications(): void
    {
        NotificationCustom::create([
            'user_id' => $this->user->id,
            'titre' => 'Test notif',
            'message' => 'Contenu test',
            'type' => 'info',
            'is_read' => false,
            'lue' => false,
        ]);

        $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/notifications')
            ->assertStatus(200);
    }

    public function test_user_can_get_unread_count(): void
    {
        $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/notifications/non-lues/count')
            ->assertStatus(200);
    }

    public function test_user_can_mark_all_read(): void
    {
        NotificationCustom::create([
            'user_id' => $this->user->id,
            'titre' => 'A lire',
            'message' => 'Msg',
            'type' => 'info',
            'is_read' => false,
            'lue' => false,
        ]);

        $this->actingAs($this->user, 'sanctum')
            ->putJson('/api/notifications/tout-lire')
            ->assertStatus(200);
    }

    public function test_user_can_delete_own_notification(): void
    {
        $notif = NotificationCustom::create([
            'user_id' => $this->user->id,
            'titre' => 'A supprimer',
            'message' => 'Msg',
            'type' => 'info',
            'is_read' => false,
            'lue' => false,
        ]);

        $this->actingAs($this->user, 'sanctum')
            ->deleteJson("/api/notifications/{$notif->id}")
            ->assertStatus(200);
    }
}
