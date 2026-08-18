<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class PopulationReportController extends Controller
{
    public function show(Request $request, Farm $farm): JsonResponse|Response
    {
        $this->authorizeFarmAccess($request, $farm);

        $data = $this->reportData($farm);

        if ($request->query('format') === 'csv') {
            return $this->csv($farm, $data);
        }

        return response()->json(['data' => $data]);
    }

    private function reportData(Farm $farm): array
    {
        $activeRabbits = $farm->rabbits()
            ->whereNotIn('status', ['sold', 'retired', 'deceased', 'culled']);

        return [
            'total' => (clone $activeRabbits)->count(),
            'by_sex' => $this->countsBy((clone $activeRabbits), 'sex'),
            'by_status' => $this->countsBy((clone $activeRabbits), 'status'),
            'by_breed' => $this->countsBy((clone $activeRabbits), 'breed', 'Unspecified'),
            'by_location' => $farm->rabbits()
                ->leftJoin('locations', 'rabbits.current_location_id', '=', 'locations.id')
                ->where('rabbits.farm_id', $farm->id)
                ->whereNotIn('rabbits.status', ['sold', 'retired', 'deceased', 'culled'])
                ->selectRaw('COALESCE(locations.name, ?) as label, COUNT(*) as count', ['No location'])
                ->groupBy('label')
                ->orderByDesc('count')
                ->orderBy('label')
                ->get()
                ->map(fn ($row) => [
                    'label' => $row->label,
                    'count' => (int) $row->count,
                ]),
        ];
    }

    private function csv(Farm $farm, array $data): Response
    {
        return response($this->csvContent($farm, $data), 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="population-report.csv"',
        ]);
    }

    private function csvContent(Farm $farm, array $data): string
    {
        $handle = fopen('php://temp', 'r+');
        fputcsv($handle, ['farm', 'report', 'section', 'label', 'count']);
        fputcsv($handle, [$farm->name, 'Population report', 'Total', 'Active rabbits', $data['total']]);

        foreach ([
            'Sex' => $data['by_sex'],
            'Status' => $data['by_status'],
            'Breed' => $data['by_breed'],
            'Location' => $data['by_location'],
        ] as $section => $rows) {
            foreach ($rows as $row) {
                fputcsv($handle, [$farm->name, 'Population report', $section, $row['label'], $row['count']]);
            }
        }

        rewind($handle);
        $content = stream_get_contents($handle);
        fclose($handle);

        return $content;
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
}
