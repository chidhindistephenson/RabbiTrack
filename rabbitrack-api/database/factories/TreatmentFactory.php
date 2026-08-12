<?php

namespace Database\Factories;

use App\Models\Farm;
use App\Models\HealthEvent;
use App\Models\Rabbit;
use App\Models\Treatment;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Treatment>
 */
class TreatmentFactory extends Factory
{
    public function definition(): array
    {
        return [
            'farm_id' => Farm::factory(),
            'health_event_id' => HealthEvent::factory(),
            'rabbit_id' => Rabbit::factory(),
            'prescribed_by_id' => User::factory(),
            'medication' => 'Example medication',
            'dosage' => '1 ml',
            'route' => 'oral',
            'frequency' => 'daily',
            'started_on' => now()->toDateString(),
            'ended_on' => null,
            'withdrawal_days' => 0,
            'withdrawal_ends_on' => null,
            'status' => 'active',
            'notes' => null,
        ];
    }
}
