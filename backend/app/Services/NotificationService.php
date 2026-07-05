<?php

namespace App\Services;

use App\Models\NotificationCustom;
use App\Models\User;

class NotificationService
{
    public function notifyUser(int $userId, string $titre, string $message, string $type = 'info', ?string $lien = null): NotificationCustom
    {
        return NotificationCustom::create([
            'user_id' => $userId,
            'titre' => $titre,
            'message' => $message,
            'type' => $type,
            'lien' => $lien,
        ]);
    }

    public function notifyRole(string $roleName, string $titre, string $message, string $type = 'info'): int
    {
        $users = User::whereHas('role', fn ($q) => $q->where('name', $roleName))->pluck('id');

        $notifications = $users->map(fn ($id) => [
            'user_id' => $id,
            'titre' => $titre,
            'message' => $message,
            'type' => $type,
            'created_at' => now(),
            'updated_at' => now(),
        ])->toArray();

        NotificationCustom::insert($notifications);

        return count($notifications);
    }

    public function markAllRead(int $userId): int
    {
        return NotificationCustom::where('user_id', $userId)
            ->whereNull('lu_le')
            ->update(['lu_le' => now()]);
    }
}
