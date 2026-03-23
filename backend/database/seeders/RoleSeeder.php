<?php

namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $now = now();

        $roles = [
            ['name' => 'admin', 'permissions' => json_encode([
                'can_validate' => true,
                'can_manage_users' => true,
                'can_export' => true,
                'can_view_all' => true,
                'can_create_mission' => true,
            ])],
            ['name' => 'validateur', 'permissions' => json_encode([
                'can_validate' => true,
                'can_view_all' => true,
                'can_export' => true,
                'can_create_mission' => true,
            ])],
            ['name' => 'utilisateur', 'permissions' => json_encode([
                'can_create_mission' => true,
                'can_view_own' => true,
            ])],
            ['name' => 'demandeur', 'permissions' => json_encode([
                'can_create_mission' => true,
            ])],
        ];

        foreach ($roles as $role) {
            Role::query()->updateOrCreate(
                ['name' => $role['name']],
                array_merge($role, ['created_at' => $now, 'updated_at' => $now])
            );
        }
    }
}
