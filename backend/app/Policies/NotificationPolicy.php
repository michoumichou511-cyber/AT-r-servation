<?php

namespace App\Policies;

use App\Models\NotificationCustom;
use App\Models\User;

class NotificationPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, NotificationCustom $notification): bool
    {
        return $user->id === $notification->user_id;
    }

    public function update(User $user, NotificationCustom $notification): bool
    {
        return $user->id === $notification->user_id;
    }

    public function delete(User $user, NotificationCustom $notification): bool
    {
        return $user->id === $notification->user_id || $user->role?->name === 'admin';
    }
}
