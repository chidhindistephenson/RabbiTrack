<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Rabbit;
use App\Models\RabbitMovement;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<RabbitMovement>
 */
class RabbitMovementFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'rabbit_id' => Rabbit::factory(),
            'from_location_id' => null,
            'to_location_id' => null,
            'user_id' => User::factory(),
            'moved_at' => now(),
            'reason' => 'Initial placement',
            'notes' => null,
        ];
    }
}
