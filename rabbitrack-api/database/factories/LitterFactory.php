<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Litter;
use App\Models\Rabbit;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Litter>
 */
class LitterFactory extends Factory
{
    public function definition(): array
    {
        $kindledOn = now()->toDateString();

        return [
            'farm_id' => Farm::factory(),
            'identifier' => Str::upper(fake()->unique()->bothify('LIT-####')),
            'doe_id' => Rabbit::factory(),
            'buck_id' => Rabbit::factory(),
            'mating_id' => null,
            'kindled_on' => $kindledOn,
            'kits_born_alive' => 6,
            'kits_stillborn' => 0,
            'kits_weak' => 0,
            'current_live_count' => 6,
            'planned_weaning_on' => now()->addDays(35)->toDateString(),
            'status' => 'newborn',
            'notes' => null,
        ];
    }
}
