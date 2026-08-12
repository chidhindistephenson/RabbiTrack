<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Throwable;

class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        $checks = [
            'database' => $this->databaseIsReady(),
            'redis' => $this->redisIsReady(),
            'demo_account' => $this->demoAccountIsReady(),
        ];

        $isReady = ! in_array(false, $checks, true);

        return response()->json([
            'status' => $isReady ? 'ok' : 'degraded',
            'app' => 'RabbiTrack',
            'checks' => $checks,
        ], $isReady ? 200 : 503);
    }

    private function databaseIsReady(): bool
    {
        try {
            DB::select('select 1');

            return true;
        } catch (Throwable) {
            return false;
        }
    }

    private function redisIsReady(): bool
    {
        $host = (string) config('database.redis.default.host', '127.0.0.1');
        $port = (int) config('database.redis.default.port', 6379);

        try {
            $connection = @fsockopen($host, $port, $errorCode, $errorMessage, 1);
            if (! $connection) {
                return false;
            }

            fclose($connection);
            return true;
        } catch (Throwable) {
            return false;
        }
    }

    private function demoAccountIsReady(): bool
    {
        try {
            return User::query()
                ->where('email', 'owner@rabbitrack.local')
                ->where('is_active', true)
                ->exists();
        } catch (Throwable) {
            return false;
        }
    }
}
