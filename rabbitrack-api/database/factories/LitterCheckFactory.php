<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Litter;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\LitterCheck>
 */
class LitterCheckFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'litter_id' => Litter::factory(),
            'recorded_by_id' => null,
            'checked_on' => now()->toDateString(),
            'live_count' => 6,
            'dead_count' => 0,
            'weak_count' => 0,
            'suspected_cause' => null,
            'nest_observation' => fake()->optional()->sentence(4),
            'corrective_action' => null,
            'notes' => null,
        ];
    }
}
