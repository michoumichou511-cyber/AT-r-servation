<?php

namespace Database\Seeders;

use App\Models\HotelConvention;
use Illuminate\Database\Seeder;

class HotelConventionSeeder extends Seeder
{
    public function run(): void
    {
        $conventionDebut = '2026-01-01';
        $conventionFin = '2027-12-31';

        $hotels = [
            // ── Alger ──────────────────────────────
            ['nom' => 'Hôtel El Aurassi', 'ville' => 'Alger', 'wilaya' => 'Alger', 'adresse' => '2 Boulevard Frantz Fanon, Alger Centre', 'telephone' => '021 74 82 52', 'tarif_chambre_simple' => 12000, 'tarif_chambre_double' => 16000],
            ['nom' => 'Sofitel Algiers Hamma Garden', 'ville' => 'Alger', 'wilaya' => 'Alger', 'adresse' => '172 Rue Hassiba Ben Bouali, Hamma', 'telephone' => '021 68 52 10', 'tarif_chambre_simple' => 18000, 'tarif_chambre_double' => 24000],
            ['nom' => 'Hôtel Mercure Alger Aéroport', 'ville' => 'Alger', 'wilaya' => 'Alger', 'adresse' => 'Aéroport Houari Boumediene', 'telephone' => '021 50 90 90', 'tarif_chambre_simple' => 14000, 'tarif_chambre_double' => 18000],
            ['nom' => 'AZ Hotel Kouba', 'ville' => 'Alger', 'wilaya' => 'Alger', 'adresse' => 'Rue Mohamed Gacem, Kouba', 'telephone' => '021 29 44 44', 'tarif_chambre_simple' => 9500, 'tarif_chambre_double' => 13000],

            // ── Oran ───────────────────────────────
            ['nom' => 'Sheraton Oran Hotel', 'ville' => 'Oran', 'wilaya' => 'Oran', 'adresse' => '1 Place 1er Novembre, Oran Centre', 'telephone' => '041 50 50 50', 'tarif_chambre_simple' => 16000, 'tarif_chambre_double' => 22000],
            ['nom' => 'Le Méridien Oran', 'ville' => 'Oran', 'wilaya' => 'Oran', 'adresse' => 'Haï Khemisti, Oran', 'telephone' => '041 29 50 50', 'tarif_chambre_simple' => 14000, 'tarif_chambre_double' => 19000],
            ['nom' => 'Royal Hotel Oran', 'ville' => 'Oran', 'wilaya' => 'Oran', 'adresse' => 'Boulevard de la Soummam, Oran', 'telephone' => '041 40 00 00', 'tarif_chambre_simple' => 8500, 'tarif_chambre_double' => 12000],
            ['nom' => 'Eden Hotel Oran', 'ville' => 'Oran', 'wilaya' => 'Oran', 'adresse' => 'Rue Larbi Ben M\'hidi, Oran', 'telephone' => '041 33 10 00', 'tarif_chambre_simple' => 7000, 'tarif_chambre_double' => 10000],

            // ── Constantine ────────────────────────
            ['nom' => 'Marriott Constantine', 'ville' => 'Constantine', 'wilaya' => 'Constantine', 'adresse' => 'Nouvelle Ville Ali Mendjeli', 'telephone' => '031 79 90 00', 'tarif_chambre_simple' => 15000, 'tarif_chambre_double' => 20000],
            ['nom' => 'Novotel Constantine', 'ville' => 'Constantine', 'wilaya' => 'Constantine', 'adresse' => 'Route de l\'Aéroport, Constantine', 'telephone' => '031 69 40 00', 'tarif_chambre_simple' => 11000, 'tarif_chambre_double' => 15000],
            ['nom' => 'Hôtel Cirta', 'ville' => 'Constantine', 'wilaya' => 'Constantine', 'adresse' => 'Rue Didouche Mourad, Constantine', 'telephone' => '031 92 85 00', 'tarif_chambre_simple' => 7500, 'tarif_chambre_double' => 10000],

            // ── Annaba ─────────────────────────────
            ['nom' => 'Hôtel Seybouse International', 'ville' => 'Annaba', 'wilaya' => 'Annaba', 'adresse' => 'Boulevard du 1er Novembre, Annaba', 'telephone' => '038 86 42 00', 'tarif_chambre_simple' => 12000, 'tarif_chambre_double' => 16000],
            ['nom' => 'Hôtel Sabri', 'ville' => 'Annaba', 'wilaya' => 'Annaba', 'adresse' => 'Corniche, Annaba', 'telephone' => '038 86 50 00', 'tarif_chambre_simple' => 9000, 'tarif_chambre_double' => 13000],
            ['nom' => 'Rhiss Hotel Annaba', 'ville' => 'Annaba', 'wilaya' => 'Annaba', 'adresse' => 'Boulevard du Front de Mer, Annaba', 'telephone' => '038 80 70 00', 'tarif_chambre_simple' => 8000, 'tarif_chambre_double' => 11500],

            // ── Sétif ──────────────────────────────
            ['nom' => 'Hôtel El Hidhab', 'ville' => 'Sétif', 'wilaya' => 'Sétif', 'adresse' => 'Cité El Hidhab, Sétif', 'telephone' => '036 93 66 00', 'tarif_chambre_simple' => 8000, 'tarif_chambre_double' => 11000],
            ['nom' => 'Park Mall Hotel Sétif', 'ville' => 'Sétif', 'wilaya' => 'Sétif', 'adresse' => 'Centre Commercial Park Mall', 'telephone' => '036 72 00 00', 'tarif_chambre_simple' => 10000, 'tarif_chambre_double' => 14000],
            ['nom' => 'Hôtel Nadjah Sétif', 'ville' => 'Sétif', 'wilaya' => 'Sétif', 'adresse' => 'Boulevard de la Palestine, Sétif', 'telephone' => '036 84 20 00', 'tarif_chambre_simple' => 6500, 'tarif_chambre_double' => 9000],

            // ── Béjaïa ─────────────────────────────
            ['nom' => 'Hôtel Les Hammadites', 'ville' => 'Béjaïa', 'wilaya' => 'Béjaïa', 'adresse' => 'Route de Tichy, Béjaïa', 'telephone' => '034 21 48 00', 'tarif_chambre_simple' => 9000, 'tarif_chambre_double' => 12000],
            ['nom' => 'Hôtel Cristal Béjaïa', 'ville' => 'Béjaïa', 'wilaya' => 'Béjaïa', 'adresse' => 'Rue de la Liberté, Béjaïa', 'telephone' => '034 21 30 00', 'tarif_chambre_simple' => 7000, 'tarif_chambre_double' => 10000],
            ['nom' => 'Hôtel Syphax Béjaïa', 'ville' => 'Béjaïa', 'wilaya' => 'Béjaïa', 'adresse' => 'Avenue de la Soummam, Béjaïa', 'telephone' => '034 22 50 00', 'tarif_chambre_simple' => 6500, 'tarif_chambre_double' => 9000],

            // ── Blida ──────────────────────────────
            ['nom' => 'Hôtel Chréa', 'ville' => 'Blida', 'wilaya' => 'Blida', 'adresse' => 'Route de Chréa, Blida', 'telephone' => '025 43 12 00', 'tarif_chambre_simple' => 6000, 'tarif_chambre_double' => 8500],
            ['nom' => 'Royal Hotel Blida', 'ville' => 'Blida', 'wilaya' => 'Blida', 'adresse' => 'Rue Larbi Tebessi, Blida', 'telephone' => '025 41 00 00', 'tarif_chambre_simple' => 7500, 'tarif_chambre_double' => 10500],
            ['nom' => 'Hôtel El Kenz Blida', 'ville' => 'Blida', 'wilaya' => 'Blida', 'adresse' => 'Boulevard Boudiaf, Blida', 'telephone' => '025 42 30 00', 'tarif_chambre_simple' => 5500, 'tarif_chambre_double' => 8000],

            // ── Tizi Ouzou ─────────────────────────
            ['nom' => 'Hôtel Lalla Khedidja', 'ville' => 'Tizi Ouzou', 'wilaya' => 'Tizi Ouzou', 'adresse' => 'Boulevard Stiti Ali, Tizi Ouzou', 'telephone' => '026 22 16 00', 'tarif_chambre_simple' => 7000, 'tarif_chambre_double' => 10000],
            ['nom' => 'Hôtel Amraoua', 'ville' => 'Tizi Ouzou', 'wilaya' => 'Tizi Ouzou', 'adresse' => 'Rue Abane Ramdane, Tizi Ouzou', 'telephone' => '026 21 45 00', 'tarif_chambre_simple' => 5500, 'tarif_chambre_double' => 8000],
            ['nom' => 'Hôtel Belloua Tizi Ouzou', 'ville' => 'Tizi Ouzou', 'wilaya' => 'Tizi Ouzou', 'adresse' => 'Cité Belloua, Tizi Ouzou', 'telephone' => '026 20 80 00', 'tarif_chambre_simple' => 6000, 'tarif_chambre_double' => 8500],

            // ── Ouargla ────────────────────────────
            ['nom' => 'Hôtel Le Transatlantique Ouargla', 'ville' => 'Ouargla', 'wilaya' => 'Ouargla', 'adresse' => 'Avenue de la République, Ouargla', 'telephone' => '029 71 01 00', 'tarif_chambre_simple' => 8000, 'tarif_chambre_double' => 11000],
            ['nom' => 'Hôtel Mehri Ouargla', 'ville' => 'Ouargla', 'wilaya' => 'Ouargla', 'adresse' => 'Centre ville, Ouargla', 'telephone' => '029 76 30 00', 'tarif_chambre_simple' => 6000, 'tarif_chambre_double' => 9000],
            ['nom' => 'Hôtel Rym Ouargla', 'ville' => 'Ouargla', 'wilaya' => 'Ouargla', 'adresse' => 'Hai Nasr, Ouargla', 'telephone' => '029 71 50 00', 'tarif_chambre_simple' => 5000, 'tarif_chambre_double' => 7500],

            // ── Ghardaïa ──────────────────────────
            ['nom' => 'Hôtel Les Rostémides', 'ville' => 'Ghardaïa', 'wilaya' => 'Ghardaïa', 'adresse' => 'Route de Beni Isguen, Ghardaïa', 'telephone' => '029 88 01 00', 'tarif_chambre_simple' => 7000, 'tarif_chambre_double' => 10000],
            ['nom' => 'Hôtel M\'Zab', 'ville' => 'Ghardaïa', 'wilaya' => 'Ghardaïa', 'adresse' => 'Avenue 1er Novembre, Ghardaïa', 'telephone' => '029 89 20 00', 'tarif_chambre_simple' => 5500, 'tarif_chambre_double' => 8000],

            // ── Tlemcen ────────────────────────────
            ['nom' => 'Renaissance Hôtel Tlemcen', 'ville' => 'Tlemcen', 'wilaya' => 'Tlemcen', 'adresse' => 'Plateau Lalla Setti, Tlemcen', 'telephone' => '043 27 50 00', 'tarif_chambre_simple' => 10000, 'tarif_chambre_double' => 14000],
            ['nom' => 'Hôtel Les Zianides', 'ville' => 'Tlemcen', 'wilaya' => 'Tlemcen', 'adresse' => 'Rue Commandant Djaber, Tlemcen', 'telephone' => '043 20 30 00', 'tarif_chambre_simple' => 6500, 'tarif_chambre_double' => 9000],
            ['nom' => 'Hôtel Agadir Tlemcen', 'ville' => 'Tlemcen', 'wilaya' => 'Tlemcen', 'adresse' => 'Avenue Maghreb Arabi, Tlemcen', 'telephone' => '043 21 90 00', 'tarif_chambre_simple' => 5000, 'tarif_chambre_double' => 7500],

            // ── Batna ──────────────────────────────
            ['nom' => 'Hôtel Chelia Batna', 'ville' => 'Batna', 'wilaya' => 'Batna', 'adresse' => 'Route de Biskra, Batna', 'telephone' => '033 86 31 00', 'tarif_chambre_simple' => 7000, 'tarif_chambre_double' => 10000],
            ['nom' => 'Hôtel Salama Batna', 'ville' => 'Batna', 'wilaya' => 'Batna', 'adresse' => 'Rue 1er Novembre, Batna', 'telephone' => '033 80 10 00', 'tarif_chambre_simple' => 5500, 'tarif_chambre_double' => 8000],
            ['nom' => 'AZ Hotel Batna', 'ville' => 'Batna', 'wilaya' => 'Batna', 'adresse' => 'Cité 1200 logements, Batna', 'telephone' => '033 81 44 00', 'tarif_chambre_simple' => 6000, 'tarif_chambre_double' => 8500],

            // ── Biskra ─────────────────────────────
            ['nom' => 'Hôtel Les Zibans', 'ville' => 'Biskra', 'wilaya' => 'Biskra', 'adresse' => 'Route de Touggourt, Biskra', 'telephone' => '033 74 22 00', 'tarif_chambre_simple' => 7500, 'tarif_chambre_double' => 10500],
            ['nom' => 'Hôtel El Mountazah Biskra', 'ville' => 'Biskra', 'wilaya' => 'Biskra', 'adresse' => 'Avenue Hakim Saadane, Biskra', 'telephone' => '033 71 30 00', 'tarif_chambre_simple' => 6000, 'tarif_chambre_double' => 9000],
            ['nom' => 'Royal Hotel Biskra', 'ville' => 'Biskra', 'wilaya' => 'Biskra', 'adresse' => 'Centre ville, Biskra', 'telephone' => '033 73 50 00', 'tarif_chambre_simple' => 5000, 'tarif_chambre_double' => 7500],

            // ── Djelfa ─────────────────────────────
            ['nom' => 'Hôtel Zaghez Djelfa', 'ville' => 'Djelfa', 'wilaya' => 'Djelfa', 'adresse' => 'Route Nationale 1, Djelfa', 'telephone' => '027 87 30 00', 'tarif_chambre_simple' => 5500, 'tarif_chambre_double' => 8000],
            ['nom' => 'Hôtel El Moustakbal Djelfa', 'ville' => 'Djelfa', 'wilaya' => 'Djelfa', 'adresse' => 'Centre ville, Djelfa', 'telephone' => '027 85 10 00', 'tarif_chambre_simple' => 4500, 'tarif_chambre_double' => 7000],

            // ── Tipaza ─────────────────────────────
            ['nom' => 'Hôtel Matarès Tipaza', 'ville' => 'Tipaza', 'wilaya' => 'Tipaza', 'adresse' => 'Zone touristique, Tipaza', 'telephone' => '024 47 70 00', 'tarif_chambre_simple' => 9000, 'tarif_chambre_double' => 13000],
            ['nom' => 'Chenoua Plage Hôtel', 'ville' => 'Tipaza', 'wilaya' => 'Tipaza', 'adresse' => 'Chenoua Plage, Tipaza', 'telephone' => '024 47 50 00', 'tarif_chambre_simple' => 7500, 'tarif_chambre_double' => 11000],

            // ── Boumerdès ──────────────────────────
            ['nom' => 'Hôtel Le Thénia', 'ville' => 'Boumerdès', 'wilaya' => 'Boumerdès', 'adresse' => 'Cité des 500 logements, Boumerdès', 'telephone' => '024 81 60 00', 'tarif_chambre_simple' => 6500, 'tarif_chambre_double' => 9000],
            ['nom' => 'Résidence Sahel Boumerdès', 'ville' => 'Boumerdès', 'wilaya' => 'Boumerdès', 'adresse' => 'Front de Mer, Boumerdès', 'telephone' => '024 79 40 00', 'tarif_chambre_simple' => 7000, 'tarif_chambre_double' => 10000],

            // ── Jijel ──────────────────────────────
            ['nom' => 'Hôtel Kotama Jijel', 'ville' => 'Jijel', 'wilaya' => 'Jijel', 'adresse' => 'Corniche, Jijel', 'telephone' => '034 47 15 00', 'tarif_chambre_simple' => 7000, 'tarif_chambre_double' => 10000],
            ['nom' => 'Hôtel Les Sables d\'Or', 'ville' => 'Jijel', 'wilaya' => 'Jijel', 'adresse' => 'Plage Kotama, Jijel', 'telephone' => '034 49 20 00', 'tarif_chambre_simple' => 8000, 'tarif_chambre_double' => 11000],

            // ── Skikda ─────────────────────────────
            ['nom' => 'Hôtel Es Salem Skikda', 'ville' => 'Skikda', 'wilaya' => 'Skikda', 'adresse' => 'Route du Port, Skikda', 'telephone' => '038 75 10 00', 'tarif_chambre_simple' => 6500, 'tarif_chambre_double' => 9000],
            ['nom' => 'Hôtel Les Orangers Skikda', 'ville' => 'Skikda', 'wilaya' => 'Skikda', 'adresse' => 'Boulevard Ben Boulaïd, Skikda', 'telephone' => '038 76 20 00', 'tarif_chambre_simple' => 5500, 'tarif_chambre_double' => 8000],

            // ── Mostaganem ─────────────────────────
            ['nom' => 'Hôtel Le Dauphin Mostaganem', 'ville' => 'Mostaganem', 'wilaya' => 'Mostaganem', 'adresse' => 'Front de Mer, Mostaganem', 'telephone' => '045 21 35 00', 'tarif_chambre_simple' => 7000, 'tarif_chambre_double' => 10000],

            // ── M\'Sila ────────────────────────────
            ['nom' => 'Hôtel Hodna M\'Sila', 'ville' => 'M\'Sila', 'wilaya' => 'M\'Sila', 'adresse' => 'Avenue de l\'ALN, M\'Sila', 'telephone' => '035 55 20 00', 'tarif_chambre_simple' => 5000, 'tarif_chambre_double' => 7500],

            // ── Médéa ──────────────────────────────
            ['nom' => 'Hôtel El Mouhidine Médéa', 'ville' => 'Médéa', 'wilaya' => 'Médéa', 'adresse' => 'Centre ville, Médéa', 'telephone' => '025 58 10 00', 'tarif_chambre_simple' => 4500, 'tarif_chambre_double' => 7000],

            // ── Chlef ──────────────────────────────
            ['nom' => 'Hôtel Ad Diar Chlef', 'ville' => 'Chlef', 'wilaya' => 'Chlef', 'adresse' => 'Centre ville, Chlef', 'telephone' => '027 77 30 00', 'tarif_chambre_simple' => 5000, 'tarif_chambre_double' => 7500],

            // ── Tiaret ─────────────────────────────
            ['nom' => 'Hôtel Taguine Tiaret', 'ville' => 'Tiaret', 'wilaya' => 'Tiaret', 'adresse' => 'Avenue Emir Abdelkader, Tiaret', 'telephone' => '046 42 20 00', 'tarif_chambre_simple' => 5000, 'tarif_chambre_double' => 7500],

            // ── El Oued ────────────────────────────
            ['nom' => 'Hôtel Louss El Oued', 'ville' => 'El Oued', 'wilaya' => 'El Oued', 'adresse' => 'Centre ville, El Oued', 'telephone' => '032 21 40 00', 'tarif_chambre_simple' => 5500, 'tarif_chambre_double' => 8000],

            // ── Béchar ─────────────────────────────
            ['nom' => 'Hôtel Antar Béchar', 'ville' => 'Béchar', 'wilaya' => 'Béchar', 'adresse' => 'Boulevard Emir Abdelkader, Béchar', 'telephone' => '049 81 30 00', 'tarif_chambre_simple' => 5000, 'tarif_chambre_double' => 7500],

            // ── Tamanrasset ────────────────────────
            ['nom' => 'Hôtel Tahat Tamanrasset', 'ville' => 'Tamanrasset', 'wilaya' => 'Tamanrasset', 'adresse' => 'Centre ville, Tamanrasset', 'telephone' => '029 34 40 00', 'tarif_chambre_simple' => 8000, 'tarif_chambre_double' => 12000],
            ['nom' => 'Hôtel Tidikelt Tamanrasset', 'ville' => 'Tamanrasset', 'wilaya' => 'Tamanrasset', 'adresse' => 'Route de l\'Aéroport, Tamanrasset', 'telephone' => '029 34 60 00', 'tarif_chambre_simple' => 6500, 'tarif_chambre_double' => 9500],
        ];

        foreach ($hotels as $data) {
            HotelConvention::firstOrCreate(
                ['nom' => $data['nom']],
                array_merge($data, [
                    'date_debut_convention' => $conventionDebut,
                    'date_fin_convention'   => $conventionFin,
                    'statut'                => 'active',
                ])
            );
        }
    }
}
