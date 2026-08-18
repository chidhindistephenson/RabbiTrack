<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Litter;
use App\Models\Rabbit;
use App\Models\User;
use App\Models\Weaning;
use App\Models\WeightRecord;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LitterPerformanceReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_view_litter_performance_report(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        $doe = Rabbit::factory()->create(['farm_id' => $farm->id, 'identifier' => 'DOE-LIT']);
        $buck = Rabbit::factory()->create(['farm_id' => $farm->id, 'identifier' => 'BUCK-LIT']);
        $litter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'LIT-PERF',
            'doe_id' => $doe->id,
            'buck_id' => $buck->id,
            'kits_born_alive' => 8,
            'kits_stillborn' => 2,
            'current_live_count' => 6,
        ]);
        Weaning::factory()->create([
            'farm_id' => $farm->id,
            'litter_id' => $litter->id,
            'doe_id' => $doe->id,
            'recorded_by_id' => $user->id,
            'number_weaned' => 6,
            'average_weight_value' => 0.850,
        ]);
        WeightRecord::factory()->create([
            'farm_id' => $farm->id,
            'litter_id' => $litter->id,
            'rabbit_id' => null,
            'stage' => 'birth',
            'kit_count' => 8,
            'weight_value' => 0.640,
            'average_weight_value' => 0.080,
            'weight_unit' => 'kg',
        ]);
        WeightRecord::factory()->create([
            'farm_id' => $farm->id,
            'litter_id' => $litter->id,
            'rabbit_id' => null,
            'stage' => 'weaning',
            'kit_count' => 6,
            'weight_value' => 5.100,
            'average_weight_value' => 0.850,
            'weight_unit' => 'kg',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/reports/litters/performance")
            ->assertOk()
            ->assertJsonPath('data.litter_count', 1)
            ->assertJsonPath('data.born_alive', 8)
            ->assertJsonPath('data.stillborn', 2)
            ->assertJsonPath('data.mortality', 2)
            ->assertJsonPath('data.weaned', 6)
            ->assertJsonPath('data.survival_rate', 75)
            ->assertJsonPath('data.litters.0.identifier', 'LIT-PERF')
            ->assertJsonPath('data.litters.0.birth_average_weight', '0.080')
            ->assertJsonPath('data.litters.0.weaning_average_weight', '0.850');
    }

    public function test_non_member_cannot_view_litter_performance_report(): void
    {
        $farm = Farm::factory()->create();

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/farms/{$farm->id}/reports/litters/performance")
            ->assertNotFound();
    }

    public function test_member_can_export_litter_performance_report_as_csv(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        Litter::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'LIT-CSV',
            'kits_born_alive' => 5,
            'current_live_count' => 4,
        ]);

        Sanctum::actingAs($user);

        $this->get("/api/v1/farms/{$farm->id}/reports/litters/performance?format=csv")
            ->assertOk()
            ->assertHeader('Content-Type', 'text/csv; charset=utf-8')
            ->assertSee('identifier,doe_identifier,buck_identifier,kindled_on,born_alive', false)
            ->assertSee('LIT-CSV', false);
    }
}
