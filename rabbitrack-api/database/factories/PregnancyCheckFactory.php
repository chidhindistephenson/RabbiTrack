<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Mating;
use App\Models\PregnancyCheck;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PregnancyCheck>
 */
class PregnancyCheckFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'mating_id' => Mating::factory(),
            'doe_id' => Rabbit::factory(),
            'examiner_id' => User::factory(),
            'checked_on' => now()->toDateString(),
            'result' => 'pregnant',
            'notes' => null,
        ];
    }
}
