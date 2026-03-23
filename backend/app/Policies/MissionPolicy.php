<?php

namespace App\Policies;

use App\Models\Mission;
use App\Models\User;

class MissionPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Mission $mission): bool
    {
        return $user->id === $mission->user_id || $this->isAdmin($user) || $this->isValidateur($user);
    }

    public function create(User $user): bool
    {
        return $user->is_active;
    }

    public function update(User $user, Mission $mission): bool
    {
        if ($mission->statut !== 'brouillon') {
            return false;
        }

        return $user->id === $mission->user_id || $this->isAdmin($user);
    }

    public function delete(User $user, Mission $mission): bool
    {
        return $this->update($user, $mission);
    }

    public function submit(User $user, Mission $mission): bool
    {
        return $user->id === $mission->user_id && $mission->statut === 'brouillon';
    }

    protected function isAdmin(User $user): bool
    {
        return $user->role?->name === 'admin';
    }

    protected function isValidateur(User $user): bool
    {
        return $user->role?->name === 'validateur';
    }
}
