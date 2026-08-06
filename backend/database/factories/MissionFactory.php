<?php

namespace Database\Factories;

use App\Models\Mission;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class MissionFactory extends Factory
{
    protected $model = Mission::class;

    public function definition(): array
    {
        $depart = $this->faker->dateTimeBetween('+1 week', '+2 months');
        $retour = (clone $depart)->modify('+'.rand(1, 7).' days');

        return [
            'user_id' => User::factory(),
            'created_by' => fn (array $attrs) => $attrs['user_id'],
            'titre' => $this->faker->sentence(4),
            'objet_mission' => $this->faker->sentence(6),
            'destination' => $this->faker->city(),
            'destination_ville' => $this->faker->city(),
            'date_depart' => $depart->format('Y-m-d'),
            'date_retour' => $retour->format('Y-m-d'),
            'type_mission' => $this->faker->randomElement(['nationale', 'internationale']),
            'priorite' => $this->faker->randomElement(['normale', 'urgente']),
            'statut' => 'brouillon',
            'budget_previsionnel' => $this->faker->randomFloat(2, 5000, 200000),
        ];
    }
}
