<?php

namespace App\Services;

use App\Models\Mission;

class CarboneService
{
    private const CO2_AVION_KG_KM = 0.255;
    private const CO2_TERRESTRE_KG_KM = 0.171;
    private const KG_PAR_ARBRE_AN = 22;

    private const DISTANCES_WILAYAS = [
        'alger'       => 0,
        'oran'        => 432,
        'constantine' => 431,
        'annaba'      => 599,
        'setif'       => 300,
        'blida'       => 50,
        'tizi ouzou'  => 100,
        'bejaia'      => 260,
        'batna'       => 425,
        'tlemcen'     => 520,
        'biskra'      => 425,
        'ouargla'     => 800,
        'ghardaia'    => 600,
        'djelfa'      => 300,
        'msila'       => 250,
        'tipaza'      => 70,
        'boumerdes'   => 50,
        'bouira'      => 120,
        'medea'       => 90,
        'chlef'       => 200,
        'mostaganem'  => 365,
        'sidi bel abbes' => 470,
        'skikda'      => 500,
        'jijel'       => 350,
        'el oued'     => 630,
        'bechar'      => 1000,
        'adrar'       => 1500,
        'tamanrasset' => 1900,
        'paris'       => 1350,
        'tunis'       => 900,
        'istanbul'    => 2800,
        'dubai'       => 5200,
        'casablanca'  => 1600,
        'rome'        => 1200,
        'madrid'      => 1500,
    ];

    public function calculerEmpreinte(Mission $mission): array
    {
        $transportType = strtolower($mission->transport_type ?? 'avion');
        $isAvion = str_contains($transportType, 'avion') || str_contains($transportType, 'aerien');

        $destination = strtolower(trim($mission->destination_ville ?? ''));
        $distanceKm = self::DISTANCES_WILAYAS[$destination] ?? 300;
        $distanceAllerRetour = $distanceKm * 2;

        $facteur = $isAvion ? self::CO2_AVION_KG_KM : self::CO2_TERRESTRE_KG_KM;
        $co2Kg = round($distanceAllerRetour * $facteur, 1);
        $equivalentArbres = self::KG_PAR_ARBRE_AN > 0 ? round($co2Kg / self::KG_PAR_ARBRE_AN, 1) : 0;

        return [
            'co2_kg'           => $co2Kg,
            'equivalent_arbres' => $equivalentArbres,
            'transport_type'    => $isAvion ? 'avion' : 'terrestre',
            'distance_km'      => $distanceAllerRetour,
        ];
    }

    public function statsEmpreinte(string $periode = 'mois'): array
    {
        $query = Mission::whereNotNull('date_depart');

        $now = now();
        if ($periode === 'mois') {
            $query->whereMonth('date_depart', $now->month)->whereYear('date_depart', $now->year);
        } elseif ($periode === 'trimestre') {
            $debutTrimestre = $now->copy()->startOfQuarter();
            $query->where('date_depart', '>=', $debutTrimestre);
        } else {
            $query->whereYear('date_depart', $now->year);
        }

        $missions = $query->get();
        $totalCo2 = 0;
        $co2Avion = 0;
        $co2Terrestre = 0;
        $parDirection = [];

        foreach ($missions as $mission) {
            $empreinte = $this->calculerEmpreinte($mission);
            $totalCo2 += $empreinte['co2_kg'];

            if ($empreinte['transport_type'] === 'avion') {
                $co2Avion += $empreinte['co2_kg'];
            } else {
                $co2Terrestre += $empreinte['co2_kg'];
            }

            $dir = $mission->direction ?? 'Autre';
            if (!isset($parDirection[$dir])) {
                $parDirection[$dir] = 0;
            }
            $parDirection[$dir] += $empreinte['co2_kg'];
        }

        arsort($parDirection);
        $topDirections = array_slice(
            array_map(fn($dir, $co2) => ['direction' => $dir, 'co2_kg' => round($co2, 1)], array_keys($parDirection), $parDirection),
            0, 5
        );

        $missionsTerrestres = $missions->filter(fn($m) => !str_contains(strtolower($m->transport_type ?? ''), 'avion'));
        $suggestionsCount = $missions->filter(function ($m) {
            $dest = strtolower(trim($m->destination_ville ?? ''));
            $dist = self::DISTANCES_WILAYAS[$dest] ?? 300;
            $isAvion = str_contains(strtolower($m->transport_type ?? ''), 'avion');
            return $isAvion && $dist < 500;
        })->count();

        return [
            'total_co2_kg'       => round($totalCo2, 1),
            'equivalent_arbres'  => round($totalCo2 / self::KG_PAR_ARBRE_AN, 1),
            'co2_avion'          => round($co2Avion, 1),
            'co2_terrestre'      => round($co2Terrestre, 1),
            'top_directions'     => $topDirections,
            'missions_count'     => $missions->count(),
            'suggestions_terrestre' => $suggestionsCount,
            'periode'            => $periode,
        ];
    }
}
