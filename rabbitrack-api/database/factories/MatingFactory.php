<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Mating;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Mating>
 */
class MatingFactory extends Factory
{
    public function definition(): array
    {
        $matedAt = now();

        return [
            'farm_id' => Farm::factory(),
            'doe_id' => Rabbit::factory(),
            'buck_id' => Rabbit::factory(),
            'recorded_by_id' => User::factory(),
            'mated_at' => $matedAt,
            'outcome' => 'observed',
            'behavior_observed' => null,
            'pregnancy_check_due_on' => $matedAt->copy()->addDays(14)->toDateString(),
            'expected_kindling_on' => $matedAt->copy()->addDays(31)->toDateString(),
            'nest_box_due_on' => $matedAt->copy()->addDays(28)->toDateString(),
            'status' => 'awaiting_pregnancy_check',
            'notes' => null,
        ];
    }
}
