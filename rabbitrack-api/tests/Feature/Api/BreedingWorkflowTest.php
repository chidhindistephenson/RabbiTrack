<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\HealthEvent;
use App\Models\Mating;
use App\Models\PregnancyCheck;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BreedingWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_record_mating_and_generate_follow_up_tasks(): void
    {
        [$user, $farm] = $this->memberContext();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-0047',
            'sex' => 'female',
            'status' => 'available_for_breeding',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-0003',
            'sex' => 'male',
            'status' => 'available_for_breeding',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings", [
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-07-03 09:30:00',
            'outcome' => 'observed',
            'behavior_observed' => 'Observed successful fall-off.',
        ])
            ->assertCreated()
            ->assertJsonPath('data.doe_identifier', 'DOE-0047')
            ->assertJsonPath('data.buck_identifier', 'BUCK-0003')
            ->assertJsonPath('data.pregnancy_check_due_on', '2026-07-17')
            ->assertJsonPath('data.expected_kindling_on', '2026-08-03')
            ->assertJsonPath('data.nest_box_due_on', '2026-07-31')
            ->assertJsonPath('data.status', 'awaiting_pregnancy_check');

        $this->assertDatabaseHas('rabbits', [
            'id' => $doe->id,
            'status' => 'awaiting_pregnancy_check',
        ]);

        $this->assertDatabaseHas('tasks', [
            'farm_id' => $farm->id,
            'rabbit_id' => $doe->id,
            'type' => 'pregnancy_check',
            'due_on' => '2026-07-17 00:00:00',
        ]);

        $this->assertDatabaseHas('tasks', [
            'farm_id' => $farm->id,
            'rabbit_id' => $doe->id,
            'type' => 'nest_box_preparation',
            'due_on' => '2026-07-31 00:00:00',
        ]);
    }

    public function test_mating_requires_female_doe_and_male_buck(): void
    {
        [$user, $farm] = $this->memberContext();
        $notDoe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings", [
            'doe_id' => $notDoe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-07-03 09:30:00',
        ])->assertUnprocessable();
    }

    public function test_member_cannot_record_second_mating_for_unresolved_doe(): void
    {
        [$user, $farm] = $this->memberContext();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'awaiting_pregnancy_check',
        ]);
        $firstBuck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);
        $secondBuck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);
        Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $firstBuck->id,
            'status' => 'awaiting_pregnancy_check',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings", [
            'doe_id' => $doe->id,
            'buck_id' => $secondBuck->id,
            'mated_at' => '2026-07-10 09:30:00',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('doe_id');

        $this->assertDatabaseCount('matings', 1);
    }

    public function test_member_cannot_record_mating_with_sold_rabbit(): void
    {
        [$user, $farm] = $this->memberContext();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'sold',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'status' => 'available_for_breeding',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings", [
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-08-05 09:30:00',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('doe_id');
    }

    public function test_member_cannot_record_mating_with_unavailable_or_sick_rabbit(): void
    {
        [$user, $farm] = $this->memberContext();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'under_treatment',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'status' => 'available_for_breeding',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings", [
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-08-05 09:30:00',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('doe_id');

        $doe->update(['status' => 'available_for_breeding']);
        HealthEvent::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $buck->id,
            'recorded_by_id' => $user->id,
            'status' => 'open',
        ]);

        $this->postJson("/api/v1/farms/{$farm->id}/matings", [
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-08-05 09:30:00',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('buck_id');
    }

    public function test_member_cannot_record_mating_before_configured_breeding_age(): void
    {
        [$user, $farm] = $this->memberContext();
        $farm->update([
            'settings' => array_merge($farm->settings ?? [], [
                'breeding_min_doe_age_days' => 150,
                'breeding_min_buck_age_days' => 120,
            ]),
        ]);

        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'available_for_breeding',
            'date_of_birth' => '2026-06-01',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'status' => 'available_for_breeding',
            'date_of_birth' => '2025-12-01',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings", [
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-08-17 09:30:00',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('doe_id');

        $doe->update(['date_of_birth' => '2025-12-01']);
        $buck->update(['date_of_birth' => '2026-06-01']);

        $this->postJson("/api/v1/farms/{$farm->id}/matings", [
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-08-17 09:30:00',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('buck_id');
    }

    public function test_member_must_confirm_related_mating_risk(): void
    {
        [$user, $farm] = $this->memberContext();
        $mother = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
        ]);
        $father = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'available_for_breeding',
            'mother_id' => $mother->id,
            'father_id' => $father->id,
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'status' => 'available_for_breeding',
            'mother_id' => $mother->id,
            'father_id' => $father->id,
        ]);

        Sanctum::actingAs($user);

        $payload = [
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-07-03 09:30:00',
        ];

        $this->postJson("/api/v1/farms/{$farm->id}/matings", $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors('confirm_relationship_risk');

        $this->postJson("/api/v1/farms/{$farm->id}/matings", $payload + [
            'confirm_relationship_risk' => true,
        ])
            ->assertCreated()
            ->assertJsonPath('data.status', 'awaiting_pregnancy_check');
    }

    public function test_member_can_view_mating_detail(): void
    {
        [$user, $farm] = $this->memberContext();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-DETAIL',
            'sex' => 'female',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-DETAIL',
            'sex' => 'male',
        ]);
        $mating = Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
        ]);
        PregnancyCheck::factory()->create([
            'farm_id' => $farm->id,
            'mating_id' => $mating->id,
            'doe_id' => $doe->id,
            'result' => 'positive',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/matings/{$mating->id}")
            ->assertOk()
            ->assertJsonPath('data.doe_identifier', 'DOE-DETAIL')
            ->assertJsonPath('data.buck_identifier', 'BUCK-DETAIL')
            ->assertJsonCount(1, 'data.pregnancy_checks');
    }

    public function test_member_can_filter_matings_by_rabbit(): void
    {
        [$user, $farm] = $this->memberContext();
        $targetDoe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-FILTER',
            'sex' => 'female',
        ]);
        $targetBuck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-FILTER',
            'sex' => 'male',
        ]);
        $otherDoe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
        ]);
        $otherBuck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);
        Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $targetDoe->id,
            'buck_id' => $targetBuck->id,
            'mated_at' => '2026-07-30 09:00:00',
        ]);
        Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $otherDoe->id,
            'buck_id' => $otherBuck->id,
            'mated_at' => '2026-07-31 09:00:00',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/matings?rabbit_id={$targetBuck->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.doe_identifier', 'DOE-FILTER')
            ->assertJsonPath('data.0.buck_identifier', 'BUCK-FILTER');
    }

    public function test_member_can_delete_mating_without_litter_records(): void
    {
        [$user, $farm] = $this->memberContext();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'awaiting_pregnancy_check',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);
        $mating = Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'status' => 'awaiting_pregnancy_check',
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson("/api/v1/farms/{$farm->id}/matings/{$mating->id}")
            ->assertNoContent();

        $this->assertDatabaseMissing('matings', ['id' => $mating->id]);
        $this->assertDatabaseHas('rabbits', [
            'id' => $doe->id,
            'status' => 'available_for_breeding',
        ]);
    }

    public function test_member_cannot_repeat_completed_pregnancy_check(): void
    {
        [$user, $farm] = $this->memberContext();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'pregnant',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);
        $mating = Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'status' => 'pregnant',
            'pregnancy_check_due_on' => now()->subDay()->toDateString(),
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings/{$mating->id}/pregnancy-checks", [
            'checked_on' => '2026-07-16',
            'result' => 'pregnant',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('mating_id');

        $this->assertDatabaseCount('pregnancy_checks', 0);
    }

    public function test_member_cannot_record_kindling_for_sold_doe(): void
    {
        [$user, $farm] = $this->memberContext();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'sold',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/kindlings", [
            'doe_id' => $doe->id,
            'kindled_on' => '2026-08-05',
            'kits_born_alive' => 5,
            'birth_weight_value' => 0.450,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('doe_id');
    }

    public function test_non_member_cannot_record_mating_for_farm(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        $doe = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/matings", [
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-07-03 09:30:00',
        ])->assertNotFound();
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
