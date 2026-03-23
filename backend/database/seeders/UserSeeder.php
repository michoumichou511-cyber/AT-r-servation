<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $roles = Role::query()->pluck('id', 'name');

        $users = [
            [
                'email' => 'admin@at.dz',
                'password' => Hash::make('Password@123'),
                'nom' => 'Système',
                'prenom' => 'Admin',
                'matricule' => 'MAT001',
                'direction' => 'DG',
                'service' => 'IT',
                'role_id' => $roles['admin'] ?? null,
            ],
            [
                'email' => 'validateur@at.dz',
                'password' => Hash::make('Password@123'),
                'nom' => 'Division',
                'prenom' => 'Chef',
                'matricule' => 'MAT002',
                'direction' => 'Logistique',
                'service' => 'Achats',
                'role_id' => $roles['validateur'] ?? null,
            ],
            [
                'email' => 'user@at.dz',
                'password' => Hash::make('Password@123'),
                'nom' => 'Employé',
                'prenom' => 'Test',
                'matricule' => 'MAT003',
                'direction' => 'Technique',
                'service' => 'Réseau',
                'role_id' => $roles['utilisateur'] ?? null,
            ],
            [
                'email' => 'demandeur@at.dz',
                'password' => Hash::make('Password@123'),
                'nom' => 'Benali',
                'prenom' => 'Ahmed',
                'matricule' => 'MAT004',
                'direction' => 'Ressources Humaines',
                'service' => 'Recrutement',
                'role_id' => $roles['demandeur'] ?? null,
            ],
        ];

        foreach ($users as $data) {
            User::query()->updateOrCreate([
                'email' => $data['email'],
            ], $data);
        }
    }
}
