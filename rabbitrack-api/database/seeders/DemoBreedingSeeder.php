<?php

namespace Database\Seeders;

use App\Models\Farm;
use App\Models\Litter;
use App\Models\Mating;
use App\Models\Rabbit;
use App\Models\Task;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class DemoBreedingSeeder extends Seeder
{
    public function run(): void
    {
        $farm = Farm::query()->where('code', 'DEMO-FARM')->firstOrFail();
        $owner = User::query()->where('email', 'owner@rabbitrack.local')->firstOrFail();
        $doe = Rabbit::query()
            ->where('farm_id', $farm->id)
            ->where('identifier', 'DOE-0047')
            ->firstOrFail();
        $buck = Rabbit::query()
            ->where('farm_id', $farm->id)
            ->where('identifier', 'BUCK-0003')
            ->firstOrFail();

        $kindledOn = Carbon::today();
        $matedAt = $kindledOn->copy()->subDays(31)->setTime(9, 30);
        $litterIdentifier = 'LIT-DEMO-'.$kindledOn->format('ymd');
        $plannedWeaningOn = $kindledOn->copy()->addDays(35)->toDateString();

        $mating = Mating::query()->updateOrCreate(
            [
                'farm_id' => $farm->id,
                'notes' => 'Demo seeded mating-to-kindling flow.',
            ],
            [
                'doe_id' => $doe->id,
                'buck_id' => $buck->id,
                'recorded_by_id' => $owner->id,
                'mated_at' => $matedAt,
                'outcome' => 'observed',
                'behavior_observed' => 'Successful fall-off observed.',
                'pregnancy_check_due_on' => $matedAt->copy()->addDays(14)->toDateString(),
                'expected_kindling_on' => $kindledOn->toDateString(),
                'nest_box_due_on' => $kindledOn->copy()->subDays(3)->toDateString(),
                'status' => 'kindled',
            ],
        );

        $litter = Litter::query()->updateOrCreate(
            [
                'farm_id' => $farm->id,
                'identifier' => $litterIdentifier,
            ],
            [
                'doe_id' => $doe->id,
                'buck_id' => $buck->id,
                'mating_id' => $mating->id,
                'kindled_on' => $kindledOn->toDateString(),
                'kits_born_alive' => 6,
                'kits_stillborn' => 1,
                'kits_weak' => 1,
                'current_live_count' => 6,
                'planned_weaning_on' => $plannedWeaningOn,
                'status' => 'nursing',
                'notes' => 'Demo kindling record created from the seeded mating.',
            ],
        );

        $farm->kindlings()->updateOrCreate(
            [
                'mating_id' => $mating->id,
                'litter_id' => $litter->id,
            ],
            [
                'doe_id' => $doe->id,
                'recorded_by_id' => $owner->id,
                'kindled_on' => $kindledOn->toDateString(),
                'kits_born_alive' => 6,
                'kits_stillborn' => 1,
                'kits_weak' => 1,
                'nest_condition' => 'Clean, warm, and well lined.',
                'doe_condition' => 'Alert and nursing normally.',
                'notes' => 'Demo kindling record created from the seeded mating.',
            ],
        );

        Task::query()
            ->where('related_type', Mating::class)
            ->where('related_id', $mating->id)
            ->whereIn('type', ['pregnancy_check', 'nest_box_preparation', 'expected_kindling'])
            ->update(['status' => 'completed']);

        $farm->tasks()->updateOrCreate(
            [
                'related_type' => Litter::class,
                'related_id' => $litter->id,
                'type' => 'weaning',
            ],
            [
                'assigned_to_id' => $owner->id,
                'title' => "Wean litter {$litter->identifier}",
                'description' => 'Record actual weaning count, weights, and destination.',
                'due_on' => $plannedWeaningOn,
                'priority' => 'normal',
                'status' => 'open',
                'rabbit_id' => $doe->id,
                'litter_id' => $litter->id,
                'metadata' => [
                    'litter_id' => $litter->id,
                    'planned_weaning_on' => $plannedWeaningOn,
                ],
            ],
        );

        $doe->update(['status' => 'nursing']);
        $buck->update(['status' => 'available_for_breeding']);
    }
}
