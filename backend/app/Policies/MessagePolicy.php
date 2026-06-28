<?php

namespace App\Policies;

use App\Models\Message;
use App\Models\User;

class MessagePolicy
{
    public function view(User $user, Message $message): bool
    {
        return $user->id === $message->sender_id || $user->id === $message->receiver_id;
    }

    public function create(User $user): bool
    {
        return $user->is_active;
    }

    public function update(User $user, Message $message): bool
    {
        return $user->id === $message->receiver_id;
    }

    public function delete(User $user, Message $message): bool
    {
        return $user->id === $message->sender_id || $user->role?->name === 'admin';
    }
}
