<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<FarmMembership>
 */
class FarmMembershipFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'user_id' => User::factory(),
            'role' => 'owner',
            'is_active' => true,
            'joined_at' => now(),
        ];
    }
}
