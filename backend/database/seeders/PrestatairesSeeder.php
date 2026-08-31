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
            // ── Compagnies aériennes ─────────────────────────
            ['nom' => 'Air Algérie', 'type' => 'compagnie_aerienne', 'email' => 'contact@airalgerie.dz', 'telephone' => '021 98 63 63', 'ville' => 'Alger', 'pays' => 'Algérie', 'note_performance' => 3.5],
            ['nom' => 'Tassili Airlines', 'type' => 'compagnie_aerienne', 'email' => 'info@tassiliairlines.dz', 'telephone' => '029 76 18 00', 'ville' => 'Hassi Messaoud', 'pays' => 'Algérie', 'note_performance' => 3.2],
            ['nom' => 'Air France', 'type' => 'compagnie_aerienne', 'email' => 'contact@airfrance.fr', 'telephone' => '021 98 04 04', 'ville' => 'Alger', 'pays' => 'France', 'note_performance' => 4.2],
            ['nom' => 'Turkish Airlines', 'type' => 'compagnie_aerienne', 'email' => 'alger@thy.com', 'telephone' => '021 74 22 22', 'ville' => 'Alger', 'pays' => 'Turquie', 'note_performance' => 4.0],
            ['nom' => 'Tunisair', 'type' => 'compagnie_aerienne', 'email' => 'alger@tunisair.com.tn', 'telephone' => '021 63 17 00', 'ville' => 'Alger', 'pays' => 'Tunisie', 'note_performance' => 3.0],

            // ── Hôtels — Alger ───────────────────────────────
            ['nom' => 'El Aurassi Alger', 'type' => 'hotel', 'adresse' => '2 Bd Frantz Fanon, Les Tagarins', 'ville' => 'Alger', 'pays' => 'Algérie', 'telephone' => '021 74 82 52', 'note_performance' => 4.5],
            ['nom' => 'Sheraton Club des Pins', 'type' => 'hotel', 'adresse' => 'BP 62 Club des Pins', 'ville' => 'Alger', 'pays' => 'Algérie', 'telephone' => '021 37 77 77', 'note_performance' => 5.0],
            ['nom' => 'Mercure Alger Aéroport', 'type' => 'hotel', 'adresse' => 'Aéroport Houari Boumediene', 'ville' => 'Alger', 'pays' => 'Algérie', 'telephone' => '021 50 90 90', 'note_performance' => 4.0],
            ['nom' => 'Hilton Alger', 'type' => 'hotel', 'adresse' => 'Pins Maritimes, El Mohammadia', 'ville' => 'Alger', 'pays' => 'Algérie', 'telephone' => '021 21 21 21', 'note_performance' => 4.8],
            ['nom' => 'AZ Hotel Kouba', 'type' => 'hotel', 'adresse' => 'Rue Mohamed Belouizdad, Kouba', 'ville' => 'Alger', 'pays' => 'Algérie', 'telephone' => '021 28 45 00', 'note_performance' => 3.5],

            // ── Hôtels — Oran ────────────────────────────────
            ['nom' => 'Sheraton Oran', 'type' => 'hotel', 'adresse' => '1 Place 1er Novembre', 'ville' => 'Oran', 'pays' => 'Algérie', 'telephone' => '041 40 40 40', 'note_performance' => 4.5],
            ['nom' => 'Le Méridien Oran', 'type' => 'hotel', 'adresse' => 'Convention Centre', 'ville' => 'Oran', 'pays' => 'Algérie', 'telephone' => '041 29 80 80', 'note_performance' => 4.3],
            ['nom' => 'Royal Hotel Oran', 'type' => 'hotel', 'adresse' => 'Bd de la Soummam', 'ville' => 'Oran', 'pays' => 'Algérie', 'telephone' => '041 39 45 45', 'note_performance' => 3.8],

            // ── Hôtels — Constantine ─────────────────────────
            ['nom' => 'Marriott Constantine', 'type' => 'hotel', 'adresse' => 'Nouvelle Ville Ali Mendjeli', 'ville' => 'Constantine', 'pays' => 'Algérie', 'telephone' => '031 79 50 00', 'note_performance' => 4.6],
            ['nom' => 'Hôtel Cirta Constantine', 'type' => 'hotel', 'adresse' => '1 Ave Rahmani Amar', 'ville' => 'Constantine', 'pays' => 'Algérie', 'telephone' => '031 92 88 88', 'note_performance' => 3.5],
            ['nom' => 'Ibis Constantine', 'type' => 'hotel', 'adresse' => 'Nouvelle Ville UV3', 'ville' => 'Constantine', 'pays' => 'Algérie', 'telephone' => '031 79 22 22', 'note_performance' => 3.8],

            // ── Hôtels — Annaba ──────────────────────────────
            ['nom' => 'Hôtel Sabri Annaba', 'type' => 'hotel', 'adresse' => 'Corniche Seybouse', 'ville' => 'Annaba', 'pays' => 'Algérie', 'telephone' => '038 86 40 40', 'note_performance' => 4.0],
            ['nom' => 'Sheraton Annaba', 'type' => 'hotel', 'adresse' => 'Route de la Corniche', 'ville' => 'Annaba', 'pays' => 'Algérie', 'telephone' => '038 86 50 50', 'note_performance' => 4.2],

            // ── Hôtels — Sétif ───────────────────────────────
            ['nom' => 'Hôtel El Hidhab Sétif', 'type' => 'hotel', 'adresse' => 'Cité El Hidhab', 'ville' => 'Sétif', 'pays' => 'Algérie', 'telephone' => '036 93 20 20', 'note_performance' => 3.5],
            ['nom' => 'Park Mall Hôtel Sétif', 'type' => 'hotel', 'adresse' => 'Centre Commercial Park Mall', 'ville' => 'Sétif', 'pays' => 'Algérie', 'telephone' => '036 84 10 10', 'note_performance' => 4.0],

            // ── Hôtels — Béjaïa ──────────────────────────────
            ['nom' => 'Hôtel Cristal Béjaïa', 'type' => 'hotel', 'adresse' => 'Route des Aurès', 'ville' => 'Béjaïa', 'pays' => 'Algérie', 'telephone' => '034 21 55 55', 'note_performance' => 3.8],
            ['nom' => 'Résidence Les Hammadites', 'type' => 'hotel', 'adresse' => 'Tichy', 'ville' => 'Béjaïa', 'pays' => 'Algérie', 'telephone' => '034 20 40 40', 'note_performance' => 3.2],

            // ── Hôtels — Tlemcen ─────────────────────────────
            ['nom' => 'Renaissance Tlemcen', 'type' => 'hotel', 'adresse' => 'Plateau Lalla Setti', 'ville' => 'Tlemcen', 'pays' => 'Algérie', 'telephone' => '043 41 55 55', 'note_performance' => 4.5],
            ['nom' => 'Hôtel Les Zianides Tlemcen', 'type' => 'hotel', 'adresse' => 'Rue Commandant Djaber', 'ville' => 'Tlemcen', 'pays' => 'Algérie', 'telephone' => '043 20 15 15', 'note_performance' => 3.0],

            // ── Hôtels — Sud (Biskra, Ouargla, Ghardaïa) ────
            ['nom' => 'Hôtel El Mountazah Biskra', 'type' => 'hotel', 'adresse' => 'Route de Tolga', 'ville' => 'Biskra', 'pays' => 'Algérie', 'telephone' => '033 74 60 60', 'note_performance' => 3.5],
            ['nom' => 'Hôtel Transatlantique Biskra', 'type' => 'hotel', 'adresse' => 'Rue du Capitaine Khemisti', 'ville' => 'Biskra', 'pays' => 'Algérie', 'telephone' => '033 71 22 22', 'note_performance' => 3.0],
            ['nom' => 'Hôtel Méhari Ouargla', 'type' => 'hotel', 'adresse' => 'Bd de la République', 'ville' => 'Ouargla', 'pays' => 'Algérie', 'telephone' => '029 76 34 34', 'note_performance' => 3.2],
            ['nom' => 'Hôtel El Djanoub Ghardaïa', 'type' => 'hotel', 'adresse' => 'Route Nationale 1', 'ville' => 'Ghardaïa', 'pays' => 'Algérie', 'telephone' => '029 88 11 11', 'note_performance' => 3.5],
            ['nom' => 'Hôtel Rostomides Ghardaïa', 'type' => 'hotel', 'adresse' => 'Quartier Beni Isguen', 'ville' => 'Ghardaïa', 'pays' => 'Algérie', 'telephone' => '029 89 22 22', 'note_performance' => 3.8],

            // ── Hôtels — Autres villes ───────────────────────
            ['nom' => 'Hôtel Chélia Batna', 'type' => 'hotel', 'adresse' => 'Rue de l\'Indépendance', 'ville' => 'Batna', 'pays' => 'Algérie', 'telephone' => '033 86 33 33', 'note_performance' => 3.0],
            ['nom' => 'Hôtel Atlas Blida', 'type' => 'hotel', 'adresse' => 'Bd Larbi Tbessi', 'ville' => 'Blida', 'pays' => 'Algérie', 'telephone' => '025 43 12 12', 'note_performance' => 3.2],
            ['nom' => 'Hôtel Tamanrasset', 'type' => 'hotel', 'adresse' => 'Centre-ville', 'ville' => 'Tamanrasset', 'pays' => 'Algérie', 'telephone' => '029 34 50 50', 'note_performance' => 3.0],
            ['nom' => 'Hôtel Hassi Messaoud', 'type' => 'hotel', 'adresse' => 'Zone Industrielle', 'ville' => 'Hassi Messaoud', 'pays' => 'Algérie', 'telephone' => '029 73 80 80', 'note_performance' => 3.5],
            ['nom' => 'Golden Tulip Tizi Ouzou', 'type' => 'hotel', 'adresse' => 'Nouvelle Ville', 'ville' => 'Tizi Ouzou', 'pays' => 'Algérie', 'telephone' => '026 21 55 55', 'note_performance' => 3.8],
            ['nom' => 'Hôtel Eden Mostaganem', 'type' => 'hotel', 'adresse' => 'Corniche Salamandre', 'ville' => 'Mostaganem', 'pays' => 'Algérie', 'telephone' => '045 33 44 44', 'note_performance' => 3.5],
            ['nom' => 'Hôtel Marsa Ben M\'Hidi', 'type' => 'hotel', 'adresse' => 'Plage de Marsa', 'ville' => 'Tlemcen', 'pays' => 'Algérie', 'telephone' => '043 32 11 11', 'note_performance' => 3.3],
            ['nom' => 'Hôtel Nour Djelfa', 'type' => 'hotel', 'adresse' => 'Route nationale 1', 'ville' => 'Djelfa', 'pays' => 'Algérie', 'telephone' => '027 87 66 66', 'note_performance' => 2.8],
            ['nom' => 'Hôtel Souf El Oued', 'type' => 'hotel', 'adresse' => 'Centre-ville', 'ville' => 'El Oued', 'pays' => 'Algérie', 'telephone' => '032 22 44 44', 'note_performance' => 3.0],
            ['nom' => 'Hôtel Timgad Batna', 'type' => 'hotel', 'adresse' => 'Route de Timgad', 'ville' => 'Batna', 'pays' => 'Algérie', 'telephone' => '033 81 50 50', 'note_performance' => 3.3],

            // ── Restauration / Catering ──────────────────────
            ['nom' => 'Restaurant AT Centre', 'type' => 'catering', 'adresse' => 'Siège AT', 'ville' => 'Alger', 'pays' => 'Algérie', 'note_performance' => 3.5],
            ['nom' => 'Le Bouchon Alger', 'type' => 'catering', 'adresse' => 'Rue Didouche Mourad', 'ville' => 'Alger', 'pays' => 'Algérie', 'note_performance' => 4.0],
            ['nom' => 'Traiteur El Baraka Oran', 'type' => 'catering', 'adresse' => 'Bd Emir Abdelkader', 'ville' => 'Oran', 'pays' => 'Algérie', 'note_performance' => 3.5],
            ['nom' => 'Catering Djurdjura Béjaïa', 'type' => 'catering', 'adresse' => 'Zone Industrielle', 'ville' => 'Béjaïa', 'pays' => 'Algérie', 'note_performance' => 3.2],
            ['nom' => 'Restauration Express Constantine', 'type' => 'catering', 'adresse' => 'Rue Larbi Ben M\'Hidi', 'ville' => 'Constantine', 'pays' => 'Algérie', 'note_performance' => 3.0],
            ['nom' => 'Traiteur Sahara Ouargla', 'type' => 'catering', 'adresse' => 'Rue principale', 'ville' => 'Ouargla', 'pays' => 'Algérie', 'note_performance' => 2.8],

            // ── Agences de voyage ────────────────────────────
            ['nom' => 'ONAT Alger', 'type' => 'agence_voyage', 'email' => 'contact@onat.dz', 'adresse' => '126 Rue Didouche Mourad', 'ville' => 'Alger', 'pays' => 'Algérie', 'telephone' => '021 74 44 44', 'note_performance' => 3.5],
            ['nom' => 'Touring Voyages Algérie', 'type' => 'agence_voyage', 'email' => 'info@tva.dz', 'adresse' => 'Bd Amirouche', 'ville' => 'Alger', 'pays' => 'Algérie', 'telephone' => '021 63 58 58', 'note_performance' => 3.8],
            ['nom' => 'Voyages Khalifa Oran', 'type' => 'agence_voyage', 'adresse' => 'Place du 1er Novembre', 'ville' => 'Oran', 'pays' => 'Algérie', 'telephone' => '041 39 22 22', 'note_performance' => 3.0],
            ['nom' => 'Agence Tassili Voyages', 'type' => 'agence_voyage', 'adresse' => 'Rue Ahmed Bey', 'ville' => 'Constantine', 'pays' => 'Algérie', 'telephone' => '031 92 55 55', 'note_performance' => 3.5],

            // ── Transport (classés agence_voyage — pas de type 'transport' en DB)
            ['nom' => 'ETUSA Alger', 'type' => 'agence_voyage', 'email' => 'contact@etusa.dz', 'adresse' => 'Oued Smar', 'ville' => 'Alger', 'pays' => 'Algérie', 'telephone' => '021 51 70 70', 'note_performance' => 3.0],
            ['nom' => 'Entreprise AT Transport', 'type' => 'agence_voyage', 'adresse' => 'Parc Auto AT', 'ville' => 'Alger', 'pays' => 'Algérie', 'telephone' => '021 60 30 30', 'note_performance' => 4.0],
            ['nom' => 'Trans Sahara Ouargla', 'type' => 'agence_voyage', 'adresse' => 'Zone Industrielle', 'ville' => 'Ouargla', 'pays' => 'Algérie', 'telephone' => '029 76 88 88', 'note_performance' => 3.2],
            ['nom' => 'Naftal Transport Oran', 'type' => 'agence_voyage', 'adresse' => 'Zone Industrielle Es-Sénia', 'ville' => 'Oran', 'pays' => 'Algérie', 'telephone' => '041 47 33 33', 'note_performance' => 3.5],
            ['nom' => 'Transport Est Constantine', 'type' => 'agence_voyage', 'adresse' => 'Route de Batna', 'ville' => 'Constantine', 'pays' => 'Algérie', 'telephone' => '031 69 44 44', 'note_performance' => 3.0],
            ['nom' => 'Location Auto Sud Biskra', 'type' => 'agence_voyage', 'adresse' => 'Rue des Frères Abbas', 'ville' => 'Biskra', 'pays' => 'Algérie', 'telephone' => '033 74 55 55', 'note_performance' => 2.8],
        ];

        foreach ($entries as $data) {
            Prestataire::withoutGlobalScopes()->updateOrCreate([
                'nom' => $data['nom'],
            ], $data + ['is_active' => true, 'created_at' => $now, 'updated_at' => $now]);
        }
    }
}
