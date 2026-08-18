<?php

namespace Database\Factories;

use App\Models\Farm;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Farm>
 */
class FarmFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->company().' Rabbitry',
            'code' => Str::upper(fake()->unique()->bothify('FARM-####')),
            'timezone' => 'Africa/Johannesburg',
            'currency' => 'USD',
            'settings' => [
                'gestation_days' => 31,
                'pregnancy_check_start_days' => 10,
                'pregnancy_check_end_days' => 14,
                'nest_box_lead_days' => 3,
                'weaning_days' => 35,
                'sale_ready_min_age_days' => 0,
                'sale_ready_min_weight_kg' => null,
                'retirement_review_litter_threshold' => 0,
                'breeding_min_doe_age_days' => 0,
                'breeding_min_buck_age_days' => 0,
            ],
        ];
    }
}
