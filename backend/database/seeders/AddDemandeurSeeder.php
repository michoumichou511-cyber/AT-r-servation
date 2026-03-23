<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AddDemandeurSeeder extends Seeder
{
    public function run(): void
    {
        // Vérifier si le rôle demandeur existe
        $roleDemandeur = Role::where('name', 'demandeur')->first();

        if (! $roleDemandeur) {
            $roleDemandeur = Role::create([
                'name' => 'demandeur',
                'description' => 'Employé qui soumet des demandes de réservation',
                'permissions' => json_encode(['can_create_mission' => true]),
            ]);
        }

        // Créer le demandeur seulement s'il n'existe pas
        if (! User::where('email', 'demandeur@at.dz')->exists()) {
            User::create([
                'nom' => 'Benali',
                'prenom' => 'Ahmed',
                'email' => 'demandeur@at.dz',
                'password' => Hash::make('Password@123'),
                'role_id' => $roleDemandeur->id,
                'matricule' => 'MAT004',
                'direction' => 'Ressources Humaines',
                'service' => 'Recrutement',
                'is_active' => true,
            ]);

            echo "\n✅ Demandeur créé: demandeur@at.dz\n";
        } else {
            echo "\n⚠️  Demandeur existe déjà: demandeur@at.dz\n";
        }
    }
}
