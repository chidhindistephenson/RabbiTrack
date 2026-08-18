<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Litter;
use App\Models\LitterFoster;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<LitterFoster>
 */
class LitterFosterFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'from_litter_id' => Litter::factory(),
            'to_litter_id' => Litter::factory(),
            'recorded_by_id' => User::factory(),
            'fostered_on' => now()->toDateString(),
            'kit_count' => 1,
            'reason' => 'Balancing litter size',
            'notes' => null,
        ];
    }
}
