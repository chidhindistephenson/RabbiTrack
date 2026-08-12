<?php

namespace Database\Factories;

use App\Models\Expense;
use App\Models\Farm;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Expense>
 */
class ExpenseFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'recorded_by_id' => User::factory(),
            'category' => fake()->randomElement(Expense::CATEGORIES),
            'vendor' => fake()->optional()->company(),
            'spent_on' => fake()->date(),
            'amount' => fake()->randomFloat(2, 5, 250),
            'currency' => 'USD',
            'notes' => fake()->optional()->sentence(),
        ];
    }
}
