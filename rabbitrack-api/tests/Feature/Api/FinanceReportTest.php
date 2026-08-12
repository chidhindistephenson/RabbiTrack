<?php

namespace Tests\Feature\Api;

use App\Models\Expense;
use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Rabbit;
use App\Models\Sale;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FinanceReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_view_monthly_finance_report(): void
    {
        CarbonImmutable::setTestNow('2026-07-30 12:00:00');

        $user = User::factory()->create();
        $farm = Farm::factory()->create(['currency' => 'USD']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);
        $rabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);

        Sale::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $rabbit->id,
            'sold_by_id' => $user->id,
            'sold_on' => '2026-07-05',
            'sale_price' => 40,
        ]);
        Sale::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $rabbit->id,
            'sold_by_id' => $user->id,
            'sold_on' => '2026-06-10',
            'sale_price' => 20,
        ]);
        Expense::factory()->create([
            'farm_id' => $farm->id,
            'recorded_by_id' => $user->id,
            'spent_on' => '2026-07-15',
            'amount' => 12.50,
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/reports/finance/monthly")
            ->assertOk()
            ->assertJsonPath('data.currency', 'USD')
            ->assertJsonCount(6, 'data.months')
            ->assertJsonPath('data.months.4.month', '2026-06')
            ->assertJsonPath('data.months.4.revenue', '20.00')
            ->assertJsonPath('data.months.4.expenses', '0.00')
            ->assertJsonPath('data.months.5.month', '2026-07')
            ->assertJsonPath('data.months.5.revenue', '40.00')
            ->assertJsonPath('data.months.5.expenses', '12.50')
            ->assertJsonPath('data.months.5.net_income', '27.50');

        CarbonImmutable::setTestNow();
    }

    public function test_non_member_cannot_view_monthly_finance_report(): void
    {
        $farm = Farm::factory()->create();

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/farms/{$farm->id}/reports/finance/monthly")
            ->assertNotFound();
    }
}
