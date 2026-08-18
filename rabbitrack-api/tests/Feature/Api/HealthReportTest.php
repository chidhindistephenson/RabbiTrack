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

class HealthReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_view_health_report(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create(['timezone' => 'Africa/Harare']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-HEALTH',
            'status' => 'under_treatment',
        ]);
        Rabbit::factory()->create(['farm_id' => $farm->id, 'status' => 'deceased']);
        Rabbit::factory()->create(['farm_id' => $farm->id, 'status' => 'culled']);

        $event = HealthEvent::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $rabbit->id,
            'recorded_by_id' => $user->id,
            'severity' => 'severe',
            'body_system' => 'respiratory',
            'diagnosis' => 'Snuffles',
            'status' => 'open',
        ]);
        HealthEvent::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $rabbit->id,
            'recorded_by_id' => $user->id,
            'status' => 'resolved',
            'severity' => 'mild',
        ]);
        Treatment::factory()->create([
            'farm_id' => $farm->id,
            'health_event_id' => $event->id,
            'rabbit_id' => $rabbit->id,
            'prescribed_by_id' => $user->id,
            'medication' => 'Oxytet',
            'withdrawal_days' => 14,
            'withdrawal_ends_on' => now()->addDays(5)->toDateString(),
            'status' => 'active',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/reports/health")
            ->assertOk()
            ->assertJsonPath('data.active_health_events', 1)
            ->assertJsonPath('data.active_treatments', 1)
            ->assertJsonPath('data.withdrawal_restrictions', 1)
            ->assertJsonPath('data.mortality_count', 2)
            ->assertJsonPath('data.events_by_severity.0.label', 'severe')
            ->assertJsonPath('data.events_by_body_system.0.label', 'respiratory')
            ->assertJsonPath('data.events_by_diagnosis.0.label', 'Snuffles')
            ->assertJsonPath('data.medicine_use.0.label', 'Oxytet')
            ->assertJsonPath('data.withdrawals.0.rabbit_identifier', 'DOE-HEALTH');
    }

    public function test_member_can_export_health_report_as_csv(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create(['timezone' => 'Africa/Harare']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-HEALTH',
            'status' => 'under_treatment',
        ]);
        $event = HealthEvent::factory()->create([
            'farm_id' => $farm->id,
            'rabbit_id' => $rabbit->id,
            'recorded_by_id' => $user->id,
            'severity' => 'severe',
            'body_system' => 'respiratory',
            'diagnosis' => 'Snuffles',
            'status' => 'open',
        ]);
        Treatment::factory()->create([
            'farm_id' => $farm->id,
            'health_event_id' => $event->id,
            'rabbit_id' => $rabbit->id,
            'prescribed_by_id' => $user->id,
            'medication' => 'Oxytet',
            'withdrawal_days' => 14,
            'withdrawal_ends_on' => now()->addDays(5)->toDateString(),
            'status' => 'active',
        ]);

        Sanctum::actingAs($user);

        $response = $this->get("/api/v1/farms/{$farm->id}/reports/health?format=csv");

        $response->assertOk()
            ->assertHeader('content-type', 'text/csv; charset=UTF-8');
        $this->assertStringContainsString('summary,active_health_events,1', $response->getContent());
        $this->assertStringContainsString('events_by_severity,severe,1', $response->getContent());
        $this->assertStringContainsString('withdrawals,,,DOE-HEALTH,Oxytet', $response->getContent());
    }

    public function test_non_member_cannot_view_health_report(): void
    {
        $farm = Farm::factory()->create();

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/farms/{$farm->id}/reports/health")
            ->assertNotFound();
    }
}
