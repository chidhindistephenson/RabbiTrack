<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Litter;
use App\Models\Mating;
use App\Models\PregnancyCheck;
use App\Models\Rabbit;
use App\Models\User;
use App\Models\Weaning;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DoePerformanceReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_view_doe_performance_report(): void
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
            'identifier' => 'DOE-PERF',
            'name' => 'Athena',
            'sex' => 'female',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-PERF',
            'sex' => 'male',
        ]);
        $firstMating = Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'status' => 'kindled',
        ]);
        $secondMating = Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'status' => 'pregnant',
        ]);
        PregnancyCheck::factory()->create([
            'farm_id' => $farm->id,
            'mating_id' => $secondMating->id,
            'doe_id' => $doe->id,
            'result' => 'pregnant',
        ]);
        $firstLitter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'LIT-DOE-1',
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mating_id' => $firstMating->id,
            'kindled_on' => '2026-07-01',
            'kits_born_alive' => 8,
            'current_live_count' => 7,
            'status' => 'weaned',
        ]);
        $secondLitter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'LIT-DOE-2',
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'kindled_on' => '2026-08-01',
            'kits_born_alive' => 6,
            'current_live_count' => 6,
            'status' => 'nursing',
        ]);
        Weaning::factory()->create([
            'farm_id' => $farm->id,
            'litter_id' => $firstLitter->id,
            'doe_id' => $doe->id,
            'recorded_by_id' => $user->id,
            'number_weaned' => 7,
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/reports/does/performance")
            ->assertOk()
            ->assertJsonPath('data.doe_count', 1)
            ->assertJsonPath('data.total_matings', 2)
            ->assertJsonPath('data.confirmed_pregnancies', 2)
            ->assertJsonPath('data.kindlings', 2)
            ->assertJsonPath('data.completed_litters', 1)
            ->assertJsonPath('data.kits_born_alive', 14)
            ->assertJsonPath('data.kits_weaned', 7)
            ->assertJsonPath('data.average_litter_size', 7)
            ->assertJsonPath('data.survival_rate', 50)
            ->assertJsonPath('data.does.0.identifier', 'DOE-PERF')
            ->assertJsonPath('data.does.0.average_litter_interval_days', 31);
    }

    public function test_non_member_cannot_view_doe_performance_report(): void
    {
        $farm = Farm::factory()->create();

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/farms/{$farm->id}/reports/does/performance")
            ->assertNotFound();
    }

    public function test_member_can_filter_doe_performance_report_by_period(): void
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
            'identifier' => 'DOE-FILTER',
            'sex' => 'female',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-FILTER',
            'sex' => 'male',
        ]);
        Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-06-01 10:00:00',
            'status' => 'kindled',
        ]);
        $currentMating = Mating::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mated_at' => '2026-08-01 16:00:00',
            'status' => 'kindled',
        ]);
        Litter::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'kindled_on' => '2026-06-30',
            'kits_born_alive' => 10,
            'current_live_count' => 10,
        ]);
        $currentLitter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mating_id' => $currentMating->id,
            'kindled_on' => '2026-08-31',
            'kits_born_alive' => 6,
            'current_live_count' => 5,
            'status' => 'weaned',
        ]);
        Weaning::factory()->create([
            'farm_id' => $farm->id,
            'litter_id' => $currentLitter->id,
            'doe_id' => $doe->id,
            'recorded_by_id' => $user->id,
            'number_weaned' => 5,
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/reports/does/performance?start=2026-08-01&end=2026-08-31")
            ->assertOk()
            ->assertJsonPath('data.period.start', '2026-08-01')
            ->assertJsonPath('data.period.end', '2026-08-31')
            ->assertJsonPath('data.total_matings', 1)
            ->assertJsonPath('data.kindlings', 1)
            ->assertJsonPath('data.kits_born_alive', 6)
            ->assertJsonPath('data.kits_weaned', 5)
            ->assertJsonPath('data.does.0.matings', 1);
    }

    public function test_member_can_export_doe_performance_report_as_csv(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-CSV',
            'sex' => 'female',
        ]);

        Sanctum::actingAs($user);

        $this->get("/api/v1/farms/{$farm->id}/reports/does/performance?format=csv")
            ->assertOk()
            ->assertHeader('Content-Type', 'text/csv; charset=utf-8')
            ->assertSee('identifier,name,breed,status,matings', false)
            ->assertSee('DOE-CSV', false);
    }
}
