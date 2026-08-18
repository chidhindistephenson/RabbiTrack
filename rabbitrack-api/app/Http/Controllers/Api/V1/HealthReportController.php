<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Symfony\Component\HttpFoundation\Response;

class HealthReportController extends Controller
{
    public function show(Request $request, Farm $farm): JsonResponse|Response
    {
        $this->authorizeFarmAccess($request, $farm);

        $today = Carbon::now($farm->timezone)->toDateString();

        $activeEvents = $farm->healthEvents()
            ->whereIn('status', ['open', 'monitoring']);

        $activeTreatments = $farm->treatments()
            ->where('status', 'active');

        $payload = [
            'data' => [
                'active_health_events' => (clone $activeEvents)->count(),
                'active_treatments' => (clone $activeTreatments)->count(),
                'withdrawal_restrictions' => $farm->treatments()
                    ->whereNotNull('withdrawal_ends_on')
                    ->whereDate('withdrawal_ends_on', '>=', $today)
                    ->count(),
                'mortality_count' => $farm->rabbits()
                    ->whereIn('status', ['deceased', 'culled'])
                    ->count(),
                'events_by_severity' => $this->countsBy((clone $activeEvents), 'severity'),
                'events_by_body_system' => $this->countsBy((clone $activeEvents), 'body_system', 'Unspecified'),
                'events_by_diagnosis' => $this->countsBy((clone $activeEvents), 'diagnosis', 'Undiagnosed'),
                'medicine_use' => $this->countsBy((clone $activeTreatments), 'medication'),
                'withdrawals' => $farm->treatments()
                    ->with('rabbit')
                    ->whereNotNull('withdrawal_ends_on')
                    ->whereDate('withdrawal_ends_on', '>=', $today)
                    ->orderBy('withdrawal_ends_on')
                    ->limit(25)
                    ->get()
                    ->map(fn ($treatment) => [
                        'id' => $treatment->id,
                        'rabbit_id' => $treatment->rabbit_id,
                        'rabbit_identifier' => $treatment->rabbit?->identifier,
                        'medication' => $treatment->medication,
                        'withdrawal_ends_on' => $treatment->withdrawal_ends_on?->toDateString(),
                    ]),
            ],
        ];

        if ($request->query('format') === 'csv') {
            return $this->csvResponse($payload['data']);
        }

        return response()->json($payload);
    }

    private function countsBy($query, string $column, string $fallback = 'Unknown')
    {
        return $query
            ->selectRaw("COALESCE(NULLIF({$column}, ''), ?) as label, COUNT(*) as count", [$fallback])
            ->groupBy('label')
            ->orderByDesc('count')
            ->orderBy('label')
            ->get()
            ->map(fn ($row) => [
                'label' => $row->label,
                'count' => (int) $row->count,
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

    private function csvResponse(array $data): Response
    {
        $rows = [
            ['section', 'label', 'count', 'rabbit_identifier', 'medication', 'withdrawal_ends_on'],
            ['summary', 'active_health_events', $data['active_health_events'], '', '', ''],
            ['summary', 'active_treatments', $data['active_treatments'], '', '', ''],
            ['summary', 'withdrawal_restrictions', $data['withdrawal_restrictions'], '', '', ''],
            ['summary', 'mortality_count', $data['mortality_count'], '', '', ''],
        ];

        foreach ([
            'events_by_severity',
            'events_by_body_system',
            'events_by_diagnosis',
            'medicine_use',
        ] as $section) {
            foreach ($data[$section] as $row) {
                $rows[] = [$section, $row['label'], $row['count'], '', '', ''];
            }
        }

        foreach ($data['withdrawals'] as $withdrawal) {
            $rows[] = [
                'withdrawals',
                '',
                '',
                $withdrawal['rabbit_identifier'],
                $withdrawal['medication'],
                $withdrawal['withdrawal_ends_on'],
            ];
        }

        $handle = fopen('php://temp', 'r+');
        foreach ($rows as $row) {
            fputcsv($handle, $row);
        }

        rewind($handle);
        $csv = stream_get_contents($handle);
        fclose($handle);

        return response($csv, 200, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="health-report.csv"',
        ]);
    }
}
