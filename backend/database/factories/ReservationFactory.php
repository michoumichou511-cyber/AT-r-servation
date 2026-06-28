<?php

namespace Database\Factories;

use App\Models\Mission;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ReservationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'mission_id' => Mission::factory(),
            'user_id' => User::factory(),
            'type' => fake()->randomElement(['transport', 'hebergement', 'restauration']),
            'statut' => 'en_attente',
            'date_reservation' => fake()->dateTimeBetween('+1 week', '+2 months'),
            'montant_estime' => fake()->randomFloat(2, 5000, 50000),
            'devise' => 'DZD',
            'notes' => fake()->optional()->sentence(),
        ];
    }

    public function confirmee(): static
    {
        return $this->state(fn () => [
            'statut' => 'confirmee',
            'numero_confirmation' => 'RES-' . fake()->unique()->numerify('######'),
        ]);
    }
}
