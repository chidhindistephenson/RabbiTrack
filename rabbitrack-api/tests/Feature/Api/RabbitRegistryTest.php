<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Litter;
use App\Models\Location;
use App\Models\Rabbit;
use App\Models\Treatment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RabbitRegistryTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_register_rabbit_with_location_and_initial_movement(): void
    {
        [$user, $farm] = $this->memberContext();
        $location = Location::factory()->create([
            'farm_id' => $farm->id,
            'type' => 'cage',
            'name' => 'Cage 12',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'identifier' => 'DOE-0047',
            'name' => 'Mjolnir',
            'sex' => 'female',
            'date_of_birth' => '2025-02-14',
            'breed' => 'New Zealand White',
            'colour' => 'White',
            'weight_value' => 4.3,
            'status' => 'pregnant',
            'current_location_id' => $location->id,
        ])
            ->assertCreated()
            ->assertJsonPath('data.identifier', 'DOE-0047')
            ->assertJsonPath('data.tag_or_tattoo', 'DOE-0047')
            ->assertJsonPath('data.current_location_name', 'Cage 12');

        $this->assertDatabaseHas('rabbits', [
            'farm_id' => $farm->id,
            'identifier' => 'DOE-0047',
            'tag_or_tattoo' => 'DOE-0047',
            'current_location_id' => $location->id,
        ]);

        $this->assertDatabaseHas('rabbit_movements', [
            'farm_id' => $farm->id,
            'to_location_id' => $location->id,
            'reason' => 'Initial registration',
        ]);
    }

    public function test_rabbit_identifiers_are_unique_per_farm(): void
    {
        [$user, $farm] = $this->memberContext();
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-0047',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'identifier' => 'DOE-0047',
            'sex' => 'female',
            'status' => 'growing',
        ])->assertUnprocessable();
    }

    public function test_member_can_register_rabbit_with_normalized_text_fields(): void
    {
        [$user, $farm] = $this->memberContext();

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'identifier' => '  doe-custom-01  ',
            'name' => '  Luna  ',
            'sex' => 'female',
            'status' => 'growing',
            'breed' => '   ',
            'colour' => ' White ',
        ])
            ->assertCreated()
            ->assertJsonPath('data.identifier', 'DOE-CUSTOM-01')
            ->assertJsonPath('data.name', 'Luna')
            ->assertJsonPath('data.breed', null)
            ->assertJsonPath('data.colour', 'White');

        $this->assertDatabaseHas('rabbits', [
            'farm_id' => $farm->id,
            'identifier' => 'DOE-CUSTOM-01',
            'name' => 'Luna',
            'breed' => null,
            'colour' => 'White',
        ]);
    }

    public function test_member_can_register_weaned_kit_from_litter_origin(): void
    {
        [$user, $farm] = $this->memberContext();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'available_for_breeding',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'status' => 'available_for_breeding',
        ]);
        $litter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'kindled_on' => '2026-08-01',
            'status' => 'weaned',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'origin_type' => 'born_on_farm',
            'origin_litter_id' => $litter->id,
            'sex' => 'female',
            'status' => 'growing',
            'tag_or_tattoo' => 'KIT-01',
            'supplier' => 'Should be ignored',
            'acquisition_cost' => 20,
        ])
            ->assertCreated()
            ->assertJsonPath('data.origin_type', 'born_on_farm')
            ->assertJsonPath('data.origin_litter_id', $litter->id)
            ->assertJsonPath('data.mother_id', $doe->id)
            ->assertJsonPath('data.father_id', $buck->id)
            ->assertJsonPath('data.date_of_birth', '2026-08-01')
            ->assertJsonPath('data.supplier', null)
            ->assertJsonPath('data.acquisition_cost', null);
    }

    public function test_member_cannot_register_kit_from_unweaned_litter(): void
    {
        [$user, $farm] = $this->memberContext();
        $litter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'nursing',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'origin_type' => 'born_on_farm',
            'origin_litter_id' => $litter->id,
            'sex' => 'female',
            'status' => 'growing',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('origin_litter_id');
    }

    public function test_male_rabbit_cannot_be_registered_as_pregnant_or_nursing(): void
    {
        [$user, $farm] = $this->memberContext();

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'sex' => 'male',
            'status' => 'pregnant',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'sex' => 'male',
            'status' => 'nursing',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');
    }

    public function test_member_cannot_register_rabbit_as_sold(): void
    {
        [$user, $farm] = $this->memberContext();

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'sex' => 'female',
            'status' => 'sold',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');
    }

    public function test_rabbit_parents_must_match_parent_sex_when_registered(): void
    {
        [$user, $farm] = $this->memberContext();
        $male = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);
        $female = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'sex' => 'female',
            'status' => 'growing',
            'mother_id' => $male->id,
            'father_id' => $female->id,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['mother_id', 'father_id']);
    }

    public function test_rabbit_cannot_be_registered_with_terminal_parent(): void
    {
        [$user, $farm] = $this->memberContext();
        $soldMother = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'sold',
        ]);
        $deceasedFather = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'status' => 'deceased',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'sex' => 'female',
            'status' => 'growing',
            'mother_id' => $soldMother->id,
            'father_id' => $deceasedFather->id,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['mother_id', 'father_id']);
    }

    public function test_rabbit_cannot_use_same_parent_for_mother_and_father(): void
    {
        [$user, $farm] = $this->memberContext();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'sex' => 'female',
            'status' => 'growing',
            'mother_id' => $doe->id,
            'father_id' => $doe->id,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('father_id');
    }

    public function test_member_can_register_rabbit_without_identifier_and_api_assigns_one(): void
    {
        [$user, $farm] = $this->memberContext();
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-0047',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'name' => 'Freya',
            'sex' => 'female',
            'status' => 'growing',
        ])
            ->assertCreated()
            ->assertJsonPath('data.identifier', 'DOE-0048');

        $this->assertDatabaseHas('rabbits', [
            'farm_id' => $farm->id,
            'identifier' => 'DOE-0048',
            'name' => 'Freya',
        ]);
    }

    public function test_generated_rabbit_identifier_uses_highest_numeric_suffix(): void
    {
        [$user, $farm] = $this->memberContext();
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-9999',
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-10000',
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-CUSTOM',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'sex' => 'female',
            'status' => 'growing',
        ])
            ->assertCreated()
            ->assertJsonPath('data.identifier', 'DOE-10001');
    }

    public function test_generated_rabbit_identifier_prefix_follows_sex(): void
    {
        [$user, $farm] = $this->memberContext();

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'sex' => 'male',
            'status' => 'growing',
        ])
            ->assertCreated()
            ->assertJsonPath('data.identifier', 'BUCK-0001');

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits", [
            'sex' => 'unknown',
            'status' => 'growing',
        ])
            ->assertCreated()
            ->assertJsonPath('data.identifier', 'RAB-0001');
    }

    public function test_member_can_move_rabbit_between_locations(): void
    {
        [$user, $farm] = $this->memberContext();
        $fromLocation = Location::factory()->create([
            'farm_id' => $farm->id,
            'name' => 'Cage A',
        ]);
        $toLocation = Location::factory()->create([
            'farm_id' => $farm->id,
            'name' => 'Cage B',
        ]);
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'current_location_id' => $fromLocation->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}/movements", [
            'to_location_id' => $toLocation->id,
            'reason' => 'Moved to grow-out cage',
        ])
            ->assertCreated()
            ->assertJsonPath('data.to_location_id', $toLocation->id);

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'current_location_id' => $toLocation->id,
        ]);

        $this->assertDatabaseHas('rabbit_movements', [
            'rabbit_id' => $rabbit->id,
            'from_location_id' => $fromLocation->id,
            'to_location_id' => $toLocation->id,
            'reason' => 'Moved to grow-out cage',
        ]);
    }

    public function test_member_cannot_move_rabbit_to_current_location(): void
    {
        [$user, $farm] = $this->memberContext();
        $location = Location::factory()->create([
            'farm_id' => $farm->id,
            'name' => 'Cage A',
        ]);
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'current_location_id' => $location->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}/movements", [
            'to_location_id' => $location->id,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('to_location_id');

        $this->assertDatabaseMissing('rabbit_movements', [
            'rabbit_id' => $rabbit->id,
            'to_location_id' => $location->id,
        ]);
    }

    public function test_member_cannot_move_rabbit_to_inactive_location(): void
    {
        [$user, $farm] = $this->memberContext();
        $fromLocation = Location::factory()->create([
            'farm_id' => $farm->id,
            'name' => 'Cage A',
        ]);
        $inactiveLocation = Location::factory()->create([
            'farm_id' => $farm->id,
            'name' => 'Closed Cage',
            'is_active' => false,
        ]);
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'current_location_id' => $fromLocation->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}/movements", [
            'to_location_id' => $inactiveLocation->id,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('to_location_id');

        $this->assertDatabaseMissing('rabbit_movements', [
            'rabbit_id' => $rabbit->id,
            'to_location_id' => $inactiveLocation->id,
        ]);

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'current_location_id' => $fromLocation->id,
        ]);
    }

    public function test_member_cannot_move_sold_rabbit(): void
    {
        [$user, $farm] = $this->memberContext();
        $location = Location::factory()->create(['farm_id' => $farm->id]);
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'sold',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}/movements", [
            'to_location_id' => $location->id,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('rabbit_id');
    }

    public function test_member_can_update_rabbit_status(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'growing',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'ready_for_sale',
            'notes' => 'Reached target weight',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'ready_for_sale');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'status' => 'ready_for_sale',
            'notes' => 'Reached target weight',
        ]);
    }

    public function test_member_cannot_mark_rabbit_ready_for_sale_during_withdrawal(): void
    {
        Carbon::setTestNow('2026-08-10');
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'resting',
        ]);
        Treatment::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $rabbit->id,
            'withdrawal_days' => 14,
            'withdrawal_ends_on' => '2026-08-13',
            'status' => 'completed',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'ready_for_sale',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'status' => 'resting',
        ]);
        Carbon::setTestNow();
    }

    public function test_member_cannot_mark_rabbit_ready_for_sale_before_configured_age_or_weight(): void
    {
        Carbon::setTestNow('2026-08-17');
        [$user, $farm] = $this->memberContext();
        $farm->update([
            'settings' => array_merge($farm->settings ?? [], [
                'sale_ready_min_age_days' => 70,
                'sale_ready_min_weight_kg' => 2.0,
            ]),
        ]);
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'date_of_birth' => '2026-07-01',
            'weight_value' => 1.750,
            'status' => 'growing',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'ready_for_sale',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');

        $rabbit->update([
            'date_of_birth' => '2026-05-01',
            'weight_value' => 1.750,
        ]);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'ready_for_sale',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'status' => 'growing',
        ]);
        Carbon::setTestNow();
    }

    public function test_member_cannot_mark_rabbit_sold_without_sale_record(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'ready_for_sale',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'sold',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'status' => 'ready_for_sale',
        ]);
    }

    public function test_member_cannot_reactivate_sold_rabbit_status(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'sold',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'growing',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');
    }

    public function test_member_cannot_patch_sold_rabbit_profile(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'sold',
            'name' => 'Sold rabbit',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'sold',
            'name' => 'Changed after sale',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'name' => 'Sold rabbit',
        ]);
    }

    public function test_member_can_update_rabbit_profile_fields(): void
    {
        [$user, $farm] = $this->memberContext();
        $location = Location::factory()->create([
            'farm_id' => $farm->id,
            'name' => 'Breeder Cage',
        ]);
        $mother = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'identifier' => 'DOE-0001',
        ]);
        $father = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'identifier' => 'BUCK-0001',
        ]);
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'unknown',
            'status' => 'growing',
            'breed' => null,
            'colour' => null,
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'name' => '  Freya  ',
            'sex' => 'female',
            'status' => 'available_for_breeding',
            'date_of_birth' => '2025-12-10',
            'breed' => 'Rex',
            'colour' => 'Black',
            'weight_value' => 3.25,
            'weight_unit' => 'kg',
            'tag_or_tattoo' => '  TAG-77  ',
            'current_location_id' => $location->id,
            'mother_id' => $mother->id,
            'father_id' => $father->id,
            'notes' => 'Good condition',
        ])
            ->assertOk()
            ->assertJsonPath('data.name', 'Freya')
            ->assertJsonPath('data.sex', 'female')
            ->assertJsonPath('data.status', 'available_for_breeding')
            ->assertJsonPath('data.current_location_name', 'Breeder Cage');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'name' => 'Freya',
            'sex' => 'female',
            'status' => 'available_for_breeding',
            'breed' => 'Rex',
            'colour' => 'Black',
            'tag_or_tattoo' => 'TAG-77',
            'current_location_id' => $location->id,
            'mother_id' => $mother->id,
            'father_id' => $father->id,
        ]);
    }

    public function test_member_can_clear_optional_rabbit_profile_fields(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'name' => 'Atlas',
            'status' => 'growing',
            'breed' => 'Rex',
            'weight_value' => 2.500,
            'weight_unit' => 'kg',
            'tag_or_tattoo' => 'TAG-1',
            'notes' => 'Old note',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'growing',
            'name' => '',
            'breed' => '',
            'weight_value' => null,
            'tag_or_tattoo' => '',
            'notes' => '',
        ])
            ->assertOk()
            ->assertJsonPath('data.name', null)
            ->assertJsonPath('data.breed', null)
            ->assertJsonPath('data.weight_value', null)
            ->assertJsonPath('data.weight_unit', 'kg')
            ->assertJsonPath('data.tag_or_tattoo', null)
            ->assertJsonPath('data.notes', null);

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'name' => null,
            'breed' => null,
            'weight_value' => null,
            'weight_unit' => 'kg',
            'tag_or_tattoo' => null,
            'notes' => null,
        ]);
    }

    public function test_male_rabbit_cannot_be_updated_to_pregnant_or_nursing(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'status' => 'growing',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'nursing',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');
    }

    public function test_rabbit_cannot_be_updated_to_be_its_own_parent(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'growing',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'growing',
            'mother_id' => $rabbit->id,
            'father_id' => $rabbit->id,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['mother_id', 'father_id']);
    }

    public function test_rabbit_parents_must_match_parent_sex_when_updated(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'growing',
        ]);
        $male = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);
        $female = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'growing',
            'mother_id' => $male->id,
            'father_id' => $female->id,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['mother_id', 'father_id']);
    }

    public function test_rabbit_cannot_be_updated_with_new_terminal_parent(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'growing',
        ]);
        $soldMother = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'sold',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'growing',
            'mother_id' => $soldMother->id,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('mother_id');
    }

    public function test_rabbit_can_keep_existing_terminal_parent_when_profile_is_updated(): void
    {
        [$user, $farm] = $this->memberContext();
        $soldMother = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'sold',
        ]);
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'mother_id' => $soldMother->id,
            'status' => 'growing',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$rabbit->id}", [
            'status' => 'ready_for_sale',
            'mother_id' => $soldMother->id,
            'name' => 'Still editable',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'ready_for_sale');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'mother_id' => $soldMother->id,
            'name' => 'Still editable',
        ]);
    }

    public function test_recorded_mother_cannot_be_changed_away_from_female(): void
    {
        [$user, $farm] = $this->memberContext();
        $mother = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'growing',
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'mother_id' => $mother->id,
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$mother->id}", [
            'sex' => 'male',
            'status' => 'growing',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('sex');

        $this->assertDatabaseHas('rabbits', [
            'id' => $mother->id,
            'sex' => 'female',
        ]);
    }

    public function test_recorded_father_cannot_be_changed_away_from_male(): void
    {
        [$user, $farm] = $this->memberContext();
        $father = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'status' => 'growing',
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'father_id' => $father->id,
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/rabbits/{$father->id}", [
            'sex' => 'unknown',
            'status' => 'growing',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('sex');

        $this->assertDatabaseHas('rabbits', [
            'id' => $father->id,
            'sex' => 'male',
        ]);
    }

    public function test_member_can_filter_rabbits_by_status(): void
    {
        [$user, $farm] = $this->memberContext();
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-0047',
            'status' => 'pregnant',
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-0003',
            'status' => 'available_for_breeding',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/rabbits?status=pregnant")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.identifier', 'DOE-0047');
    }

    public function test_member_can_filter_rabbits_by_breed(): void
    {
        [$user, $farm] = $this->memberContext();
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-NZW',
            'breed' => 'New Zealand White',
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-REX',
            'breed' => 'Rex',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/rabbits?breed=New%20Zealand%20White")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.identifier', 'DOE-NZW');
    }

    public function test_member_can_search_rabbits_without_case_sensitivity(): void
    {
        [$user, $farm] = $this->memberContext();
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-0003',
            'name' => 'Atlas',
            'breed' => 'New Zealand White',
            'tag_or_tattoo' => 'SMOKE-8116',
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-0047',
            'name' => 'Freya',
            'breed' => 'Rex',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/rabbits?search=atlas")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.identifier', 'BUCK-0003');

        $this->getJson("/api/v1/farms/{$farm->id}/rabbits?search=smoke")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.identifier', 'BUCK-0003');
    }

    public function test_non_member_cannot_list_farm_rabbits(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        Rabbit::factory()->create(['farm_id' => $farm->id]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/rabbits")
            ->assertNotFound();
    }

    private function memberContext(): array
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();

        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        return [$user, $farm];
    }
}
