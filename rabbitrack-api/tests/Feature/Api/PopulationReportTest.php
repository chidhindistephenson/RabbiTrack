<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Location;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PopulationReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_view_population_report(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create();
        $cageA = Location::factory()->create([
            'farm_id' => $farm->id,
            'name' => 'Cage A',
        ]);
        $cageB = Location::factory()->create([
            'farm_id' => $farm->id,
            'name' => 'Cage B',
        ]);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'available_for_breeding',
            'breed' => 'Rex',
            'current_location_id' => $cageA->id,
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'pregnant',
            'breed' => 'Rex',
            'current_location_id' => $cageA->id,
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'male',
            'status' => 'growing',
            'breed' => 'New Zealand White',
            'current_location_id' => $cageB->id,
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'unknown',
            'status' => 'sold',
            'breed' => 'Rex',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/reports/population")
            ->assertOk()
            ->assertJsonPath('data.total', 3)
            ->assertJsonPath('data.by_sex.0.label', 'female')
            ->assertJsonPath('data.by_sex.0.count', 2)
            ->assertJsonPath('data.by_breed.0.label', 'Rex')
            ->assertJsonPath('data.by_breed.0.count', 2)
            ->assertJsonPath('data.by_location.0.label', 'Cage A')
            ->assertJsonPath('data.by_location.0.count', 2);
    }

    public function test_non_member_cannot_view_population_report(): void
    {
        $farm = Farm::factory()->create();

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/farms/{$farm->id}/reports/population")
            ->assertNotFound();
    }

    public function test_member_can_export_population_report_as_csv(): void
    {
        $user = User::factory()->create();
        $farm = Farm::factory()->create(['name' => 'CSV Farm']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);
        Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'sex' => 'female',
            'status' => 'available_for_breeding',
            'breed' => 'Rex',
        ]);

        Sanctum::actingAs($user);

        $this->get("/api/v1/farms/{$farm->id}/reports/population?format=csv")
            ->assertOk()
            ->assertHeader('Content-Type', 'text/csv; charset=utf-8')
            ->assertSee('farm,report,section,label,count', false)
            ->assertSee('CSV Farm', false)
            ->assertSee('"Population report",Total,"Active rabbits",1', false)
            ->assertSee('Sex,female,1', false);
    }
}
