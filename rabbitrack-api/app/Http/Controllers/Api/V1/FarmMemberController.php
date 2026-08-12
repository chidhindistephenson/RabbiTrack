<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Mail\FarmInvitationMail;
use App\Models\Farm;
use App\Models\FarmInvitation;
use App\Models\FarmMembership;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class FarmMemberController extends Controller
{
    private const ASSIGNABLE_ROLES = [
        'administrator',
        'manager',
        'worker',
        'veterinarian',
        'viewer',
    ];

    public function index(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmAccess($request, $farm);

        $members = $farm->memberships()
            ->with('user')
            ->where('is_active', true)
            ->orderBy('role')
            ->orderBy('created_at')
            ->get()
            ->map(fn (FarmMembership $membership) => $this->memberPayload($membership));

        $invitations = $farm->invitations()
            ->whereNull('accepted_at')
            ->whereNull('revoked_at')
            ->orderBy('created_at')
            ->get()
            ->map(fn (FarmInvitation $invitation) => $this->invitationPayload($invitation));

        return response()->json(['data' => $members->concat($invitations)->values()]);
    }

    public function store(Request $request, Farm $farm): JsonResponse
    {
        $this->authorizeFarmOwner($request, $farm);

        $validated = $request->validate([
            'email' => ['required', 'email', 'max:255'],
            'role' => ['required', 'string', Rule::in(self::ASSIGNABLE_ROLES)],
        ]);

        $email = str($validated['email'])->lower()->toString();
        $user = User::query()->where('email', $email)->first();

        if (! $user) {
            $invitation = $farm->invitations()->updateOrCreate(
                ['email' => $email],
                [
                    'invited_by_id' => $request->user()->id,
                    'role' => $validated['role'],
                    'accepted_at' => null,
                    'revoked_at' => null,
                ]
            );

            $farm->activityLogs()->create([
                'user_id' => $request->user()->id,
                'action' => 'team.invitation_created',
                'description' => "Invited {$email} as {$validated['role']}.",
                'metadata' => [
                    'invitation_id' => $invitation->id,
                    'email' => $email,
                    'role' => $validated['role'],
                ],
            ]);

            Mail::to($email)->send(new FarmInvitationMail($invitation->fresh(['farm', 'invitedBy'])));

            return response()->json([
                'data' => $this->invitationPayload($invitation),
            ], 201);
        }

        $membership = $farm->memberships()->where('user_id', $user->id)->first();

        if ($membership?->is_active) {
            throw ValidationException::withMessages([
                'email' => ['This user is already an active member of the farm.'],
            ]);
        }

        if ($membership) {
            $membership->update([
                'role' => $validated['role'],
                'is_active' => true,
                'joined_at' => now(),
            ]);
        } else {
            $membership = $farm->memberships()->create([
                'user_id' => $user->id,
                'role' => $validated['role'],
                'is_active' => true,
                'joined_at' => now(),
            ]);
        }

        $farm->activityLogs()->create([
            'user_id' => $request->user()->id,
            'action' => 'team.member_added',
            'description' => "Added {$user->email} as {$validated['role']}.",
            'metadata' => [
                'membership_id' => $membership->id,
                'member_user_id' => $user->id,
                'role' => $validated['role'],
            ],
        ]);

        return response()->json([
            'data' => $this->memberPayload($membership->load('user')),
        ], 201);
    }

    public function update(Request $request, Farm $farm, FarmMembership $member): JsonResponse
    {
        $this->authorizeFarmOwner($request, $farm);
        $this->abortUnlessFarmMember($farm, $member);

        $validated = $request->validate([
            'role' => ['required', 'string', Rule::in(self::ASSIGNABLE_ROLES)],
        ]);

        if ($member->role === 'owner' && $validated['role'] !== 'owner') {
            $this->ensureAnotherOwnerExists($farm, $member);
        }

        $member->update(['role' => $validated['role']]);

        $member->load('user');

        $farm->activityLogs()->create([
            'user_id' => $request->user()->id,
            'action' => 'team.role_updated',
            'description' => "Changed {$member->user?->email} role to {$validated['role']}.",
            'metadata' => [
                'membership_id' => $member->id,
                'member_user_id' => $member->user_id,
                'role' => $validated['role'],
            ],
        ]);

        return response()->json([
            'data' => $this->memberPayload($member->fresh('user')),
        ]);
    }

    public function destroy(Request $request, Farm $farm, FarmMembership $member): JsonResponse
    {
        $this->authorizeFarmOwner($request, $farm);
        $this->abortUnlessFarmMember($farm, $member);

        if ($member->role === 'owner') {
            $this->ensureAnotherOwnerExists($farm, $member);
        }

        $member->update(['is_active' => false]);

        $member->load('user');

        $farm->activityLogs()->create([
            'user_id' => $request->user()->id,
            'action' => 'team.member_removed',
            'description' => "Removed {$member->user?->email} from the farm.",
            'metadata' => [
                'membership_id' => $member->id,
                'member_user_id' => $member->user_id,
            ],
        ]);

        return response()->json(['message' => 'Member removed.']);
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

    private function authorizeFarmOwner(Request $request, Farm $farm): void
    {
        $hasAccess = $request->user()
            ->memberships()
            ->where('farm_id', $farm->id)
            ->where('is_active', true)
            ->where('role', 'owner')
            ->exists();

        abort_unless($hasAccess, 404);
    }

    private function abortUnlessFarmMember(Farm $farm, FarmMembership $member): void
    {
        abort_unless($member->farm_id === $farm->id && $member->is_active, 404);
    }

    private function ensureAnotherOwnerExists(Farm $farm, FarmMembership $member): void
    {
        $hasAnotherOwner = $farm->memberships()
            ->whereKeyNot($member->id)
            ->where('role', 'owner')
            ->where('is_active', true)
            ->exists();

        if (! $hasAnotherOwner) {
            throw ValidationException::withMessages([
                'role' => ['The farm must keep at least one active owner.'],
            ]);
        }
    }

    private function memberPayload(FarmMembership $membership): array
    {
        return [
            'id' => $membership->id,
            'user_id' => $membership->user_id,
            'name' => $membership->user?->name,
            'email' => $membership->user?->email,
            'role' => $membership->role,
            'joined_at' => $membership->joined_at?->toDateTimeString(),
            'status' => 'active',
        ];
    }

    private function invitationPayload(FarmInvitation $invitation): array
    {
        return [
            'id' => $invitation->id,
            'user_id' => null,
            'name' => 'Pending invite',
            'email' => $invitation->email,
            'role' => $invitation->role,
            'joined_at' => null,
            'status' => 'pending',
        ];
    }
}
