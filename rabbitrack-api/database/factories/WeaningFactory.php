<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Litter;
use App\Models\Rabbit;
use App\Models\User;
use App\Models\Weaning;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Weaning>
 */
class WeaningFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'litter_id' => Litter::factory(),
            'doe_id' => Rabbit::factory(),
            'recorded_by_id' => User::factory(),
            'weaned_on' => now()->toDateString(),
            'number_weaned' => 6,
            'average_weight_value' => 0.850,
            'weight_unit' => 'kg',
            'destination' => 'grow-out',
            'notes' => null,
        ];
    }
}
