<?php

namespace Tests\Feature\Api;

use App\Models\Expense;
use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ActivityLogTest extends TestCase
{
    use RefreshDatabase;

    public function test_sale_records_activity_log(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create(['currency' => 'USD']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'SALE-ACT-001',
            'status' => 'ready_for_sale',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/sales", [
            'rabbit_id' => $rabbit->id,
            'sold_on' => '2026-07-30',
            'sale_price' => 30,
        ])->assertCreated();

        $this->assertDatabaseHas('activity_logs', [
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'action' => 'sale.recorded',
            'description' => 'Recorded sale for SALE-ACT-001.',
        ]);
    }

    public function test_expense_records_activity_log_and_member_can_list_logs(): void
    {
        $user = User::factory()->create(['name' => 'Farm Manager']);
        $farm = Farm::factory()->create(['currency' => 'USD']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/expenses", [
            'category' => 'feed',
            'spent_on' => '2026-07-30',
            'amount' => 12.50,
        ])->assertCreated();

        $this->getJson("/api/v1/farms/{$farm->id}/activity")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.action', 'expense.recorded')
            ->assertJsonPath('data.0.actor_name', 'Farm Manager');
    }

    public function test_farm_settings_update_records_activity_log(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}", [
            'name' => 'Audit Rabbitry',
            'currency' => 'USD',
            'timezone' => 'Africa/Harare',
        ])->assertOk();

        $this->assertDatabaseHas('activity_logs', [
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'action' => 'farm.updated',
            'description' => 'Updated farm settings.',
        ]);
    }

    public function test_non_member_cannot_list_activity_logs(): void
    {
        $farm = Farm::factory()->create();
        Expense::factory()->create(['farm_id' => $farm->id]);

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/farms/{$farm->id}/activity")
            ->assertNotFound();
    }
}
