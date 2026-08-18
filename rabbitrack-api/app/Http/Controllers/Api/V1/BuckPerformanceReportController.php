<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class BuckPerformanceReportController extends Controller
{
    public function show(Request $request, Farm $farm): JsonResponse|Response
    {
        $this->authorizeFarmAccess($request, $farm);
        $filters = $request->validate([
            'start' => ['nullable', 'date'],
            'end' => ['nullable', 'date', 'after_or_equal:start'],
        ]);

        $bucks = $farm->rabbits()
            ->where('sex', 'male')
            ->with([
                'buckMatings.pregnancyChecks',
                'littersAsBuck.weanings',
            ])
            ->orderBy('identifier')
            ->get();

        $rows = $bucks->map(fn ($buck) => $this->buckRow(
            $buck,
            $filters['start'] ?? null,
            $filters['end'] ?? null,
        ))->values();
        $matings = (int) $rows->sum('matings');
        $confirmedPregnancies = (int) $rows->sum('confirmed_pregnancies');
        $kitsBornAlive = (int) $rows->sum('kits_born_alive');
        $kitsWeaned = (int) $rows->sum('kits_weaned');
        $litters = (int) $rows->sum('litters');

        $data = [
            'buck_count' => $rows->count(),
            'total_matings' => $matings,
            'confirmed_pregnancies' => $confirmedPregnancies,
            'conception_rate' => $matings > 0
                ? round(($confirmedPregnancies / $matings) * 100, 1)
                : 0.0,
            'litters' => $litters,
            'kits_born_alive' => $kitsBornAlive,
            'kits_weaned' => $kitsWeaned,
            'average_litter_size' => $litters > 0
                ? round($kitsBornAlive / $litters, 1)
                : 0.0,
            'weaning_rate' => $kitsBornAlive > 0
                ? round(($kitsWeaned / $kitsBornAlive) * 100, 1)
                : 0.0,
            'period' => [
                'start' => $filters['start'] ?? null,
                'end' => $filters['end'] ?? null,
            ],
            'bucks' => $rows,
        ];

        if ($request->query('format') === 'csv') {
            return $this->csv($data);
        }

        return response()->json(['data' => $data]);
    }

    private function buckRow($buck, ?string $start, ?string $end): array
    {
        $litters = $buck->littersAsBuck
            ->filter(fn ($litter) => $this->dateInRange($litter->kindled_on, $start, $end));
        $matings = $buck->buckMatings
            ->filter(fn ($mating) => $this->dateInRange($mating->mated_at, $start, $end));
        $matingCount = $matings->count();
        $confirmedPregnancies = $matings
            ->filter(fn ($mating) => in_array($mating->status, ['pregnant', 'kindled'], true)
                || $mating->pregnancyChecks->contains('result', 'pregnant'))
            ->count();
        $kitsBornAlive = (int) $litters->sum('kits_born_alive');
        $kitsWeaned = (int) $litters->sum(fn ($litter) => $litter->weanings->sum('number_weaned'));
        $litterCount = $litters->count();

        return [
            'id' => $buck->id,
            'identifier' => $buck->identifier,
            'name' => $buck->name,
            'breed' => $buck->breed,
            'status' => $buck->status,
            'matings' => $matingCount,
            'confirmed_pregnancies' => $confirmedPregnancies,
            'conception_rate' => $matingCount > 0
                ? round(($confirmedPregnancies / $matingCount) * 100, 1)
                : 0.0,
            'litters' => $litterCount,
            'kits_born_alive' => $kitsBornAlive,
            'kits_weaned' => $kitsWeaned,
            'average_litter_size' => $litterCount > 0
                ? round($kitsBornAlive / $litterCount, 1)
                : 0.0,
            'weaning_rate' => $kitsBornAlive > 0
                ? round(($kitsWeaned / $kitsBornAlive) * 100, 1)
                : 0.0,
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
            'conception_rate',
            'litters',
            'kits_born_alive',
            'kits_weaned',
            'average_litter_size',
            'weaning_rate',
        ]);

        foreach ($data['bucks'] as $buck) {
            fputcsv($handle, [
                $buck['identifier'],
                $buck['name'],
                $buck['breed'],
                $buck['status'],
                $buck['matings'],
                $buck['confirmed_pregnancies'],
                $buck['conception_rate'],
                $buck['litters'],
                $buck['kits_born_alive'],
                $buck['kits_weaned'],
                $buck['average_litter_size'],
                $buck['weaning_rate'],
            ]);
        }

        rewind($handle);
        $content = stream_get_contents($handle);
        fclose($handle);

        return response($content, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="buck-performance-report.csv"',
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
