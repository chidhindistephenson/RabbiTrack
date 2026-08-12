<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\HealthEvent;
use App\Models\Rabbit;
use App\Models\Treatment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class HealthEventTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_record_health_event_and_mark_rabbit_under_treatment(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-0047',
            'status' => 'growing',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/health-events", [
            'rabbit_id' => $rabbit->id,
            'observed_on' => '2026-07-30',
            'symptoms' => 'Reduced appetite',
            'diagnosis' => 'Digestive upset',
            'severity' => 'moderate',
            'body_system' => 'digestive',
            'isolation_required' => false,
        ])
            ->assertCreated()
            ->assertJsonPath('data.rabbit_identifier', 'DOE-0047')
            ->assertJsonPath('data.severity', 'moderate');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'status' => 'under_treatment',
        ]);
    }

    public function test_isolation_required_marks_rabbit_quarantined(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/health-events", [
            'rabbit_id' => $rabbit->id,
            'observed_on' => '2026-07-30',
            'symptoms' => 'Nasal discharge',
            'severity' => 'severe',
            'isolation_required' => true,
        ])->assertCreated();

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'status' => 'quarantined',
        ]);
    }

    public function test_member_cannot_record_health_event_for_sold_rabbit(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'sold',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/health-events", [
            'rabbit_id' => $rabbit->id,
            'observed_on' => '2026-08-05',
            'symptoms' => 'Reduced appetite',
            'severity' => 'moderate',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('rabbit_id');
    }

    public function test_member_can_add_treatment_and_calculate_withdrawal_end(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);
        $event = HealthEvent::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $rabbit->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/health-events/{$event->id}/treatments", [
            'medication' => 'Example antibiotic',
            'dosage' => '1 ml',
            'route' => 'oral',
            'frequency' => 'daily',
            'started_on' => '2026-07-30',
            'withdrawal_days' => 14,
        ])
            ->assertCreated()
            ->assertJsonPath('data.medication', 'Example antibiotic')
            ->assertJsonPath('data.withdrawal_ends_on', '2026-08-13');

        $this->assertDatabaseHas('treatments', [
            'health_event_id' => $event->id,
            'withdrawal_days' => 14,
            'withdrawal_ends_on' => '2026-08-13 00:00:00',
        ]);
    }

    public function test_member_can_filter_health_events_by_rabbit(): void
    {
        [$user, $farm] = $this->memberContext();
        $targetRabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-HEALTH',
        ]);
        $otherRabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);
        HealthEvent::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $targetRabbit->id,
            'observed_on' => '2026-07-30',
        ]);
        HealthEvent::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $otherRabbit->id,
            'observed_on' => '2026-07-31',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/health-events?rabbit_id={$targetRabbit->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.rabbit_identifier', 'DOE-HEALTH');
    }

    public function test_member_can_resolve_health_event_and_restore_rabbit(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'under_treatment',
        ]);
        $event = HealthEvent::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $rabbit->id,
            'status' => 'open',
        ]);
        Treatment::factory()->create([
            'farm_id' => $farm->id,
            'health_event_id' => $event->id,
            'rabbit_id' => $rabbit->id,
            'status' => 'active',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/health-events/{$event->id}", [
            'action' => 'resolve',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'resolved');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'status' => 'resting',
        ]);
        $this->assertDatabaseHas('treatments', [
            'health_event_id' => $event->id,
            'status' => 'completed',
        ]);
    }

    public function test_non_member_cannot_record_health_event(): void
    {
        $farm = Farm::factory()->create();
        $rabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);

        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/v1/farms/{$farm->id}/health-events", [
            'rabbit_id' => $rabbit->id,
            'observed_on' => '2026-07-30',
            'symptoms' => 'Reduced appetite',
            'severity' => 'moderate',
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
