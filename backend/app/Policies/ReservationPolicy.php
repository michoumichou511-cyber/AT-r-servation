<?php

namespace App\Policies;

use App\Models\Reservation;
use App\Models\User;

class ReservationPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Reservation $reservation): bool
    {
        return $user->id === $reservation->user_id
            || $user->id === $reservation->mission?->user_id
            || $this->isAdmin($user);
    }

    public function create(User $user): bool
    {
        return $user->is_active;
    }

    public function update(User $user, Reservation $reservation): bool
    {
        return $user->id === $reservation->user_id || $this->isAdmin($user);
    }

    public function delete(User $user, Reservation $reservation): bool
    {
        return $this->update($user, $reservation);
    }

    protected function isAdmin(User $user): bool
    {
        return $user->role?->name === 'admin';
    }
}
