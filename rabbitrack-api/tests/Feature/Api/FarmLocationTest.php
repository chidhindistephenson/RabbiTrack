<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Location;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FarmLocationTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_only_sees_their_farms(): void
    {
        $user = User::factory()->create();
        $myFarm = Farm::factory()->create(['name' => 'My Rabbitry']);
        Farm::factory()->create(['name' => 'Other Rabbitry']);

        FarmMembership::factory()->create([
            'farm_id' => $myFarm->id,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/v1/farms')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $myFarm->id);
    }

    public function test_member_can_create_location_for_their_farm(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();

        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/locations", [
            'type' => 'house',
            'name' => 'House 1',
            'code' => 'H1',
        ])
            ->assertCreated()
            ->assertJsonPath('data.name', 'House 1')
            ->assertJsonPath('data.code', 'H1');

        $this->assertDatabaseHas('locations', [
            'farm_id' => $farm->id,
            'name' => 'House 1',
            'code' => 'H1',
        ]);
    }

    public function test_location_text_fields_are_normalized(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();

        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/locations", [
            'type' => 'cage',
            'name' => '  Grow out cage  ',
            'code' => '  cage-a1  ',
            'capacity' => 4,
            'notes' => '   ',
        ])
            ->assertCreated()
            ->assertJsonPath('data.name', 'Grow out cage')
            ->assertJsonPath('data.code', 'CAGE-A1')
            ->assertJsonPath('data.notes', null)
            ->assertJsonPath('data.is_active', true);

        $this->assertDatabaseHas('locations', [
            'farm_id' => $farm->id,
            'name' => 'Grow out cage',
            'code' => 'CAGE-A1',
            'notes' => null,
            'is_active' => true,
        ]);
    }

    public function test_member_can_create_inactive_location(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();

        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/locations", [
            'type' => 'cage',
            'name' => 'Closed cage',
            'is_active' => false,
        ])
            ->assertCreated()
            ->assertJsonPath('data.is_active', false);

        $this->assertDatabaseHas('locations', [
            'farm_id' => $farm->id,
            'name' => 'Closed cage',
            'is_active' => false,
        ]);
    }

    public function test_location_code_uniqueness_uses_normalized_code(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();

        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        Location::factory()->create([
            'farm_id' => $farm->id,
            'code' => 'CAGE-A1',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/locations", [
            'type' => 'cage',
            'name' => 'Duplicate cage',
            'code' => ' cage-a1 ',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('code');
    }

    public function test_member_can_view_location_occupancy(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        $location = Location::factory()->create([
            'farm_id' => $farm->id,
            'name' => 'Cage 7',
            'capacity' => 2,
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-CAGE-7',
            'current_location_id' => $location->id,
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/locations")
            ->assertOk()
            ->assertJsonPath('data.0.occupied_count', 1);

        $this->getJson("/api/v1/farms/{$farm->id}/locations/{$location->id}")
            ->assertOk()
            ->assertJsonPath('data.name', 'Cage 7')
            ->assertJsonPath('data.occupied_count', 1)
            ->assertJsonCount(1, 'data.rabbits');
    }

    public function test_member_can_update_location(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        $location = Location::factory()->create([
            'farm_id' => $farm->id,
            'type' => 'cage',
            'name' => 'Old cage',
            'code' => 'OLD',
            'capacity' => 4,
            'is_active' => true,
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/locations/{$location->id}", [
            'type' => 'door',
            'name' => '  Door 7  ',
            'code' => ' door-7 ',
            'capacity' => 2,
            'is_active' => false,
            'notes' => '  Closed for repair  ',
        ])
            ->assertOk()
            ->assertJsonPath('data.type', 'door')
            ->assertJsonPath('data.name', 'Door 7')
            ->assertJsonPath('data.code', 'DOOR-7')
            ->assertJsonPath('data.is_active', false)
            ->assertJsonPath('data.notes', 'Closed for repair');

        $this->assertDatabaseHas('locations', [
            'id' => $location->id,
            'type' => 'door',
            'name' => 'Door 7',
            'code' => 'DOOR-7',
            'capacity' => 2,
            'is_active' => false,
            'notes' => 'Closed for repair',
        ]);
    }

    public function test_member_cannot_update_location_capacity_below_occupancy(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        $location = Location::factory()->create([
            'farm_id' => $farm->id,
            'capacity' => 3,
        ]);
        Rabbit::factory()->count(2)->create([
            'farm_id' => $farm->id,
            'current_location_id' => $location->id,
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/locations/{$location->id}", [
            'type' => $location->type,
            'name' => $location->name,
            'code' => $location->code,
            'capacity' => 1,
            'is_active' => true,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('capacity');
    }

    public function test_member_cannot_deactivate_occupied_location(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        $location = Location::factory()->create([
            'farm_id' => $farm->id,
            'is_active' => true,
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'current_location_id' => $location->id,
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/locations/{$location->id}", [
            'type' => $location->type,
            'name' => $location->name,
            'code' => $location->code,
            'capacity' => $location->capacity,
            'is_active' => false,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('is_active');
    }

    public function test_non_member_cannot_access_farm_locations(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        Location::factory()->create(['farm_id' => $farm->id]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/locations")
            ->assertNotFound();
    }
}
