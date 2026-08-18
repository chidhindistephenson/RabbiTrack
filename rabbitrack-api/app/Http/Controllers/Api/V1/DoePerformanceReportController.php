<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class DoePerformanceReportController extends Controller
{
    public function show(Request $request, Farm $farm): JsonResponse|Response
    {
        $this->authorizeFarmAccess($request, $farm);
        $filters = $request->validate([
            'start' => ['nullable', 'date'],
            'end' => ['nullable', 'date', 'after_or_equal:start'],
        ]);

        $does = $farm->rabbits()
            ->where('sex', 'female')
            ->with([
                'doeMatings.pregnancyChecks',
                'littersAsDoe.weanings',
            ])
            ->orderBy('identifier')
            ->get();

        $rows = $does->map(fn ($doe) => $this->doeRow(
            $doe,
            $filters['start'] ?? null,
            $filters['end'] ?? null,
        ))->values();
        $kitsBornAlive = (int) $rows->sum('kits_born_alive');
        $kitsWeaned = (int) $rows->sum('kits_weaned');
        $kindlings = (int) $rows->sum('kindlings');

        $data = [
            'doe_count' => $rows->count(),
            'total_matings' => (int) $rows->sum('matings'),
            'confirmed_pregnancies' => (int) $rows->sum('confirmed_pregnancies'),
            'kindlings' => $kindlings,
            'completed_litters' => (int) $rows->sum('completed_litters'),
            'kits_born_alive' => $kitsBornAlive,
            'kits_weaned' => $kitsWeaned,
            'average_litter_size' => $kindlings > 0
                ? round($kitsBornAlive / $kindlings, 1)
                : 0.0,
            'survival_rate' => $kitsBornAlive > 0
                ? round(($kitsWeaned / $kitsBornAlive) * 100, 1)
                : 0.0,
            'period' => [
                'start' => $filters['start'] ?? null,
                'end' => $filters['end'] ?? null,
            ],
            'does' => $rows,
        ];

        if ($request->query('format') === 'csv') {
            return $this->csv($data);
        }

        return response()->json(['data' => $data]);
    }

    private function doeRow($doe, ?string $start, ?string $end): array
    {
        $matings = $doe->doeMatings
            ->filter(fn ($mating) => $this->dateInRange($mating->mated_at, $start, $end));
        $litters = $doe->littersAsDoe
            ->filter(fn ($litter) => $this->dateInRange($litter->kindled_on, $start, $end))
            ->sortBy('kindled_on')
            ->values();
        $kitsBornAlive = (int) $litters->sum('kits_born_alive');
        $kitsWeaned = (int) $litters->sum(fn ($litter) => $litter->weanings->sum('number_weaned'));
        $kindlings = $litters->count();
        $completedLitters = $litters
            ->filter(fn ($litter) => $litter->weanings->isNotEmpty() || in_array($litter->status, ['weaned', 'closed', 'archived'], true))
            ->count();
        $confirmedPregnancies = $matings
            ->filter(fn ($mating) => in_array($mating->status, ['pregnant', 'kindled'], true)
                || $mating->pregnancyChecks->contains('result', 'pregnant'))
            ->count();

        return [
            'id' => $doe->id,
            'identifier' => $doe->identifier,
            'name' => $doe->name,
            'breed' => $doe->breed,
            'status' => $doe->status,
            'matings' => $matings->count(),
            'confirmed_pregnancies' => $confirmedPregnancies,
            'kindlings' => $kindlings,
            'completed_litters' => $completedLitters,
            'kits_born_alive' => $kitsBornAlive,
            'kits_weaned' => $kitsWeaned,
            'average_litter_size' => $kindlings > 0
                ? round($kitsBornAlive / $kindlings, 1)
                : 0.0,
            'survival_rate' => $kitsBornAlive > 0
                ? round(($kitsWeaned / $kitsBornAlive) * 100, 1)
                : 0.0,
            'average_litter_interval_days' => $this->averageLitterIntervalDays($litters),
        ];
    }

    private function csv(array $data): Response
    {
        $handle = fopen('php://temp', 'r+');
        fputcsv($handle, [
            'identifier',
            'name',
            'breed',
            'status',
            'matings',
            'confirmed_pregnancies',
            'kindlings',
            'completed_litters',
            'kits_born_alive',
            'kits_weaned',
            'average_litter_size',
            'survival_rate',
            'average_litter_interval_days',
        ]);

        foreach ($data['does'] as $doe) {
            fputcsv($handle, [
                $doe['identifier'],
                $doe['name'],
                $doe['breed'],
                $doe['status'],
                $doe['matings'],
                $doe['confirmed_pregnancies'],
                $doe['kindlings'],
                $doe['completed_litters'],
                $doe['kits_born_alive'],
                $doe['kits_weaned'],
                $doe['average_litter_size'],
                $doe['survival_rate'],
                $doe['average_litter_interval_days'],
            ]);
        }

        rewind($handle);
        $content = stream_get_contents($handle);
        fclose($handle);

        return response($content, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="doe-performance-report.csv"',
        ]);
    }

    private function dateInRange($date, ?string $start, ?string $end): bool
    {
        if ($date === null) {
            return false;
        }

        $value = $date->toDateString();

        if ($start !== null && $value < $start) {
            return false;
        }

        if ($end !== null && $value > $end) {
            return false;
        }

        return true;
    }

    private function averageLitterIntervalDays($litters): ?float
    {
        $dates = $litters
            ->pluck('kindled_on')
            ->filter()
            ->values();

        if ($dates->count() < 2) {
            return null;
        }

        $intervals = [];

        for ($index = 1; $index < $dates->count(); $index++) {
            $intervals[] = $dates[$index - 1]->diffInDays($dates[$index]);
        }

        return round(array_sum($intervals) / count($intervals), 1);
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
}
