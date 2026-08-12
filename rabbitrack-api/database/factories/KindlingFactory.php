<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Kindling;
use App\Models\Litter;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Kindling>
 */
class KindlingFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'mating_id' => null,
            'litter_id' => Litter::factory(),
            'doe_id' => Rabbit::factory(),
            'recorded_by_id' => User::factory(),
            'kindled_on' => now()->toDateString(),
            'kits_born_alive' => 6,
            'kits_stillborn' => 0,
            'kits_weak' => 0,
            'nest_condition' => null,
            'doe_condition' => null,
            'notes' => null,
        ];
    }
}
