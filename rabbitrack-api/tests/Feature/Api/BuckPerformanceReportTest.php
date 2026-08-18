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

class BuckPerformanceReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_view_buck_performance_report(): void
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
            'identifier' => 'DOE-BUCK',
            'sex' => 'female',
        ]);
        $buck = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'BUCK-PERF',
            'name' => 'Atlas',
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
            'status' => 'awaiting_pregnancy_check',
        ]);
        PregnancyCheck::factory()->create([
            'farm_id' => $farm->id,
            'mating_id' => $secondMating->id,
            'doe_id' => $doe->id,
            'result' => 'not_pregnant',
        ]);
        $litter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'LIT-BUCK',
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'mating_id' => $firstMating->id,
            'kits_born_alive' => 9,
            'current_live_count' => 8,
            'status' => 'weaned',
        ]);
        Weaning::factory()->create([
            'farm_id' => $farm->id,
            'litter_id' => $litter->id,
            'doe_id' => $doe->id,
            'recorded_by_id' => $user->id,
            'number_weaned' => 8,
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/reports/bucks/performance")
            ->assertOk()
            ->assertJsonPath('data.buck_count', 1)
            ->assertJsonPath('data.total_matings', 2)
            ->assertJsonPath('data.confirmed_pregnancies', 1)
            ->assertJsonPath('data.conception_rate', 50)
            ->assertJsonPath('data.litters', 1)
            ->assertJsonPath('data.kits_born_alive', 9)
            ->assertJsonPath('data.kits_weaned', 8)
            ->assertJsonPath('data.average_litter_size', 9)
            ->assertJsonPath('data.weaning_rate', 88.9)
            ->assertJsonPath('data.bucks.0.identifier', 'BUCK-PERF');
    }

    public function test_non_member_cannot_view_buck_performance_report(): void
    {
        $farm = Farm::factory()->create();

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/farms/{$farm->id}/reports/bucks/performance")
            ->assertNotFound();
    }

    public function test_member_can_filter_buck_performance_report_by_period(): void
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

        $this->getJson("/api/v1/farms/{$farm->id}/reports/bucks/performance?start=2026-08-01&end=2026-08-31")
            ->assertOk()
            ->assertJsonPath('data.period.start', '2026-08-01')
            ->assertJsonPath('data.period.end', '2026-08-31')
            ->assertJsonPath('data.total_matings', 1)
            ->assertJsonPath('data.litters', 1)
            ->assertJsonPath('data.kits_born_alive', 6)
            ->assertJsonPath('data.kits_weaned', 5)
            ->assertJsonPath('data.bucks.0.matings', 1);
    }

    public function test_member_can_export_buck_performance_report_as_csv(): void
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
            'identifier' => 'BUCK-CSV',
            'sex' => 'male',
        ]);

        Sanctum::actingAs($user);

        $this->get("/api/v1/farms/{$farm->id}/reports/bucks/performance?format=csv")
            ->assertOk()
            ->assertHeader('Content-Type', 'text/csv; charset=utf-8')
            ->assertSee('identifier,name,breed,status,matings', false)
            ->assertSee('BUCK-CSV', false);
    }
}
