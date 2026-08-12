<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Location;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Location>
 */
class LocationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'parent_id' => null,
            'type' => 'house',
            'name' => 'House '.fake()->numberBetween(1, 9),
            'code' => Str::upper(fake()->unique()->bothify('LOC-###')),
            'capacity' => null,
            'is_active' => true,
            'notes' => null,
        ];
    }
}
