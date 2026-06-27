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
        return $user->id === $mission->user_id
            || $user->id === $mission->created_by
            || $this->isAdmin($user)
            || $this->isValidateur($user);
    }

    public function create(User $user): bool
    {
        return $user->is_active;
    }

    public function update(User $user, Mission $mission): bool
    {
        return $user->id === $mission->user_id || $this->isAdmin($user);
    }

    public function delete(User $user, Mission $mission): bool
    {
        return $user->id === $mission->user_id || $this->isAdmin($user);
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
