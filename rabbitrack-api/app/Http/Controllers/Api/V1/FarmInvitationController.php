<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Mail\FarmInvitationMail;
use App\Models\Farm;
use App\Models\FarmInvitation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class FarmInvitationController extends Controller
{
    public function resend(Request $request, Farm $farm, FarmInvitation $invitation): JsonResponse
    {
        $this->authorizeFarmOwner($request, $farm);
        $this->abortUnlessPendingFarmInvitation($farm, $invitation);

        $invitation->update(['invited_by_id' => $request->user()->id]);
        $invitation->load(['farm', 'invitedBy']);

        Mail::to($invitation->email)->send(new FarmInvitationMail($invitation));

        $farm->activityLogs()->create([
            'user_id' => $request->user()->id,
            'action' => 'team.invitation_resent',
            'description' => "Resent invitation to {$invitation->email}.",
            'metadata' => [
                'invitation_id' => $invitation->id,
                'email' => $invitation->email,
                'role' => $invitation->role,
            ],
        ]);

        return response()->json(['message' => 'Invitation resent.']);
    }

    public function destroy(Request $request, Farm $farm, FarmInvitation $invitation): JsonResponse
    {
        $this->authorizeFarmOwner($request, $farm);
        $this->abortUnlessPendingFarmInvitation($farm, $invitation);

        $invitation->update(['revoked_at' => now()]);

        $farm->activityLogs()->create([
            'user_id' => $request->user()->id,
            'action' => 'team.invitation_cancelled',
            'description' => "Cancelled invitation to {$invitation->email}.",
            'metadata' => [
                'invitation_id' => $invitation->id,
                'email' => $invitation->email,
                'role' => $invitation->role,
            ],
        ]);

        return response()->json(['message' => 'Invitation cancelled.']);
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

    private function abortUnlessPendingFarmInvitation(Farm $farm, FarmInvitation $invitation): void
    {
        if ($invitation->farm_id !== $farm->id) {
            abort(404);
        }

        if ($invitation->accepted_at !== null || $invitation->revoked_at !== null) {
            throw ValidationException::withMessages([
                'invitation' => ['This invitation is no longer pending.'],
            ]);
        }
    }
}
