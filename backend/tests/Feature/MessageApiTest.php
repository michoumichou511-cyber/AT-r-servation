<?php

namespace Tests\Feature;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MessageApiTest extends TestCase
{
    use RefreshDatabase;

    private User $sender;
    private User $receiver;

    protected function setUp(): void
    {
        parent::setUp();

        $role = Role::firstOrCreate(['name' => 'utilisateur']);
        $this->sender = User::factory()->create(['role_id' => $role->id, 'is_active' => true]);
        $this->receiver = User::factory()->create(['role_id' => $role->id, 'is_active' => true]);
    }

    public function test_user_can_send_message(): void
    {
        $this->actingAs($this->sender, 'sanctum')
            ->postJson('/api/messages', [
                'receiver_id' => $this->receiver->id,
                'contenu' => 'Bonjour, test de messagerie',
            ])
            ->assertStatus(200);
    }

    public function test_message_requires_contenu(): void
    {
        $this->actingAs($this->sender, 'sanctum')
            ->postJson('/api/messages', [
                'receiver_id' => $this->receiver->id,
            ])
            ->assertStatus(422);
    }

    public function test_user_can_list_conversations(): void
    {
        $this->actingAs($this->sender, 'sanctum')
            ->getJson('/api/conversations')
            ->assertStatus(200);
    }

    public function test_unread_count_returns_number(): void
    {
        $this->actingAs($this->sender, 'sanctum')
            ->getJson('/api/messages/non-lus/count')
            ->assertStatus(200);
    }
}
