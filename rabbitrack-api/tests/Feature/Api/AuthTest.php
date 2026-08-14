<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmInvitation;
use App\Models\FarmMembership;
use App\Models\User;
use App\Services\GoogleIdTokenVerifier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_and_receive_owner_farm(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'New Owner',
            'email' => 'new-owner@rabbitrack.test',
            'password' => 'secret-password',
            'password_confirmation' => 'secret-password',
            'farm_name' => 'Green Valley Rabbitry',
            'device_name' => 'Pixel field phone',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('token_type', 'Bearer')
            ->assertJsonPath('user.email', 'new-owner@rabbitrack.test')
            ->assertJsonPath('user.farms.0.name', 'Green Valley Rabbitry')
            ->assertJsonPath('user.farms.0.role', 'owner')
            ->assertJsonPath('user.farms.0.timezone', 'Africa/Johannesburg')
            ->assertJsonPath('user.farms.0.currency', 'USD')
            ->assertJsonStructure(['token']);

        $this->assertDatabaseHas('users', [
            'email' => 'new-owner@rabbitrack.test',
        ]);

        $this->assertDatabaseHas('farms', [
            'name' => 'Green Valley Rabbitry',
        ]);
    }

    public function test_invited_user_registers_into_invited_farm_without_new_owner_farm(): void
    {
        $owner = User::factory()->create();
        $farm = Farm::factory()->create(['name' => 'Shared Rabbitry']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        FarmInvitation::query()->create([
            'farm_id' => $farm->id,
            'invited_by_id' => $owner->id,
            'email' => 'worker-signup@rabbitrack.test',
            'role' => 'worker',
        ]);

        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Worker Signup',
            'email' => 'worker-signup@rabbitrack.test',
            'password' => 'secret-password',
            'password_confirmation' => 'secret-password',
            'farm_name' => 'Should Not Be Created',
            'device_name' => 'Worker phone',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('user.email', 'worker-signup@rabbitrack.test')
            ->assertJsonPath('user.farms.0.id', $farm->id)
            ->assertJsonPath('user.farms.0.name', 'Shared Rabbitry')
            ->assertJsonPath('user.farms.0.role', 'worker');

        $workerId = User::query()->where('email', 'worker-signup@rabbitrack.test')->value('id');

        $this->assertDatabaseHas('farm_memberships', [
            'farm_id' => $farm->id,
            'user_id' => $workerId,
            'role' => 'worker',
            'is_active' => true,
        ]);
        $this->assertDatabaseHas('farm_invitations', [
            'farm_id' => $farm->id,
            'email' => 'worker-signup@rabbitrack.test',
        ]);
        $this->assertDatabaseMissing('farms', [
            'name' => 'Should Not Be Created',
        ]);
    }

    public function test_user_can_login_with_email_and_receive_farms(): void
    {
        $user = User::factory()->create([
            'email' => 'manager@rabbitrack.test',
            'password' => 'secret-password',
        ]);

        $farm = Farm::factory()->create([
            'name' => 'North House Rabbitry',
            'currency' => 'USD',
            'timezone' => 'Africa/Harare',
        ]);

        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'login' => 'manager@rabbitrack.test',
            'password' => 'secret-password',
            'device_name' => 'Pixel field phone',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('token_type', 'Bearer')
            ->assertJsonPath('user.email', 'manager@rabbitrack.test')
            ->assertJsonPath('user.farms.0.id', $farm->id)
            ->assertJsonPath('user.farms.0.role', 'manager')
            ->assertJsonPath('user.farms.0.timezone', 'Africa/Harare')
            ->assertJsonPath('user.farms.0.currency', 'USD')
            ->assertJsonStructure(['token']);
    }

    public function test_user_can_sign_in_with_google_and_receive_starter_farm(): void
    {
        $this->mock(GoogleIdTokenVerifier::class, function ($mock): void {
            $mock->shouldReceive('verify')
                ->once()
                ->with('valid-google-token')
                ->andReturn([
                    'sub' => 'google-user-123',
                    'email' => 'google-owner@rabbitrack.test',
                    'name' => 'Google Owner',
                ]);
        });

        $response = $this->postJson('/api/v1/auth/google', [
            'id_token' => 'valid-google-token',
            'device_name' => 'Pixel field phone',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('token_type', 'Bearer')
            ->assertJsonPath('user.email', 'google-owner@rabbitrack.test')
            ->assertJsonPath('user.farms.0.role', 'owner')
            ->assertJsonPath('user.farms.0.currency', 'USD')
            ->assertJsonStructure(['token']);

        $this->assertDatabaseHas('users', [
            'email' => 'google-owner@rabbitrack.test',
            'google_id' => 'google-user-123',
        ]);
    }

    public function test_google_sign_in_accepts_pending_farm_invitation(): void
    {
        $owner = User::factory()->create();
        $farm = Farm::factory()->create(['name' => 'Invited Google Farm']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        FarmInvitation::query()->create([
            'farm_id' => $farm->id,
            'invited_by_id' => $owner->id,
            'email' => 'google-worker@rabbitrack.test',
            'role' => 'worker',
        ]);

        $this->mock(GoogleIdTokenVerifier::class, function ($mock): void {
            $mock->shouldReceive('verify')
                ->once()
                ->with('invited-google-token')
                ->andReturn([
                    'sub' => 'google-worker-456',
                    'email' => 'google-worker@rabbitrack.test',
                    'name' => 'Google Worker',
                ]);
        });

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'invited-google-token',
        ])
            ->assertOk()
            ->assertJsonPath('user.farms.0.id', $farm->id)
            ->assertJsonPath('user.farms.0.role', 'worker');

        $workerId = User::query()->where('email', 'google-worker@rabbitrack.test')->value('id');

        $this->assertDatabaseHas('farm_memberships', [
            'farm_id' => $farm->id,
            'user_id' => $workerId,
            'role' => 'worker',
            'is_active' => true,
        ]);
        $this->assertDatabaseHas('farm_invitations', [
            'farm_id' => $farm->id,
            'email' => 'google-worker@rabbitrack.test',
        ]);
        $this->assertDatabaseMissing('farms', [
            'name' => "Google Worker's Rabbitry",
        ]);
    }

    public function test_inactive_user_cannot_sign_in_with_google(): void
    {
        User::factory()->create([
            'email' => 'inactive-google@rabbitrack.test',
            'is_active' => false,
        ]);

        $this->mock(GoogleIdTokenVerifier::class, function ($mock): void {
            $mock->shouldReceive('verify')
                ->once()
                ->with('inactive-google-token')
                ->andReturn([
                    'sub' => 'inactive-google-789',
                    'email' => 'inactive-google@rabbitrack.test',
                    'name' => 'Inactive Google',
                ]);
        });

        $this->postJson('/api/v1/auth/google', [
            'id_token' => 'inactive-google-token',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('id_token');
    }

    public function test_existing_user_accepts_pending_invitation_on_login(): void
    {
        $user = User::factory()->create([
            'email' => 'invited-existing@rabbitrack.test',
            'password' => 'secret-password',
        ]);
        $owner = User::factory()->create();
        $farm = Farm::factory()->create(['name' => 'Existing Invite Farm']);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        FarmInvitation::query()->create([
            'farm_id' => $farm->id,
            'invited_by_id' => $owner->id,
            'email' => 'invited-existing@rabbitrack.test',
            'role' => 'manager',
        ]);

        $this->postJson('/api/v1/auth/login', [
            'login' => 'invited-existing@rabbitrack.test',
            'password' => 'secret-password',
        ])
            ->assertOk()
            ->assertJsonPath('user.farms.0.id', $farm->id)
            ->assertJsonPath('user.farms.0.role', 'manager');

        $this->assertDatabaseHas('farm_memberships', [
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'manager',
            'is_active' => true,
        ]);
    }

    public function test_user_can_logout_and_invalidate_token(): void
    {
        $user = User::factory()->create([
            'email' => 'owner@rabbitrack.test',
            'password' => 'secret-password',
        ]);

        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $user->id,
            'role' => 'owner',
        ]);

        $login = $this->postJson('/api/v1/auth/login', [
            'login' => 'owner@rabbitrack.test',
            'password' => 'secret-password',
        ]);
        $token = $login->json('token');

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/v1/auth/logout')
            ->assertOk()
            ->assertJsonPath('message', 'Signed out.');

        $this->assertSame(0, PersonalAccessToken::query()->where('tokenable_id', $user->id)->count());
    }

    public function test_inactive_user_cannot_login(): void
    {
        User::factory()->create([
            'email' => 'inactive@rabbitrack.test',
            'password' => 'secret-password',
            'is_active' => false,
        ]);

        $this->postJson('/api/v1/auth/login', [
            'login' => 'inactive@rabbitrack.test',
            'password' => 'secret-password',
        ])->assertUnprocessable();
    }

    public function test_user_can_request_password_reset_code(): void
    {
        Mail::fake();
        User::factory()->create(['email' => 'reset@rabbitrack.test']);

        $this->postJson('/api/v1/auth/password/forgot', [
            'email' => 'reset@rabbitrack.test',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'If that email exists, a reset code has been sent.');

        $this->assertDatabaseHas('password_reset_tokens', [
            'email' => 'reset@rabbitrack.test',
        ]);

    }

    public function test_password_reset_request_is_generic_for_unknown_email(): void
    {
        Mail::fake();

        $this->postJson('/api/v1/auth/password/forgot', [
            'email' => 'missing@rabbitrack.test',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'If that email exists, a reset code has been sent.');

        $this->assertDatabaseCount('password_reset_tokens', 0);
        Mail::assertNothingSent();
    }

    public function test_user_can_reset_password_with_code(): void
    {
        $user = User::factory()->create([
            'email' => 'reset-success@rabbitrack.test',
            'password' => 'old-password',
        ]);
        $user->createToken('test-device');

        DB::table('password_reset_tokens')->insert([
            'email' => 'reset-success@rabbitrack.test',
            'token' => bcrypt('123456'),
            'created_at' => now(),
        ]);

        $this->postJson('/api/v1/auth/password/reset', [
            'email' => 'reset-success@rabbitrack.test',
            'code' => '123456',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'Password reset successfully.');

        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'reset-success@rabbitrack.test',
        ]);
        $this->assertSame(0, PersonalAccessToken::query()->where('tokenable_id', $user->id)->count());

        $this->postJson('/api/v1/auth/login', [
            'login' => 'reset-success@rabbitrack.test',
            'password' => 'new-password',
        ])->assertOk();
    }

    public function test_password_reset_rejects_invalid_code(): void
    {
        User::factory()->create(['email' => 'reset-fail@rabbitrack.test']);

        DB::table('password_reset_tokens')->insert([
            'email' => 'reset-fail@rabbitrack.test',
            'token' => bcrypt('123456'),
            'created_at' => now(),
        ]);

        $this->postJson('/api/v1/auth/password/reset', [
            'email' => 'reset-fail@rabbitrack.test',
            'code' => '654321',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('code');
    }
}
