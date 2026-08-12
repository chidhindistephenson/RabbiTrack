<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Rabbit;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SaleWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_record_rabbit_sale_and_mark_rabbit_sold(): void
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
            'identifier' => 'SALE-001',
            'status' => 'ready_for_sale',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/sales", [
            'rabbit_id' => $rabbit->id,
            'buyer_name' => 'Local buyer',
            'sold_on' => '2026-07-30',
            'sale_price' => 25.50,
        ])
            ->assertCreated()
            ->assertJsonPath('data.rabbit_identifier', 'SALE-001')
            ->assertJsonPath('data.sale_price', '25.50');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'status' => 'sold',
            'current_location_id' => null,
        ]);
    }

    public function test_member_can_list_sales(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);
        $rabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);

        $farm->sales()->create([
            'rabbit_id' => $rabbit->id,
            'sold_by_id' => $user->id,
            'sold_on' => '2026-07-30',
            'sale_price' => 20,
            'currency' => 'USD',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/sales")
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_member_can_filter_sales_by_rabbit(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);
        $targetRabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'SALE-FILTER',
        ]);
        $otherRabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);

        Sale::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $targetRabbit->id,
            'sold_by_id' => $user->id,
            'sold_on' => '2026-07-30',
            'currency' => 'USD',
        ]);
        Sale::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $otherRabbit->id,
            'sold_by_id' => $user->id,
            'sold_on' => '2026-07-31',
            'currency' => 'USD',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/sales?rabbit_id={$targetRabbit->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.rabbit_identifier', 'SALE-FILTER');
    }

    public function test_member_can_view_sales_summary(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create(['currency' => 'USD']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);
        Sale::factory()->create([
            'farm_id' => $farm->id,
            'sold_by_id' => $user->id,
            'sale_price' => 25,
            'currency' => 'USD',
        ]);
        Sale::factory()->create([
            'farm_id' => $farm->id,
            'sold_by_id' => $user->id,
            'sale_price' => 35,
            'currency' => 'USD',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/sales/summary")
            ->assertOk()
            ->assertJsonPath('data.total_revenue', '60.00')
            ->assertJsonPath('data.sale_count', 2)
            ->assertJsonPath('data.average_sale', '30.00')
            ->assertJsonPath('data.currency', 'USD');
    }

    public function test_member_cannot_sell_terminal_status_rabbit(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'sold',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/sales", [
            'rabbit_id' => $rabbit->id,
            'sold_on' => '2026-07-30',
            'sale_price' => 25.50,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('rabbit_id');

        $this->assertDatabaseCount('sales', 0);
    }

    public function test_sale_price_must_be_greater_than_zero(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'ready_for_sale',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/sales", [
            'rabbit_id' => $rabbit->id,
            'sold_on' => '2026-07-30',
            'sale_price' => 0,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('sale_price');

        $this->assertDatabaseCount('sales', 0);
    }

    public function test_sale_text_fields_are_normalized(): void
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
            'status' => 'ready_for_sale',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/sales", [
            'rabbit_id' => $rabbit->id,
            'buyer_name' => '  Local buyer  ',
            'buyer_phone' => '  +263 77 123 4567  ',
            'sold_on' => '2026-07-30',
            'sale_price' => 25.50,
            'currency' => ' usd ',
            'notes' => '   ',
        ])
            ->assertCreated()
            ->assertJsonPath('data.buyer_name', 'Local buyer')
            ->assertJsonPath('data.buyer_phone', '+263 77 123 4567')
            ->assertJsonPath('data.currency', 'USD')
            ->assertJsonPath('data.notes', null);

        $this->assertDatabaseHas('sales', [
            'rabbit_id' => $rabbit->id,
            'buyer_name' => 'Local buyer',
            'buyer_phone' => '+263 77 123 4567',
            'currency' => 'USD',
            'notes' => null,
        ]);
    }
}
