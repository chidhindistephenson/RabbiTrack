<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Litter;
use App\Models\Mating;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BreedingCalendarTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_view_breeding_calendar_events(): void
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
            'identifier' => 'DOE-CAL',
            'sex' => 'female',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-CAL',
            'sex' => 'male',
        ]);
        Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-08-01',
            'pregnancy_check_due_on' => '2026-08-15',
            'nest_box_due_on' => '2026-08-29',
            'expected_kindling_on' => '2026-09-01',
        ]);
        Litter::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'LIT-CAL',
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'kindled_on' => '2026-08-10',
            'planned_weaning_on' => '2026-09-14',
            'kits_born_alive' => 8,
            'current_live_count' => 7,
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/reports/breeding/calendar?start=2026-08-01&end=2026-09-30")
            ->assertOk()
            ->assertJsonCount(6, 'data')
            ->assertJsonPath('data.0.type', 'mating')
            ->assertJsonPath('data.0.date', '2026-08-01')
            ->assertJsonPath('data.0.rabbit_identifier', 'DOE-CAL')
            ->assertJsonPath('data.5.type', 'weaning')
            ->assertJsonPath('data.5.title', 'Planned weaning: LIT-CAL');
    }

    public function test_member_can_export_breeding_calendar_as_csv(): void
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
            'identifier' => 'DOE-CAL',
            'sex' => 'female',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-CAL',
            'sex' => 'male',
        ]);
        Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-08-01',
            'pregnancy_check_due_on' => '2026-08-15',
            'nest_box_due_on' => '2026-08-29',
            'expected_kindling_on' => '2026-09-01',
        ]);

        Sanctum::actingAs($user);

        $response = $this->get("/api/v1/farms/{$farm->id}/reports/breeding/calendar?start=2026-08-01&end=2026-09-30&format=csv");

        $response->assertOk()
            ->assertHeader('content-type', 'text/csv; charset=UTF-8');
        $this->assertStringContainsString('date,type,title,subtitle,rabbit_identifier,related_type,related_id', $response->getContent());
        $this->assertStringContainsString('2026-08-15,pregnancy_check,"Pregnancy check: DOE-CAL","Mated with BUCK-CAL",DOE-CAL,mating', $response->getContent());
    }

    public function test_non_member_cannot_view_breeding_calendar(): void
    {
        $farm = Farm::factory()->create();

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/farms/{$farm->id}/reports/breeding/calendar")
            ->assertNotFound();
    }
}
