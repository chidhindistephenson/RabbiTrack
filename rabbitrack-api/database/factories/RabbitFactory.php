<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Rabbit;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Rabbit>
 */
class RabbitFactory extends Factory
{
    public function definition(): array
    {
        $sex = fake()->randomElement(['female', 'male']);

        return [
            'farm_id' => Farm::factory(),
            'identifier' => fake()->unique()->bothify($sex === 'female' ? 'DOE-####' : 'BUCK-####'),
            'name' => fake()->firstName(),
            'sex' => $sex,
            'date_of_birth' => fake()->dateTimeBetween('-2 years', '-8 weeks')->format('Y-m-d'),
            'breed' => fake()->randomElement(['New Zealand White', 'Californian', 'Rex', 'Mixed']),
            'colour' => fake()->randomElement(['White', 'Black', 'Grey', 'Brown']),
            'markings' => null,
            'weight_value' => fake()->randomFloat(3, 1.2, 5.4),
            'weight_unit' => 'kg',
            'tag_or_tattoo' => fake()->optional()->bothify('TAG-###'),
            'status' => 'growing',
            'current_location_id' => null,
            'mother_id' => null,
            'father_id' => null,
            'is_farm_born' => true,
            'supplier' => null,
            'acquired_at' => null,
            'acquisition_cost' => null,
            'notes' => null,
        ];
    }
}
