<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\HealthEvent;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<HealthEvent>
 */
class HealthEventFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'rabbit_id' => Rabbit::factory(),
            'recorded_by_id' => User::factory(),
            'observed_on' => now()->toDateString(),
            'symptoms' => 'Reduced appetite',
            'diagnosis' => null,
            'severity' => 'moderate',
            'body_system' => 'digestive',
            'isolation_required' => false,
            'status' => 'open',
            'notes' => null,
        ];
    }
}
