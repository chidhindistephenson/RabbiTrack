<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Symfony\Component\HttpFoundation\Response;

class BreedingCalendarController extends Controller
{
    public function index(Request $request, Farm $farm): JsonResponse|Response
    {
        $this->authorizeFarmAccess($request, $farm);

        $validated = $request->validate([
            'start' => ['nullable', 'date'],
            'end' => ['nullable', 'date', 'after_or_equal:start'],
        ]);

        $today = Carbon::now($farm->timezone)->startOfDay();
        $start = Carbon::parse($validated['start'] ?? $today->copy()->subDays(30)->toDateString())->startOfDay();
        $end = Carbon::parse($validated['end'] ?? $today->copy()->addDays(60)->toDateString())->endOfDay();

        $events = collect();

        $farm->matings()
            ->with(['doe', 'buck'])
            ->where(function ($query) use ($start, $end): void {
                $query
                    ->whereBetween('mated_at', [$start, $end])
                    ->orWhereBetween('pregnancy_check_due_on', [$start->toDateString(), $end->toDateString()])
                    ->orWhereBetween('nest_box_due_on', [$start->toDateString(), $end->toDateString()])
                    ->orWhereBetween('expected_kindling_on', [$start->toDateString(), $end->toDateString()]);
            })
            ->get()
            ->each(function ($mating) use ($events, $start, $end): void {
                $doe = $mating->doe?->identifier ?? 'Doe';
                $buck = $mating->buck?->identifier ?? 'Buck';

                $this->pushEvent($events, $start, $end, $mating->mated_at, [
                    'type' => 'mating',
                    'title' => "Mating: {$doe} x {$buck}",
                    'subtitle' => $mating->outcome,
                    'related_type' => 'mating',
                    'related_id' => $mating->id,
                    'rabbit_id' => $mating->doe_id,
                    'rabbit_identifier' => $doe,
                ]);

                $this->pushEvent($events, $start, $end, $mating->pregnancy_check_due_on, [
                    'type' => 'pregnancy_check',
                    'title' => "Pregnancy check: {$doe}",
                    'subtitle' => "Mated with {$buck}",
                    'related_type' => 'mating',
                    'related_id' => $mating->id,
                    'rabbit_id' => $mating->doe_id,
                    'rabbit_identifier' => $doe,
                ]);

                $this->pushEvent($events, $start, $end, $mating->nest_box_due_on, [
                    'type' => 'nest_box',
                    'title' => "Nest box: {$doe}",
                    'subtitle' => "Expected kindling {$mating->expected_kindling_on?->toDateString()}",
                    'related_type' => 'mating',
                    'related_id' => $mating->id,
                    'rabbit_id' => $mating->doe_id,
                    'rabbit_identifier' => $doe,
                ]);

                $this->pushEvent($events, $start, $end, $mating->expected_kindling_on, [
                    'type' => 'expected_kindling',
                    'title' => "Expected kindling: {$doe}",
                    'subtitle' => "Buck {$buck}",
                    'related_type' => 'mating',
                    'related_id' => $mating->id,
                    'rabbit_id' => $mating->doe_id,
                    'rabbit_identifier' => $doe,
                ]);
            });

        $farm->litters()
            ->with(['doe', 'buck'])
            ->where(function ($query) use ($start, $end): void {
                $query
                    ->whereBetween('kindled_on', [$start->toDateString(), $end->toDateString()])
                    ->orWhereBetween('planned_weaning_on', [$start->toDateString(), $end->toDateString()]);
            })
            ->get()
            ->each(function ($litter) use ($events, $start, $end): void {
                $doe = $litter->doe?->identifier ?? 'Doe';

                $this->pushEvent($events, $start, $end, $litter->kindled_on, [
                    'type' => 'kindling',
                    'title' => "Kindled: {$litter->identifier}",
                    'subtitle' => "{$litter->kits_born_alive} born alive from {$doe}",
                    'related_type' => 'litter',
                    'related_id' => $litter->id,
                    'rabbit_id' => $litter->doe_id,
                    'rabbit_identifier' => $doe,
                ]);

                $this->pushEvent($events, $start, $end, $litter->planned_weaning_on, [
                    'type' => 'weaning',
                    'title' => "Planned weaning: {$litter->identifier}",
                    'subtitle' => "{$litter->current_live_count} live kits",
                    'related_type' => 'litter',
                    'related_id' => $litter->id,
                    'rabbit_id' => $litter->doe_id,
                    'rabbit_identifier' => $doe,
                ]);
            });

        $sortedEvents = $events
            ->sortBy([['date', 'asc'], ['title', 'asc']])
            ->values()
            ->all();

        if ($request->query('format') === 'csv') {
            return $this->csvResponse($sortedEvents);
        }

        return response()->json([
            'data' => $sortedEvents,
        ]);
    }

    private function pushEvent($events, Carbon $start, Carbon $end, mixed $date, array $payload): void
    {
        if ($date === null) {
            return;
        }

        $eventDate = Carbon::parse($date)->startOfDay();

        if ($eventDate->lt($start) || $eventDate->gt($end)) {
            return;
        }

        $events->push($payload + [
            'date' => $eventDate->toDateString(),
        ]);
    }

    private function authorizeFarmAccess(Request $request, Farm $farm): void
    {
        $hasAccess = $request->user()
            ->memberships()
            ->where('farm_id', $farm->id)
            ->where('is_active', true)
            ->exists();

        abort_unless($hasAccess, 404);
    }

    private function csvResponse(array $events): Response
    {
        $handle = fopen('php://temp', 'r+');
        fputcsv($handle, [
            'date',
            'type',
            'title',
            'subtitle',
            'rabbit_identifier',
            'related_type',
            'related_id',
        ]);

        foreach ($events as $event) {
            fputcsv($handle, [
                $event['date'],
                $event['type'],
                $event['title'],
                $event['subtitle'] ?? '',
                $event['rabbit_identifier'] ?? '',
                $event['related_type'],
                $event['related_id'],
            ]);
        }

        rewind($handle);
        $csv = stream_get_contents($handle);
        fclose($handle);

        return response($csv, 200, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="breeding-calendar.csv"',
        ]);
    }
}
