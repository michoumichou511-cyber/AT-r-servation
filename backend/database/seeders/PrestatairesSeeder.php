<?php

namespace Database\Seeders;

use App\Models\Prestataire;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class PrestatairesSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $now = now();

        $entries = [
            // airlines
            ['nom' => 'Air Algérie', 'type' => 'compagnie_aerienne', 'email' => 'contact@airalgerie.dz', 'note_performance' => 3.5],
            ['nom' => 'Tassili Airlines', 'type' => 'compagnie_aerienne', 'note_performance' => 3.2],
            ['nom' => 'Air France', 'type' => 'compagnie_aerienne', 'note_performance' => 4.2],
            // hotels (store city in adresse)
            ['nom' => 'El Aurassi Alger', 'type' => 'hotel', 'adresse' => 'Alger', 'note_performance' => 5.0],
            ['nom' => 'Sheraton Club des Pins', 'type' => 'hotel', 'adresse' => 'Alger', 'note_performance' => 5.0],
            ['nom' => 'Mercure Alger', 'type' => 'hotel', 'adresse' => 'Alger', 'note_performance' => 4.0],
            ['nom' => 'Sofitel Oran', 'type' => 'hotel', 'adresse' => 'Oran', 'note_performance' => 4.0],
            // catering (store city in adresse)
            ['nom' => 'Restaurant AT Centre', 'type' => 'catering', 'adresse' => 'Alger', 'note_performance' => null],
            ['nom' => 'Le Bouchon Alger', 'type' => 'catering', 'adresse' => 'Alger', 'note_performance' => null],
        ];

        foreach ($entries as $data) {
            // bypass soft-delete global scope since table has no deleted_at column
            Prestataire::withoutGlobalScopes()->updateOrCreate([
                'nom' => $data['nom'],
            ], $data + ['created_at' => $now, 'updated_at' => $now]);
        }
    }
}
