<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Mating;
use App\Models\Rabbit;
use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PregnancyCheckWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_pregnant_result_updates_mating_and_doe_and_completes_check_task(): void
    {
        [$user, $farm, $mating] = $this->matingContext();
        Task::factory()->create([
            'farm_id' => $farm->id,
            'type' => 'pregnancy_check',
            'status' => 'open',
            'related_type' => Mating::class,
            'related_id' => $mating->id,
            'rabbit_id' => $mating->doe_id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings/{$mating->id}/pregnancy-checks", [
            'checked_on' => '2026-07-15',
            'result' => 'pregnant',
            'notes' => 'Confirmed by palpation.',
        ])
            ->assertCreated()
            ->assertJsonPath('data.result', 'pregnant')
            ->assertJsonPath('data.mating_status', 'pregnant')
            ->assertJsonPath('data.doe_status', 'pregnant');

        $this->assertDatabaseHas('pregnancy_checks', [
            'mating_id' => $mating->id,
            'result' => 'pregnant',
        ]);

        $this->assertDatabaseHas('tasks', [
            'related_id' => $mating->id,
            'type' => 'pregnancy_check',
            'status' => 'completed',
        ]);
    }

    public function test_not_pregnant_result_makes_doe_available_and_cancels_nest_box_task(): void
    {
        [$user, $farm, $mating] = $this->matingContext();
        Task::factory()->create([
            'farm_id' => $farm->id,
            'type' => 'nest_box_preparation',
            'status' => 'open',
            'related_type' => Mating::class,
            'related_id' => $mating->id,
            'rabbit_id' => $mating->doe_id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings/{$mating->id}/pregnancy-checks", [
            'checked_on' => '2026-07-15',
            'result' => 'not_pregnant',
        ])
            ->assertCreated()
            ->assertJsonPath('data.mating_status', 'not_pregnant')
            ->assertJsonPath('data.doe_status', 'available_for_breeding');

        $this->assertDatabaseHas('tasks', [
            'related_id' => $mating->id,
            'type' => 'nest_box_preparation',
            'status' => 'cancelled',
        ]);
    }

    public function test_member_can_revise_latest_pregnancy_decision(): void
    {
        [$user, $farm, $mating] = $this->matingContext();

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings/{$mating->id}/pregnancy-checks", [
            'checked_on' => now()->toDateString(),
            'result' => 'pregnant',
        ])->assertCreated();

        $this->patchJson("/api/v1/farms/{$farm->id}/matings/{$mating->id}/pregnancy-checks/latest", [
            'checked_on' => now()->toDateString(),
            'result' => 'not_pregnant',
            'notes' => 'Second inspection changed the decision.',
        ])
            ->assertOk()
            ->assertJsonPath('data.result', 'not_pregnant')
            ->assertJsonPath('data.mating_status', 'not_pregnant')
            ->assertJsonPath('data.doe_status', 'available_for_breeding');

        $this->assertDatabaseCount('pregnancy_checks', 1);
        $this->assertDatabaseHas('pregnancy_checks', [
            'mating_id' => $mating->id,
            'result' => 'not_pregnant',
        ]);
    }

    public function test_uncertain_result_schedules_repeat_check(): void
    {
        [$user, $farm, $mating] = $this->matingContext([
            'repeat_pregnancy_check_days' => 4,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings/{$mating->id}/pregnancy-checks", [
            'checked_on' => '2026-07-15',
            'result' => 'uncertain',
        ])
            ->assertCreated()
            ->assertJsonPath('data.mating_status', 'uncertain')
            ->assertJsonPath('data.doe_status', 'awaiting_pregnancy_check');

        $this->assertDatabaseHas('tasks', [
            'related_id' => $mating->id,
            'type' => 'pregnancy_check',
            'status' => 'open',
        ]);

        $this->assertDatabaseHas('matings', [
            'id' => $mating->id,
            'status' => 'uncertain',
            'pregnancy_check_due_on' => now()->addDays(4)->toDateString().' 00:00:00',
        ]);
    }

    public function test_member_cannot_record_pregnancy_check_before_due_date(): void
    {
        [$user, $farm, $mating] = $this->matingContext();
        $mating->update([
            'pregnancy_check_due_on' => now()->addDay()->toDateString(),
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings/{$mating->id}/pregnancy-checks", [
            'checked_on' => now()->toDateString(),
            'result' => 'pregnant',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('pregnancy_check_due_on');

        $this->assertDatabaseCount('pregnancy_checks', 0);
    }

    public function test_non_member_cannot_record_pregnancy_check(): void
    {
        [, $farm, $mating] = $this->matingContext();
        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/v1/farms/{$farm->id}/matings/{$mating->id}/pregnancy-checks", [
            'checked_on' => '2026-07-15',
            'result' => 'pregnant',
        ])->assertNotFound();
    }

    private function matingContext(array $settings = []): array
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create([
            'settings' => array_merge([
                'gestation_days' => 31,
                'pregnancy_check_start_days' => 10,
                'pregnancy_check_end_days' => 14,
                'nest_box_lead_days' => 3,
            ], $settings),
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
            'status' => 'awaiting_pregnancy_check',
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
            'mated_at' => now()->subDays(15),
            'pregnancy_check_due_on' => now()->subDay()->toDateString(),
            'status' => 'awaiting_pregnancy_check',
        ]);

        return [$user, $farm, $mating];
    }
}
