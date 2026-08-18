<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FarmManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_farm_and_become_owner(): void
    {
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $this->postJson('/api/v1/farms', [
            'name' => 'Second Rabbitry',
            'currency' => 'usd',
        ])
            ->assertCreated()
            ->assertJsonPath('data.name', 'Second Rabbitry')
            ->assertJsonPath('data.currency', 'USD')
            ->assertJsonPath('data.role', 'owner')
            ->assertJsonPath('data.settings.sale_ready_min_age_days', 70)
            ->assertJsonPath('data.settings.sale_ready_min_weight_kg', 2)
            ->assertJsonPath('data.settings.breeding_min_doe_age_days', 0)
            ->assertJsonPath('data.settings.breeding_min_buck_age_days', 0);

        $this->assertDatabaseHas('farms', [
            'name' => 'Second Rabbitry',
            'currency' => 'USD',
        ]);

        $this->assertDatabaseHas('farm_memberships', [
            'user_id' => $user->id,
            'role' => 'owner',
            'is_active' => true,
        ]);
    }

    public function test_owner_can_update_farm_settings(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create(['currency' => 'USD']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}", [
            'name' => 'Updated Rabbitry',
            'currency' => 'usd',
            'timezone' => 'Africa/Harare',
            'sale_ready_min_age_days' => 84,
            'sale_ready_min_weight_kg' => 2.4,
            'retirement_review_litter_threshold' => 6,
            'breeding_min_doe_age_days' => 150,
            'breeding_min_buck_age_days' => 120,
        ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Updated Rabbitry')
            ->assertJsonPath('data.currency', 'USD')
            ->assertJsonPath('data.timezone', 'Africa/Harare')
            ->assertJsonPath('data.settings.sale_ready_min_age_days', 84)
            ->assertJsonPath('data.settings.sale_ready_min_weight_kg', 2.4)
            ->assertJsonPath('data.settings.retirement_review_litter_threshold', 6)
            ->assertJsonPath('data.settings.breeding_min_doe_age_days', 150)
            ->assertJsonPath('data.settings.breeding_min_buck_age_days', 120);

        $this->assertDatabaseHas('farms', [
            'id' => $farm->id,
            'name' => 'Updated Rabbitry',
            'currency' => 'USD',
            'timezone' => 'Africa/Harare',
        ]);
    }

    public function test_manager_cannot_update_farm_settings(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}", [
            'name' => 'Blocked Rabbitry',
            'currency' => 'USD',
            'timezone' => 'Africa/Harare',
        ])->assertNotFound();
    }
}
