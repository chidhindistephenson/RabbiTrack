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
            ->assertJsonPath('data.role', 'owner');

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
        ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Updated Rabbitry')
            ->assertJsonPath('data.currency', 'USD')
            ->assertJsonPath('data.timezone', 'Africa/Harare');

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
