<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Litter;
use App\Models\Rabbit;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WeightRecordTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_record_rabbit_weight_and_update_profile_weight(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'DOE-0047',
            'weight_value' => 4.000,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/weights", [
            'rabbit_id' => $rabbit->id,
            'weighed_on' => '2026-07-30',
            'weight_value' => 4.350,
            'weight_unit' => 'kg',
            'method' => 'digital scale',
        ])
            ->assertCreated()
            ->assertJsonPath('data.rabbit_identifier', 'DOE-0047')
            ->assertJsonPath('data.weight_value', '4.350');

        $this->assertDatabaseHas('rabbits', [
            'id' => $rabbit->id,
            'weight_value' => 4.350,
            'weight_unit' => 'kg',
        ]);
    }

    public function test_member_cannot_record_litter_weight_directly(): void
    {
        [$user, $farm] = $this->memberContext();
        $litter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'identifier' => 'LIT-260803-TEST',
            'current_live_count' => 5,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/weights", [
            'litter_id' => $litter->id,
            'weighed_on' => '2026-08-10',
            'weight_value' => 2.750,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('litter_id');
    }

    public function test_direct_litter_weight_is_rejected_even_when_stage_is_sent(): void
    {
        [$user, $farm] = $this->memberContext();
        $litter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'current_live_count' => 5,
            'status' => 'nursing',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/weights", [
            'litter_id' => $litter->id,
            'stage' => 'birth',
            'weighed_on' => '2026-08-10',
            'weight_value' => 2.750,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('litter_id');
    }

    public function test_member_cannot_record_weight_for_sold_rabbit(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'sold',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/weights", [
            'rabbit_id' => $rabbit->id,
            'weighed_on' => '2026-08-05',
            'weight_value' => 4.350,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('rabbit_id');
    }

    public function test_weight_requires_exactly_one_target(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);
        $litter = Litter::factory()->create(['farm_id' => $farm->id]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/weights", [
            'weighed_on' => '2026-07-30',
            'weight_value' => 4.350,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('target');

        $this->postJson("/api/v1/farms/{$farm->id}/weights", [
            'rabbit_id' => $rabbit->id,
            'litter_id' => $litter->id,
            'weighed_on' => '2026-07-30',
            'weight_value' => 4.350,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('target');
    }

    public function test_weight_target_must_belong_to_farm(): void
    {
        [$user, $farm] = $this->memberContext();
        $otherFarm = Farm::factory()->create();
        $otherRabbit = Rabbit::factory()->create(['farm_id' => $otherFarm->id]);
        $otherLitter = Litter::factory()->create(['farm_id' => $otherFarm->id]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/weights", [
            'rabbit_id' => $otherRabbit->id,
            'weighed_on' => '2026-07-30',
            'weight_value' => 4.350,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('rabbit_id');

        $this->postJson("/api/v1/farms/{$farm->id}/weights", [
            'litter_id' => $otherLitter->id,
            'weighed_on' => '2026-07-30',
            'weight_value' => 4.350,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('litter_id');
    }

    public function test_weight_text_fields_are_normalized(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/weights", [
            'rabbit_id' => $rabbit->id,
            'weighed_on' => '2026-07-30',
            'weight_value' => 4.350,
            'weight_unit' => ' kg ',
            'method' => '  Digital scale  ',
            'notes' => '   ',
        ])
            ->assertCreated()
            ->assertJsonPath('data.weight_unit', 'kg')
            ->assertJsonPath('data.method', 'Digital scale')
            ->assertJsonPath('data.notes', null);

        $this->assertDatabaseHas('weight_records', [
            'rabbit_id' => $rabbit->id,
            'weight_unit' => 'kg',
            'method' => 'Digital scale',
            'notes' => null,
        ]);
    }

    public function test_non_member_cannot_record_weight(): void
    {
        $farm = Farm::factory()->create();
        $rabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);

        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/v1/farms/{$farm->id}/weights", [
            'rabbit_id' => $rabbit->id,
            'weighed_on' => '2026-07-30',
            'weight_value' => 4.350,
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
