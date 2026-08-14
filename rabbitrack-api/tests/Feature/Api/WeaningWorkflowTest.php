<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Litter;
use App\Models\Rabbit;
use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WeaningWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_record_weaning_and_complete_weaning_task(): void
    {
        [$user, $farm, $litter, $doe] = $this->litterContext();
        Task::factory()->create([
            'farm_id' => $farm->id,
            'type' => 'weaning',
            'status' => 'open',
            'related_type' => Litter::class,
            'related_id' => $litter->id,
            'rabbit_id' => $doe->id,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}/weanings", [
            'weaned_on' => '2026-09-07',
            'number_weaned' => 7,
            'average_weight_value' => 0.850,
            'weight_unit' => 'kg',
            'destination' => 'Grow-out cages',
        ])
            ->assertCreated()
            ->assertJsonPath('data.number_weaned', 7)
            ->assertJsonPath('data.litter_status', 'weaned')
            ->assertJsonPath('data.doe_status', 'available_for_breeding');

        $this->assertDatabaseHas('weanings', [
            'litter_id' => $litter->id,
            'number_weaned' => 7,
            'average_weight_value' => 0.850,
            'destination' => 'Grow-out cages',
        ]);

        $this->assertDatabaseHas('weight_records', [
            'litter_id' => $litter->id,
            'stage' => 'weaning',
            'weight_value' => 5.950,
            'kit_count' => 7,
            'average_weight_value' => 0.850,
            'method' => 'Weaning record',
        ]);

        $this->assertDatabaseHas('litters', [
            'id' => $litter->id,
            'current_live_count' => 7,
            'status' => 'weaned',
        ]);

        $this->assertDatabaseHas('tasks', [
            'related_id' => $litter->id,
            'type' => 'weaning',
            'status' => 'completed',
        ]);

        $this->assertDatabaseHas('tasks', [
            'related_id' => $litter->id,
            'type' => 'kit_identification',
            'title' => "Identify/tag kits from {$litter->identifier}",
            'status' => 'open',
        ]);

        $this->assertEquals(
            '2026-09-14',
            Task::query()
                ->where('related_id', $litter->id)
                ->where('type', 'kit_identification')
                ->firstOrFail()
                ->due_on
                ->toDateString(),
        );
    }

    public function test_non_member_cannot_record_weaning(): void
    {
        [, $farm, $litter] = $this->litterContext();
        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/v1/farms/{$farm->id}/litters/{$litter->id}/weanings", [
            'weaned_on' => '2026-09-07',
            'number_weaned' => 7,
        ])->assertNotFound();
    }

    private function litterContext(): array
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
            'sex' => 'female',
            'status' => 'nursing',
        ]);

        $litter = Litter::factory()->create([
            'farm_id' => $farm->id,
            'doe_id' => $doe->id,
            'current_live_count' => 8,
            'status' => 'nursing',
        ]);

        return [$user, $farm, $litter, $doe];
    }
}
