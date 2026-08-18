<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Litter;
use App\Models\Mating;
use App\Models\Rabbit;
use App\Models\Task;
use App\Models\User;
use App\Models\Weaning;
use App\Models\WeightRecord;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class KindlingWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_record_kindling_create_litter_and_weaning_task(): void
    {
        [$user, $farm, $mating, $doe] = $this->matingContext();
        Task::factory()->create([
            'farm_id' => $farm->id,
            'type' => 'nest_box_preparation',
            'status' => 'open',
            'related_type' => Mating::class,
            'related_id' => $mating->id,
            'rabbit_id' => $doe->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/kindlings", [
            'mating_id' => $mating->id,
            'kindled_on' => '2026-08-03',
            'kits_born_alive' => 8,
            'kits_stillborn' => 1,
            'kits_weak' => 2,
            'birth_weight_value' => 0.640,
            'nest_condition' => 'Clean and warm',
            'doe_condition' => 'Bright',
        ])
            ->assertCreated()
            ->assertJsonPath('data.doe_identifier', 'DOE-0047')
            ->assertJsonPath('data.buck_identifier', 'BUCK-0003')
            ->assertJsonPath('data.kits_born_alive', 8)
            ->assertJsonPath('data.current_live_count', 8)
            ->assertJsonPath('data.planned_weaning_on', '2026-09-07')
            ->assertJsonPath('data.status', 'nursing');

        $this->assertDatabaseHas('rabbits', [
            'id' => $doe->id,
            'status' => 'nursing',
        ]);

        $this->assertDatabaseHas('matings', [
            'id' => $mating->id,
            'status' => 'kindled',
        ]);

        $this->assertDatabaseHas('tasks', [
            'related_id' => $mating->id,
            'type' => 'nest_box_preparation',
            'status' => 'completed',
        ]);

        $this->assertDatabaseHas('tasks', [
            'farm_id' => $farm->id,
            'type' => 'weaning',
            'status' => 'open',
            'due_on' => '2026-09-07 00:00:00',
        ]);

        $this->assertDatabaseHas('weight_records', [
            'litter_id' => Litter::query()->firstOrFail()->id,
            'stage' => 'birth',
            'weight_value' => 0.640,
            'kit_count' => 8,
            'average_weight_value' => 0.080,
            'method' => 'Kindling record',
        ]);
    }

    public function test_kindling_can_be_recorded_without_mating_for_farm_doe(): void
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
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/kindlings", [
            'doe_id' => $doe->id,
            'kindled_on' => '2026-08-03',
            'kits_born_alive' => 5,
            'birth_weight_value' => 0.450,
        ])
            ->assertCreated()
            ->assertJsonPath('data.kits_born_alive', 5)
            ->assertJsonPath('data.buck_id', null);
    }

    public function test_kindling_creates_retirement_review_when_litter_threshold_is_reached(): void
    {
        [$user, $farm, $mating, $doe] = $this->matingContext();
        $farm->update([
            'settings' => array_merge($farm->settings ?? [], [
                'retirement_review_litter_threshold' => 2,
            ]),
        ]);
        Litter::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'status' => 'weaned',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/kindlings", [
            'mating_id' => $mating->id,
            'kindled_on' => '2026-08-03',
            'kits_born_alive' => 6,
            'birth_weight_value' => 0.600,
        ])->assertCreated();

        $this->assertDatabaseHas('tasks', [
            'farm_id' => $farm->id,
            'type' => 'retirement_review',
            'status' => 'open',
            'rabbit_id' => $doe->id,
            'priority' => 'high',
        ]);

        $this->assertDatabaseHas('rabbits', [
            'id' => $doe->id,
            'status' => 'nursing',
        ]);
    }

    public function test_kindling_does_not_duplicate_open_retirement_review(): void
    {
        [$user, $farm, $mating, $doe] = $this->matingContext();
        $farm->update([
            'settings' => array_merge($farm->settings ?? [], [
                'retirement_review_litter_threshold' => 1,
            ]),
        ]);
        Task::factory()->create([
            'farm_id' => $farm->id,
            'type' => 'retirement_review',
            'status' => 'open',
            'rabbit_id' => $doe->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/kindlings", [
            'mating_id' => $mating->id,
            'kindled_on' => '2026-08-03',
            'kits_born_alive' => 6,
            'birth_weight_value' => 0.600,
        ])->assertCreated();

        $this->assertSame(
            1,
            Task::query()
                ->where('farm_id', $farm->id)
                ->where('type', 'retirement_review')
                ->where('rabbit_id', $doe->id)
                ->where('status', 'open')
                ->count(),
        );
    }

    public function test_member_can_view_litter_detail(): void
    {
        [$user, $farm,, $doe] = $this->matingContext();
        $litter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'identifier' => 'LIT-DETAIL',
        ]);
        Weaning::factory()->create([
            'farm_id' => $farm->id,
            'litter_id' => $litter->id,
            'doe_id' => $doe->id,
            'number_weaned' => 7,
        ]);
        WeightRecord::factory()->create([
            'farm_id' => $farm->id,
            'litter_id' => $litter->id,
            'stage' => 'birth',
            'weight_value' => 3.125,
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}")
            ->assertOk()
            ->assertJsonPath('data.identifier', 'LIT-DETAIL')
            ->assertJsonCount(1, 'data.weanings')
            ->assertJsonCount(1, 'data.weights')
            ->assertJsonPath('data.weights.0.stage', 'birth');
    }

    public function test_non_member_cannot_record_kindling(): void
    {
        [, $farm, $mating] = $this->matingContext();
        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/v1/farms/{$farm->id}/kindlings", [
            'mating_id' => $mating->id,
            'kindled_on' => '2026-08-03',
            'kits_born_alive' => 8,
            'birth_weight_value' => 0.640,
        ])->assertNotFound();
    }

    private function matingContext(): array
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create([
            'settings' => [
                'gestation_days' => 31,
                'pregnancy_check_start_days' => 10,
                'pregnancy_check_end_days' => 14,
                'nest_box_lead_days' => 3,
                'weaning_days' => 35,
                'retirement_review_litter_threshold' => 0,
            ],
        ]);

        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-0047',
            'sex' => 'female',
            'status' => 'pregnant',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-0003',
            'sex' => 'male',
        ]);
        $mating = Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'recorded_by_id' => $user->id,
            'status' => 'pregnant',
        ]);

        return [$user, $farm, $mating, $doe];
    }
}
