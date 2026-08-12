<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Farm;
use App\Models\FarmInvitation;
use App\Models\FarmMembership;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::min(8)],
            'farm_name' => ['nullable', 'string', 'max:120'],
            'device_name' => ['nullable', 'string', 'max:120'],
        ]);

        $user = User::query()->create([
            'name' => $validated['name'],
            'email' => str($validated['email'])->lower()->toString(),
            'password' => $validated['password'],
            'is_active' => true,
        ]);

        $acceptedInvitations = $this->acceptPendingInvitations($user);

        if ($acceptedInvitations === 0) {
            $farm = Farm::query()->create([
                'name' => $validated['farm_name'] ?? "{$validated['name']}'s Rabbitry",
                'code' => $this->uniqueFarmCode($validated['name']),
                'timezone' => 'Africa/Johannesburg',
                'currency' => 'USD',
                'settings' => [
                    'gestation_days' => 31,
                    'pregnancy_check_start_days' => 10,
                    'pregnancy_check_end_days' => 14,
                    'nest_box_lead_days' => 3,
                    'weaning_days' => 35,
                ],
            ]);

            FarmMembership::query()->create([
                'farm_id' => $farm->id,
                'user_id' => $user->id,
                'role' => 'owner',
                'is_active' => true,
                'joined_at' => now(),
            ]);
        }

        $token = $user->createToken($validated['device_name'] ?? 'android-device')->plainTextToken;

        return response()->json([
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => $this->userPayload($user),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'login' => ['required', 'string'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:120'],
        ]);

        $login = $validated['login'];

        $user = User::query()
            ->where('email', $login)
            ->orWhere('username', $login)
            ->orWhere('phone', $login)
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'login' => ['The provided credentials are incorrect.'],
            ]);
        }

        if (! $user->is_active) {
            throw ValidationException::withMessages([
                'login' => ['This account is not active.'],
            ]);
        }

        $this->acceptPendingInvitations($user);

        $token = $user->createToken($validated['device_name'] ?? 'android-device')->plainTextToken;

        return response()->json([
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => $this->userPayload($user),
        ]);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $user = User::query()->where('email', $validated['email'])->first();

        if ($user) {
            $code = (string) random_int(100000, 999999);

            DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $validated['email']],
                [
                    'token' => Hash::make($code),
                    'created_at' => now(),
                ]
            );

            Mail::raw(
                "Your RabbiTrack password reset code is {$code}. It expires in 30 minutes.",
                fn ($message) => $message
                    ->to($validated['email'])
                    ->subject('RabbiTrack password reset code')
            );
        }

        return response()->json([
            'message' => 'If that email exists, a reset code has been sent.',
        ]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'digits:6'],
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);

        $record = DB::table('password_reset_tokens')
            ->where('email', $validated['email'])
            ->first();

        if (
            ! $record ||
            now()->diffInMinutes($record->created_at) > 30 ||
            ! Hash::check($validated['code'], $record->token)
        ) {
            throw ValidationException::withMessages([
                'code' => ['The reset code is invalid or expired.'],
            ]);
        }

        $user = User::query()->where('email', $validated['email'])->first();
        if (! $user) {
            throw ValidationException::withMessages([
                'email' => ['The selected email is invalid.'],
            ]);
        }

        $user->update(['password' => $validated['password']]);
        $user->tokens()->delete();

        DB::table('password_reset_tokens')->where('email', $validated['email'])->delete();

        return response()->json([
            'message' => 'Password reset successfully.',
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'user' => $this->userPayload($request->user()),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'Signed out.',
        ]);
    }

    private function userPayload(User $user): array
    {
        $user->load('memberships.farm');

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'username' => $user->username,
            'phone' => $user->phone,
            'farms' => $user->memberships
                ->where('is_active', true)
                ->map(fn ($membership) => [
                    'id' => $membership->farm->id,
                    'name' => $membership->farm->name,
                    'code' => $membership->farm->code,
                    'role' => $membership->role,
                    'timezone' => $membership->farm->timezone,
                    'currency' => $membership->farm->currency,
                ])
                ->values(),
        ];
    }

    private function acceptPendingInvitations(User $user): int
    {
        $accepted = 0;
        $email = str($user->email)->lower()->toString();

        FarmInvitation::query()
            ->where('email', $email)
            ->whereNull('accepted_at')
            ->whereNull('revoked_at')
            ->get()
            ->each(function (FarmInvitation $invitation) use ($user, &$accepted): void {
                $membership = FarmMembership::query()->firstOrNew([
                    'farm_id' => $invitation->farm_id,
                    'user_id' => $user->id,
                ]);

                $membership->fill([
                    'role' => $invitation->role,
                    'is_active' => true,
                    'joined_at' => $membership->joined_at ?? now(),
                ])->save();

                $invitation->update(['accepted_at' => now()]);
                $accepted++;
            });

        return $accepted;
    }

    private function uniqueFarmCode(string $seed): string
    {
        $prefix = Str::of($seed)
            ->upper()
            ->replaceMatches('/[^A-Z0-9]+/', '-')
            ->trim('-')
            ->substr(0, 12);

        $prefix = $prefix->isEmpty() ? 'FARM' : $prefix->toString();

        do {
            $code = "{$prefix}-".Str::upper(Str::random(4));
        } while (Farm::query()->where('code', $code)->exists());

        return $code;
    }
}
