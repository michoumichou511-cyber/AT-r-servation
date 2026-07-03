<?php

namespace Database\Seeders;

use App\Models\Vehicule;
use Illuminate\Database\Seeder;

/**
 * Parc de véhicules de service pour le module DML.
 */
class VehiculeSeeder extends Seeder
{
    public function run(): void
    {
        $vehicules = [
            ['type' => 'berline', 'marque' => 'Peugeot', 'modele' => '301', 'immatriculation' => '00123-116-16', 'annee' => 2022, 'capacite' => 5, 'statut' => 'disponible'],
            ['type' => 'berline', 'marque' => 'Renault', 'modele' => 'Symbol', 'immatriculation' => '00456-119-16', 'annee' => 2021, 'capacite' => 5, 'statut' => 'disponible'],
            ['type' => 'berline', 'marque' => 'Hyundai', 'modele' => 'Accent', 'immatriculation' => '00789-121-16', 'annee' => 2023, 'capacite' => 5, 'statut' => 'disponible'],
            ['type' => 'voiture_service', 'marque' => 'Dacia', 'modele' => 'Duster', 'immatriculation' => '01012-122-16', 'annee' => 2023, 'capacite' => 5, 'statut' => 'disponible'],
            ['type' => 'minibus', 'marque' => 'Toyota', 'modele' => 'Hiace', 'immatriculation' => '01345-118-16', 'annee' => 2020, 'capacite' => 12, 'statut' => 'disponible'],
            ['type' => 'voiture_service', 'marque' => 'Renault', 'modele' => 'Kangoo', 'immatriculation' => '01678-120-16', 'annee' => 2021, 'capacite' => 2, 'statut' => 'maintenance', 'notes' => 'Révision 60 000 km en cours'],
        ];

        foreach ($vehicules as $v) {
            Vehicule::firstOrCreate(
                ['immatriculation' => $v['immatriculation']],
                $v
            );
        }
    }
}
