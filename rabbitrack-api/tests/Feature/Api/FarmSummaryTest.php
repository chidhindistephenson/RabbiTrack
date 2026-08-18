<?php

namespace Tests\Feature\Api;

use App\Models\Expense;
use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\HealthEvent;
use App\Models\Litter;
use App\Models\Mating;
use App\Models\Rabbit;
use App\Models\Sale;
use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FarmSummaryTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_view_farm_summary_counts(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create(['currency' => 'USD']);

        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        Rabbit::factory()->create(['farm_id' => $farm->id, 'sex' => 'female', 'status' => 'growing']);
        $saleBuck = Rabbit::factory()->create(['farm_id' => $farm->id, 'sex' => 'male', 'status' => 'ready_for_sale']);
        Rabbit::factory()->create(['farm_id' => $farm->id, 'sex' => 'male', 'status' => 'quarantined']);
        $pregnantDoe = Rabbit::factory()->create(['farm_id' => $farm->id, 'sex' => 'female', 'status' => 'pregnant']);
        $nursingDoe = Rabbit::factory()->create(['farm_id' => $farm->id, 'sex' => 'female', 'status' => 'nursing']);
        $soldRabbit = Rabbit::factory()->create(['farm_id' => $farm->id, 'status' => 'sold']);
        HealthEvent::factory()->create(['farm_id' => $farm->id, 'status' => 'open']);
        HealthEvent::factory()->create(['farm_id' => $farm->id, 'status' => 'resolved']);
        Task::factory()->create(['farm_id' => $farm->id, 'status' => 'open', 'due_on' => now()->subDay()->toDateString()]);
        Task::factory()->create(['farm_id' => $farm->id, 'status' => 'completed']);
        Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $pregnantDoe->id,
            'buck_id' => $saleBuck->id,
            'status' => 'pregnant',
            'expected_kindling_on' => now()->addDays(5)->toDateString(),
        ]);
        Litter::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $nursingDoe->id,
            'buck_id' => $saleBuck->id,
            'status' => 'nursing',
            'current_live_count' => 7,
        ]);
        Sale::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $soldRabbit->id,
            'sold_by_id' => $user->id,
            'sale_price' => 25.50,
            'currency' => 'USD',
        ]);
        Expense::factory()->create([
            'farm_id' => $farm->id,
            'recorded_by_id' => $user->id,
            'amount' => 10.25,
            'currency' => 'USD',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/summary")
            ->assertOk()
            ->assertJsonPath('data.active_rabbits', 5)
            ->assertJsonPath('data.does', 3)
            ->assertJsonPath('data.bucks', 2)
            ->assertJsonPath('data.live_kits', 7)
            ->assertJsonPath('data.ready_for_sale', 1)
            ->assertJsonPath('data.health_alerts', 1)
            ->assertJsonPath('data.quarantined', 1)
            ->assertJsonPath('data.pregnant_does', 1)
            ->assertJsonPath('data.nursing_does', 1)
            ->assertJsonPath('data.open_tasks', 1)
            ->assertJsonPath('data.overdue_tasks', 1)
            ->assertJsonPath('data.expected_kindlings', 1)
            ->assertJsonPath('data.total_sales', 1)
            ->assertJsonPath('data.sales_revenue', '25.50')
            ->assertJsonPath('data.total_expenses', '10.25')
            ->assertJsonPath('data.net_income', '15.25')
            ->assertJsonPath('data.currency', 'USD');
    }

    public function test_non_member_cannot_view_farm_summary(): void
    {
        $farm = Farm::factory()->create();

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/farms/{$farm->id}/summary")
            ->assertNotFound();
    }
}
