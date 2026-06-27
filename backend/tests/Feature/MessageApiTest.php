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
        $role = Role::firstOrCreate(['name' => 'utilisateur'], ['description' => 'Employé']);
        $this->sender = User::factory()->create(['role_id' => $role->id]);
        $this->receiver = User::factory()->create(['role_id' => $role->id]);
    }

    public function test_send_message_creates_conversation()
    {
        $response = $this->actingAs($this->sender, 'sanctum')
            ->postJson('/api/messages', [
                'receiver_id' => $this->receiver->id,
                'contenu' => 'Bonjour, comment allez-vous ?',
            ]);

        $response->assertOk()->assertJsonPath('success', true);
        $this->assertDatabaseHas('conversations', [
            'participant_1_id' => $this->sender->id,
            'participant_2_id' => $this->receiver->id,
        ]);
        $this->assertDatabaseHas('messages', [
            'sender_id' => $this->sender->id,
            'contenu' => 'Bonjour, comment allez-vous ?',
        ]);
    }

    public function test_send_message_reuses_conversation()
    {
        $conv = Conversation::create([
            'participant_1_id' => $this->sender->id,
            'participant_2_id' => $this->receiver->id,
        ]);

        $this->actingAs($this->sender, 'sanctum')
            ->postJson('/api/messages', [
                'receiver_id' => $this->receiver->id,
                'contenu' => 'Premier message',
            ]);
        $this->actingAs($this->sender, 'sanctum')
            ->postJson('/api/messages', [
                'receiver_id' => $this->receiver->id,
                'contenu' => 'Deuxième message',
            ]);

        $this->assertEquals(1, Conversation::count());
        $this->assertEquals(2, Message::where('conversation_id', $conv->id)->count());
    }

    public function test_list_conversations()
    {
        $conv = Conversation::create([
            'participant_1_id' => $this->sender->id,
            'participant_2_id' => $this->receiver->id,
            'dernier_message' => 'Hello',
            'dernier_message_at' => now(),
        ]);

        $response = $this->actingAs($this->sender, 'sanctum')
            ->getJson('/api/conversations');

        $response->assertOk()
            ->assertJsonPath('success', true);

        $conversations = $response->json('data.conversations');
        $this->assertCount(1, $conversations);
    }

    public function test_get_messages_of_conversation()
    {
        $conv = Conversation::create([
            'participant_1_id' => $this->sender->id,
            'participant_2_id' => $this->receiver->id,
        ]);
        Message::create([
            'conversation_id' => $conv->id,
            'sender_id' => $this->sender->id,
            'receiver_id' => $this->receiver->id,
            'contenu' => 'Test message',
            'lu' => false,
        ]);

        $response = $this->actingAs($this->sender, 'sanctum')
            ->getJson("/api/conversations/{$conv->id}/messages");

        $response->assertOk()
            ->assertJsonPath('success', true);

        $messages = $response->json('data.messages');
        $this->assertCount(1, $messages);
    }

    public function test_mark_message_as_read()
    {
        $conv = Conversation::create([
            'participant_1_id' => $this->sender->id,
            'participant_2_id' => $this->receiver->id,
        ]);
        $msg = Message::create([
            'conversation_id' => $conv->id,
            'sender_id' => $this->sender->id,
            'receiver_id' => $this->receiver->id,
            'contenu' => 'A lire',
            'lu' => false,
        ]);

        $response = $this->actingAs($this->receiver, 'sanctum')
            ->putJson("/api/messages/{$msg->id}/lire");

        $response->assertOk();
        $this->assertDatabaseHas('messages', ['id' => $msg->id, 'lu' => true]);
    }

    public function test_unread_count()
    {
        $conv = Conversation::create([
            'participant_1_id' => $this->sender->id,
            'participant_2_id' => $this->receiver->id,
        ]);
        Message::create([
            'conversation_id' => $conv->id,
            'sender_id' => $this->sender->id,
            'receiver_id' => $this->receiver->id,
            'contenu' => 'Unread',
            'lu' => false,
        ]);
        Message::create([
            'conversation_id' => $conv->id,
            'sender_id' => $this->sender->id,
            'receiver_id' => $this->receiver->id,
            'contenu' => 'Also unread',
            'lu' => false,
        ]);

        $response = $this->actingAs($this->receiver, 'sanctum')
            ->getJson('/api/messages/non-lus/count');

        $response->assertOk()
            ->assertJsonPath('data.count', 2);
    }

    public function test_send_message_validation()
    {
        $response = $this->actingAs($this->sender, 'sanctum')
            ->postJson('/api/messages', [
                'contenu' => 'Missing receiver',
            ]);

        $response->assertStatus(422);
    }

    public function test_cannot_read_other_users_conversation()
    {
        $other = User::factory()->create(['role_id' => $this->sender->role_id]);
        $conv = Conversation::create([
            'participant_1_id' => $this->sender->id,
            'participant_2_id' => $this->receiver->id,
        ]);

        $response = $this->actingAs($other, 'sanctum')
            ->getJson("/api/conversations/{$conv->id}/messages");

        $response->assertStatus(404);
    }
}
