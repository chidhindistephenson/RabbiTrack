<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmMembership;
use App\Models\Rabbit;
use App\Models\Task;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TaskWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_list_and_summarize_tasks(): void
    {
        [$user, $farm] = $this->memberContext();
        Task::factory()->create([
            'farm_id' => $farm->id,
            'title' => 'Pregnancy check',
            'due_on' => now()->toDateString(),
            'status' => 'open',
        ]);
        Task::factory()->create([
            'farm_id' => $farm->id,
            'title' => 'Overdue task',
            'due_on' => now()->subDay()->toDateString(),
            'status' => 'open',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/farms/{$farm->id}/tasks?status=open")
            ->assertOk()
            ->assertJsonCount(2, 'data');

        $this->getJson("/api/v1/farms/{$farm->id}/tasks/summary")
            ->assertOk()
            ->assertJsonPath('data.today', 1)
            ->assertJsonPath('data.overdue', 1)
            ->assertJsonPath('data.open', 2);
    }

    public function test_member_can_create_and_complete_manual_task(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create(['farm_id' => $farm->id]);

        Sanctum::actingAs($user);

        $taskId = $this->postJson("/api/v1/farms/{$farm->id}/tasks", [
            'title' => 'Check water bottle',
            'due_on' => now()->toDateString(),
            'priority' => 'high',
            'rabbit_id' => $rabbit->id,
        ])
            ->assertCreated()
            ->assertJsonPath('data.title', 'Check water bottle')
            ->json('data.id');

        $this->patchJson("/api/v1/farms/{$farm->id}/tasks/{$taskId}", [
            'action' => 'complete',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'completed');
    }

    public function test_member_can_reschedule_task(): void
    {
        [$user, $farm] = $this->memberContext();
        $task = Task::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'open',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson("/api/v1/farms/{$farm->id}/tasks/{$task->id}", [
            'action' => 'reschedule',
            'due_on' => '2026-08-10',
        ])
            ->assertOk()
            ->assertJsonPath('data.due_on', '2026-08-10')
            ->assertJsonPath('data.status', 'open');
    }

    public function test_member_cannot_create_task_for_sold_rabbit(): void
    {
        [$user, $farm] = $this->memberContext();
        $rabbit = Rabbit::factory()->create([
            'farm_id' => $farm->id,
            'status' => 'sold',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/farms/{$farm->id}/tasks", [
            'title' => 'Check water bottle',
            'due_on' => now()->toDateString(),
            'rabbit_id' => $rabbit->id,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('rabbit_id');
    }

    public function test_non_member_cannot_access_tasks(): void
    {
        $farm = Farm::factory()->create();
        Task::factory()->create(['farm_id' => $farm->id]);

        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/v1/farms/{$farm->id}/tasks")
            ->assertNotFound();
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
