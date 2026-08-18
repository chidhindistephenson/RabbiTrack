<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Litter;
use App\Models\Location;
use App\Models\Rabbit;
use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WeaningWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_record_weaning_and_complete_weaning_task(): void
    {
        [$user, $farm, $litter, $doe] = $this->litterContext();
        Task::factory()->create([
            'farm_id' => $farm->id,
            'type' => 'weaning',
            'status' => 'open',
            'related_type' => Litter::class,
            'related_id' => $litter->id,
            'rabbit_id' => $doe->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}/weanings", [
            'weaned_on' => '2026-09-07',
            'number_weaned' => 7,
            'average_weight_value' => 0.850,
            'weight_unit' => 'kg',
            'destination' => 'Grow-out cages',
        ])
            ->assertCreated()
            ->assertJsonPath('data.number_weaned', 7)
            ->assertJsonPath('data.litter_status', 'weaned')
            ->assertJsonPath('data.doe_status', 'available_for_breeding');

        $this->assertDatabaseHas('weanings', [
            'litter_id' => $litter->id,
            'number_weaned' => 7,
            'average_weight_value' => 0.850,
            'destination' => 'Grow-out cages',
        ]);

        $this->assertDatabaseHas('weight_records', [
            'litter_id' => $litter->id,
            'stage' => 'weaning',
            'weight_value' => 5.950,
            'kit_count' => 7,
            'average_weight_value' => 0.850,
            'method' => 'Weaning record',
        ]);

        $this->assertDatabaseHas('litters', [
            'id' => $litter->id,
            'current_live_count' => 7,
            'status' => 'weaned',
        ]);

        $this->assertDatabaseHas('tasks', [
            'related_id' => $litter->id,
            'type' => 'weaning',
            'status' => 'completed',
        ]);

        $this->assertDatabaseHas('tasks', [
            'related_id' => $litter->id,
            'type' => 'kit_identification',
            'title' => "Identify/tag kits from {$litter->identifier}",
            'status' => 'open',
        ]);

        $this->assertEquals(
            '2026-09-14',
            Task::query()
                ->where('related_id', $litter->id)
                ->where('type', 'kit_identification')
                ->firstOrFail()
                ->due_on
                ->toDateString(),
        );
    }

    public function test_non_member_cannot_record_weaning(): void
    {
        [, $farm, $litter] = $this->litterContext();
        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}/weanings", [
            'weaned_on' => '2026-09-07',
            'number_weaned' => 7,
        ])->assertNotFound();
    }

    public function test_member_can_convert_weaned_kits_to_rabbits(): void
    {
        [$user, $farm, $litter, $doe] = $this->litterContext([
            'current_live_count' => 7,
            'status' => 'weaned',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'identifier' => 'BUCK-0001',
        ]);
        $location = Location::factory()->create([
            'farm_id' => $farm->id,
            'type' => 'cage',
            'is_active' => true,
        ]);
        $litter->update(['buck_id' => $buck->id]);
        Task::factory()->create([
            'farm_id' => $farm->id,
            'type' => 'kit_identification',
            'status' => 'open',
            'related_type' => Litter::class,
            'related_id' => $litter->id,
            'rabbit_id' => $doe->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}/conversions", [
            'count' => 7,
            'sex' => 'unknown',
            'breed' => 'New Zealand White',
            'colour' => 'White',
            'current_location_id' => $location->id,
        ])
            ->assertCreated()
            ->assertJsonPath('data.converted_count', 7)
            ->assertJsonPath('data.remaining_count', 0)
            ->assertJsonPath('data.rabbits.0.origin_litter_id', $litter->id)
            ->assertJsonPath('data.rabbits.0.mother_id', $doe->id)
            ->assertJsonPath('data.rabbits.0.father_id', $buck->id);

        $this->assertSame(
            7,
            Rabbit::query()->where('origin_litter_id', $litter->id)->count(),
        );
        $this->assertDatabaseHas('rabbits', [
            'farm_id' => $farm->id,
            'identifier' => 'RAB-0001',
            'origin_litter_id' => $litter->id,
            'mother_id' => $doe->id,
            'father_id' => $buck->id,
            'origin_type' => 'born_on_farm',
            'is_farm_born' => true,
            'tag_or_tattoo' => 'RAB-0001',
            'current_location_id' => $location->id,
        ]);
        $this->assertDatabaseHas('tasks', [
            'related_id' => $litter->id,
            'type' => 'kit_identification',
            'status' => 'completed',
        ]);
    }

    public function test_member_can_record_litter_check_and_update_live_count(): void
    {
        [$user, $farm, $litter] = $this->litterContext([
            'current_live_count' => 8,
            'status' => 'nursing',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}/checks", [
            'checked_on' => '2026-08-20',
            'live_count' => 7,
            'dead_count' => 1,
            'weak_count' => 2,
            'suspected_cause' => 'Chilling',
            'nest_observation' => 'Nest damp near corner',
            'corrective_action' => 'Changed bedding',
            'notes' => 'Doe calm.',
        ])
            ->assertCreated()
            ->assertJsonPath('data.live_count', 7)
            ->assertJsonPath('data.dead_count', 1)
            ->assertJsonPath('data.litter_live_count', 7);

        $this->assertDatabaseHas('litter_checks', [
            'litter_id' => $litter->id,
            'live_count' => 7,
            'dead_count' => 1,
            'weak_count' => 2,
            'suspected_cause' => 'Chilling',
        ]);

        $this->assertDatabaseHas('litters', [
            'id' => $litter->id,
            'current_live_count' => 7,
        ]);

        $this->getJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}")
            ->assertOk()
            ->assertJsonPath('data.checks.0.live_count', 7)
            ->assertJsonPath('data.current_live_count', 7);
    }

    public function test_member_cannot_record_impossible_litter_check_counts(): void
    {
        [$user, $farm, $litter] = $this->litterContext([
            'current_live_count' => 4,
            'status' => 'nursing',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}/checks", [
            'checked_on' => '2026-08-20',
            'live_count' => 4,
            'dead_count' => 1,
            'weak_count' => 1,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('live_count');

        $this->assertDatabaseMissing('litter_checks', [
            'litter_id' => $litter->id,
        ]);
    }

    public function test_member_can_record_foster_and_update_litter_counts(): void
    {
        [$user, $farm, $source] = $this->litterContext([
            'identifier' => 'LIT-SOURCE',
            'current_live_count' => 8,
            'status' => 'nursing',
        ]);
        $destination = Litter::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'LIT-DEST',
            'current_live_count' => 5,
            'status' => 'nursing',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$source->id}/fosters", [
            'to_litter_id' => $destination->id,
            'fostered_on' => '2026-08-18',
            'kit_count' => 2,
            'reason' => 'Balance litter sizes',
            'notes' => 'Accepted after nest rub.',
        ])
            ->assertCreated()
            ->assertJsonPath('data.kit_count', 2)
            ->assertJsonPath('data.from_litter_identifier', 'LIT-SOURCE')
            ->assertJsonPath('data.to_litter_identifier', 'LIT-DEST')
            ->assertJsonPath('data.from_live_count', 6)
            ->assertJsonPath('data.to_live_count', 7);

        $this->assertDatabaseHas('litter_fosters', [
            'from_litter_id' => $source->id,
            'to_litter_id' => $destination->id,
            'kit_count' => 2,
            'reason' => 'Balance litter sizes',
        ]);

        $this->assertDatabaseHas('litters', [
            'id' => $source->id,
            'current_live_count' => 6,
        ]);

        $this->assertDatabaseHas('litters', [
            'id' => $destination->id,
            'current_live_count' => 7,
        ]);

        $this->getJson("/api/v1/farms/{$farm->id}/litters/{$source->id}")
            ->assertOk()
            ->assertJsonPath('data.fosters_out.0.kit_count', 2)
            ->assertJsonPath('data.fosters_out.0.to_litter_identifier', 'LIT-DEST');

        $this->getJson("/api/v1/farms/{$farm->id}/litters/{$destination->id}")
            ->assertOk()
            ->assertJsonPath('data.fosters_in.0.kit_count', 2)
            ->assertJsonPath('data.fosters_in.0.from_litter_identifier', 'LIT-SOURCE');
    }

    public function test_member_cannot_foster_more_than_source_live_count(): void
    {
        [$user, $farm, $source] = $this->litterContext([
            'current_live_count' => 1,
            'status' => 'nursing',
        ]);
        $destination = Litter::factory()->create([
            'farm_id' => $farm->id,
            'current_live_count' => 4,
            'status' => 'nursing',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$source->id}/fosters", [
            'to_litter_id' => $destination->id,
            'fostered_on' => '2026-08-18',
            'kit_count' => 2,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('kit_count');

        $this->assertDatabaseMissing('litter_fosters', [
            'from_litter_id' => $source->id,
        ]);
    }

    public function test_member_cannot_foster_to_same_litter(): void
    {
        [$user, $farm, $litter] = $this->litterContext([
            'current_live_count' => 4,
            'status' => 'nursing',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}/fosters", [
            'to_litter_id' => $litter->id,
            'fostered_on' => '2026-08-18',
            'kit_count' => 1,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('to_litter_id');
    }

    public function test_member_cannot_convert_more_than_remaining_weaned_kits(): void
    {
        [$user, $farm, $litter] = $this->litterContext([
            'current_live_count' => 2,
            'status' => 'weaned',
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'unknown',
            'origin_litter_id' => $litter->id,
            'origin_type' => 'born_on_farm',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}/conversions", [
            'count' => 2,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('count');
    }

    private function litterContext(array $litterOverrides = []): array
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();

        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'nursing',
        ]);

        $litter = Litter::factory()->create(array_merge([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'current_live_count' => 8,
            'status' => 'nursing',
        ], $litterOverrides));

        return [$user, $farm, $litter, $doe];
    }
}
