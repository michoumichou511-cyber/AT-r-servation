<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class ATUsersSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $roles = Role::query()->pluck('id', 'name');
        $password = Hash::make('Password@123');

        $accounts = [
            ['name' => 'Karim Bensalem', 'email' => 'karim.bensalem@at.dz', 'role' => 'admin', 'structure_id' => 'pdg'],
            ['name' => 'Admin Système', 'email' => 'admin@at.dz', 'role' => 'admin', 'structure_id' => 'pdg'],
            ['name' => 'Nadia Khelifi', 'email' => 'nadia.khelifi@at.dz', 'role' => 'validateur', 'structure_id' => 'cellule'],
            ['name' => 'Mourad Tebbal', 'email' => 'mourad.tebbal@at.dz', 'role' => 'validateur', 'structure_id' => 'inspection'],
            ['name' => 'Yacine Boudiaf', 'email' => 'yacine.boudiaf@at.dz', 'role' => 'validateur', 'structure_id' => 'dsi'],
            ['name' => 'Leila Mebarki', 'email' => 'leila.mebarki@at.dz', 'role' => 'validateur', 'structure_id' => 'drh'],
            ['name' => 'Bilal Hadidi', 'email' => 'bilal.hadidi@at.dz', 'role' => 'validateur', 'structure_id' => 'dcm'],
            ['name' => 'Karima Bouziane', 'email' => 'karima.bouziane@at.dz', 'role' => 'validateur', 'structure_id' => 'dfc'],
            ['name' => 'Adel Boukhobza', 'email' => 'adel.boukhobza@at.dz', 'role' => 'validateur', 'structure_id' => 'dir-interconnexion'],
            ['name' => 'Djamila Rekik', 'email' => 'djamila.rekik@at.dz', 'role' => 'validateur', 'structure_id' => 'dir-achats'],
            ['name' => 'Abdelaziz Guerroudj', 'email' => 'abdelaziz.guerroudj@at.dz', 'role' => 'validateur', 'structure_id' => 'pole-infra'],
            ['name' => 'Houria Belkacemi', 'email' => 'houria.belkacemi@at.dz', 'role' => 'validateur', 'structure_id' => 'dir-formation'],
            ['name' => 'Amar Bouzidi', 'email' => 'amar.bouzidi@at.dz', 'role' => 'validateur', 'structure_id' => 'dir-secu'],
            ['name' => 'Samira Hadj-Ali', 'email' => 'samira.hadjali@at.dz', 'role' => 'validateur', 'structure_id' => 'dir-infra'],
            ['name' => 'Rachid Ferhat', 'email' => 'rachid.ferhat@at.dz', 'role' => 'validateur', 'structure_id' => 'dir-dev'],
            ['name' => 'Farida Amrane', 'email' => 'farida.amrane@at.dz', 'role' => 'validateur', 'structure_id' => 'dir-billing'],
            ['name' => 'Djamel Ouali', 'email' => 'djamel.ouali@at.dz', 'role' => 'validateur', 'structure_id' => 'dir-carrieres'],
            ['name' => 'Samir Bencherif', 'email' => 'samir.bencherif@at.dz', 'role' => 'validateur', 'structure_id' => 'dept-qualite'],
            ['name' => 'Kamel Ghribi', 'email' => 'kamel.ghribi@at.dz', 'role' => 'validateur', 'structure_id' => 'dept-competences'],
            ['name' => 'Nabila Sediki', 'email' => 'nabila.sediki@at.dz', 'role' => 'validateur', 'structure_id' => 'dept-veille'],
            ['name' => 'Hani Beddiaf', 'email' => 'hani.beddiaf@at.dz', 'role' => 'validateur', 'structure_id' => 'div-transport'],
            ['name' => 'Lydia Chaker', 'email' => 'lydia.chaker@at.dz', 'role' => 'validateur', 'structure_id' => 'div-core'],
            ['name' => 'Mehdi Bouchenak', 'email' => 'mehdi.bouchenak@at.dz', 'role' => 'validateur', 'structure_id' => 'div-acces'],
            ['name' => 'Assia Boudali', 'email' => 'assia.boudali@at.dz', 'role' => 'demandeur', 'structure_id' => 's-qualite'],
            ['name' => 'Hocine Zeroual', 'email' => 'hocine.zeroual@at.dz', 'role' => 'demandeur', 'structure_id' => 's-etude'],
            ['name' => 'Rania Tlemcani', 'email' => 'rania.tlemcani@at.dz', 'role' => 'demandeur', 'structure_id' => 's-support'],
            ['name' => 'Nabil Kara', 'email' => 'nabil.kara@at.dz', 'role' => 'demandeur', 'structure_id' => 's-tech'],
            ['name' => 'Wafa Benali', 'email' => 'wafa.benali@at.dz', 'role' => 'demandeur', 'structure_id' => 's-manag'],
            ['name' => 'Sofiane Laib', 'email' => 'sofiane.laib@at.dz', 'role' => 'demandeur', 'structure_id' => 's-cadres'],
            ['name' => 'Tarek Mahiout', 'email' => 'tarek.mahiout@at.dz', 'role' => 'demandeur', 'structure_id' => 's-veille'],
            ['name' => 'Imane Bensaid', 'email' => 'imane.bensaid@at.dz', 'role' => 'demandeur', 'structure_id' => 's-etude2'],
            ['name' => 'Chaabane Khelil', 'email' => 'chaabane.khelil@at.dz', 'role' => 'demandeur', 'structure_id' => 'do-alger1'],
            ['name' => 'Nassira Belmahi', 'email' => 'nassira.belmahi@at.dz', 'role' => 'demandeur', 'structure_id' => 'do-alger2'],
            ['name' => 'Omar Brahimi', 'email' => 'omar.brahimi@at.dz', 'role' => 'demandeur', 'structure_id' => 'do-alger3'],
            ['name' => 'Utilisateur Test', 'email' => 'user@at.dz', 'role' => 'utilisateur', 'structure_id' => 'dsi'],
            ['name' => 'Demandeur Test', 'email' => 'demandeur@at.dz', 'role' => 'demandeur', 'structure_id' => 's-tech'],
            ['name' => 'Validateur Test', 'email' => 'validateur@at.dz', 'role' => 'validateur', 'structure_id' => 'dir-formation'],
        ];

        $i = 1;
        foreach ($accounts as $row) {
            [$prenom, $nom] = $this->splitName($row['name']);
            User::query()->updateOrCreate(
                ['email' => $row['email']],
                [
                    'prenom' => $prenom,
                    'nom' => $nom,
                    'password' => $password,
                    'role_id' => $roles[$row['role']] ?? null,
                    'structure_id' => $row['structure_id'],
                    'matricule' => 'MAT'.str_pad((string) $i, 3, '0', STR_PAD_LEFT),
                ]
            );
            $i++;
        }
    }

    /**
     * @return array{0: string, 1: string}
     */
    private function splitName(string $name): array
    {
        $name = trim($name);
        $pos = strpos($name, ' ');
        if ($pos === false) {
            return [$name, '—'];
        }

        return [substr($name, 0, $pos), trim(substr($name, $pos + 1))];
    }
}
