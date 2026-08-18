<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class LitterPerformanceReportController extends Controller
{
    public function show(Request $request, Farm $farm): JsonResponse|Response
    {
        $this->authorizeFarmAccess($request, $farm);

        $litters = $farm->litters()
            ->with(['doe', 'buck', 'weanings', 'weightRecords'])
            ->orderByDesc('kindled_on')
            ->get();

        $bornAlive = (int) $litters->sum('kits_born_alive');
        $stillborn = (int) $litters->sum('kits_stillborn');
        $currentLive = (int) $litters->sum('current_live_count');
        $weaned = (int) $litters->sum(fn ($litter) => $litter->weanings->sum('number_weaned'));
        $mortality = max(0, $bornAlive - $currentLive);

        $data = [
            'litter_count' => $litters->count(),
            'born_alive' => $bornAlive,
            'stillborn' => $stillborn,
            'mortality' => $mortality,
            'current_live' => $currentLive,
            'weaned' => $weaned,
            'survival_rate' => $bornAlive > 0 ? round(($currentLive / $bornAlive) * 100, 1) : 0.0,
            'litters' => $litters->map(fn ($litter) => $this->litterRow($litter))->values(),
        ];

        if ($request->query('format') === 'csv') {
            return $this->csv($data);
        }

        return response()->json(['data' => $data]);
    }

    private function litterRow($litter): array
    {
        $birthWeight = $litter->weightRecords->firstWhere('stage', 'birth');
        $weaningWeight = $litter->weightRecords->firstWhere('stage', 'weaning');
        $weaned = (int) $litter->weanings->sum('number_weaned');
        $mortality = max(0, $litter->kits_born_alive - $litter->current_live_count);

        return [
            'id' => $litter->id,
            'identifier' => $litter->identifier,
            'doe_identifier' => $litter->doe?->identifier,
            'buck_identifier' => $litter->buck?->identifier,
            'kindled_on' => $litter->kindled_on?->toDateString(),
            'born_alive' => $litter->kits_born_alive,
            'stillborn' => $litter->kits_stillborn,
            'mortality' => $mortality,
            'current_live' => $litter->current_live_count,
            'weaned' => $weaned,
            'survival_rate' => $litter->kits_born_alive > 0
                ? round(($litter->current_live_count / $litter->kits_born_alive) * 100, 1)
                : 0.0,
            'birth_average_weight' => $birthWeight?->average_weight_value,
            'weaning_average_weight' => $weaningWeight?->average_weight_value,
            'weight_unit' => $weaningWeight?->weight_unit ?? $birthWeight?->weight_unit ?? 'kg',
            'status' => $litter->status,
        ];
    }

    private function csv(array $data): Response
    {
        $handle = fopen('php://temp', 'r+');
        fputcsv($handle, [
            'identifier',
            'doe_identifier',
            'buck_identifier',
            'kindled_on',
            'born_alive',
            'stillborn',
            'mortality',
            'current_live',
            'weaned',
            'survival_rate',
            'birth_average_weight',
            'weaning_average_weight',
            'weight_unit',
            'status',
        ]);

        foreach ($data['litters'] as $litter) {
            fputcsv($handle, [
                $litter['identifier'],
                $litter['doe_identifier'],
                $litter['buck_identifier'],
                $litter['kindled_on'],
                $litter['born_alive'],
                $litter['stillborn'],
                $litter['mortality'],
                $litter['current_live'],
                $litter['weaned'],
                $litter['survival_rate'],
                $litter['birth_average_weight'],
                $litter['weaning_average_weight'],
                $litter['weight_unit'],
                $litter['status'],
            ]);
        }

        rewind($handle);
        $content = stream_get_contents($handle);
        fclose($handle);

        return response($content, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="litter-performance-report.csv"',
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
}
