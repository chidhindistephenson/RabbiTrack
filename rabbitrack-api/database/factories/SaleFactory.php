<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\Rabbit;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Sale>
 */
class SaleFactory extends Factory
{
    public function definition(): array
    {
        $farm = Farm::factory();

        return [
            'farm_id' => $farm,
            'rabbit_id' => Rabbit::factory()->for($farm),
            'sold_by_id' => User::factory(),
            'buyer_name' => fake()->name(),
            'buyer_phone' => fake()->phoneNumber(),
            'sold_on' => fake()->date(),
            'sale_price' => fake()->randomFloat(2, 10, 120),
            'currency' => 'USD',
            'notes' => fake()->optional()->sentence(),
        ];
    }
}
