<?php

namespace Tests\Feature\Api;

use App\Models\Expense;
use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ExpenseWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_record_expense(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create(['currency' => 'USD']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/expenses", [
            'category' => 'feed',
            'vendor' => 'Town Feed Store',
            'spent_on' => '2026-07-30',
            'amount' => 18.75,
            'notes' => 'Pellets and hay',
        ])
            ->assertCreated()
            ->assertJsonPath('data.category', 'feed')
            ->assertJsonPath('data.amount', '18.75')
            ->assertJsonPath('data.currency', 'USD');

        $this->assertDatabaseHas('expenses', [
            'farm_id' => $farm->id,
            'recorded_by_id' => $user->id,
            'category' => 'feed',
            'vendor' => 'Town Feed Store',
        ]);
    }

    public function test_member_can_list_expenses(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);
        Expense::factory()->create([
            'farm_id' => $farm->id,
            'recorded_by_id' => $user->id,
            'category' => 'medicine',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/expenses")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.category', 'medicine');
    }

    public function test_member_can_view_expense_summary_by_category(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create(['currency' => 'USD']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);
        Expense::factory()->create([
            'farm_id' => $farm->id,
            'recorded_by_id' => $user->id,
            'category' => 'feed',
            'amount' => 10,
        ]);
        Expense::factory()->create([
            'farm_id' => $farm->id,
            'recorded_by_id' => $user->id,
            'category' => 'feed',
            'amount' => 15.50,
        ]);
        Expense::factory()->create([
            'farm_id' => $farm->id,
            'recorded_by_id' => $user->id,
            'category' => 'medicine',
            'amount' => 4.25,
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/expenses/summary")
            ->assertOk()
            ->assertJsonPath('data.total', '29.75')
            ->assertJsonPath('data.currency', 'USD')
            ->assertJsonPath('data.by_category.0.category', 'feed')
            ->assertJsonPath('data.by_category.0.total', '25.50')
            ->assertJsonPath('data.by_category.0.count', 2)
            ->assertJsonPath('data.by_category.1.category', 'medicine')
            ->assertJsonPath('data.by_category.1.total', '4.25')
            ->assertJsonPath('data.by_category.1.count', 1);
    }

    public function test_non_member_cannot_record_expense(): void
    {
        $farm = Farm::factory()->create();

        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/v1/farms/{$farm->id}/expenses", [
            'category' => 'feed',
            'spent_on' => '2026-07-30',
            'amount' => 18.75,
        ])->assertNotFound();
    }
}
