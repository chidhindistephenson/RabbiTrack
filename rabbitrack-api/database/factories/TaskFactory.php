<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Task;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Task>
 */
class TaskFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'assigned_to_id' => null,
            'type' => 'manual',
            'title' => fake()->sentence(3),
            'description' => null,
            'due_on' => now()->toDateString(),
            'due_time' => null,
            'priority' => 'normal',
            'status' => 'open',
            'related_type' => null,
            'related_id' => null,
            'rabbit_id' => null,
            'litter_id' => null,
            'location_id' => null,
            'metadata' => null,
        ];
    }
}
