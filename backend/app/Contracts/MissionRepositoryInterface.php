<?php

namespace App\Contracts;

use App\Models\Mission;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface MissionRepositoryInterface
{
    public function findForUser(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator;

    public function findById(int $id): Mission;

    public function create(array $data): Mission;

    public function update(Mission $mission, array $data): Mission;

    public function delete(Mission $mission): bool;

    public function countByStatut(User $user): array;
}
