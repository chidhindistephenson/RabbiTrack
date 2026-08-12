<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Rabbit;
use App\Models\User;
use App\Models\WeightRecord;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<WeightRecord>
 */
class WeightRecordFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'rabbit_id' => Rabbit::factory(),
            'litter_id' => null,
            'recorded_by_id' => User::factory(),
            'weighed_on' => now()->toDateString(),
            'weight_value' => fake()->randomFloat(3, 0.5, 5.5),
            'weight_unit' => 'kg',
            'method' => 'scale',
            'notes' => null,
        ];
    }
}
