<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HealthCheckTest extends TestCase
{
    use RefreshDatabase;

    public function test_health_check_reports_service_readiness(): void
    {
        User::factory()->create([
            'email' => 'owner@rabbitrack.local',
            'is_active' => true,
        ]);

        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertJsonPath('status', 'ok')
            ->assertJsonPath('app', 'RabbiTrack')
            ->assertJsonPath('checks.database', true)
            ->assertJsonPath('checks.demo_account', true);
    }

    public function test_health_check_reports_degraded_when_demo_account_is_missing(): void
    {
        $this->getJson('/api/v1/health')
            ->assertStatus(503)
            ->assertJsonPath('status', 'degraded')
            ->assertJsonPath('checks.database', true)
            ->assertJsonPath('checks.demo_account', false);
    }
}
