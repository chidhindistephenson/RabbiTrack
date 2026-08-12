<?php

namespace Tests\Feature\Api;

use App\Models\Farm;
use App\Models\FarmInvitation;
use App\Models\FarmMembership;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use App\Mail\FarmInvitationMail;

class FarmMemberTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_list_active_farm_members(): void
    {
        $owner = User::factory()->create(['name' => 'Owner One']);
        $worker = User::factory()->create(['name' => 'Worker One']);
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $worker->id,
            'role' => 'worker',
        ]);

        Sanctum::actingAs($worker);

        $this->getJson("/api/v1/farms/{$farm->id}/members")
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.role', 'owner')
            ->assertJsonPath('data.1.role', 'worker');
    }

    public function test_owner_can_add_existing_user_to_farm(): void
    {
        Mail::fake();
        $owner = User::factory()->create();
        $newMember = User::factory()->create(['email' => 'worker@rabbitrack.test']);
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);

        Sanctum::actingAs($owner);

        $this->postJson("/api/v1/farms/{$farm->id}/members", [
            'email' => 'worker@rabbitrack.test',
            'role' => 'worker',
        ])
            ->assertCreated()
            ->assertJsonPath('data.email', 'worker@rabbitrack.test')
            ->assertJsonPath('data.role', 'worker');

        $this->assertDatabaseHas('farm_memberships', [
            'farm_id' => $farm->id,
            'user_id' => $newMember->id,
            'role' => 'worker',
            'is_active' => true,
        ]);
        Mail::assertNothingSent();
    }

    public function test_owner_can_invite_email_without_existing_account(): void
    {
        Mail::fake();
        $owner = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);

        Sanctum::actingAs($owner);

        $this->postJson("/api/v1/farms/{$farm->id}/members", [
            'email' => 'new-worker@rabbitrack.test',
            'role' => 'worker',
        ])
            ->assertCreated()
            ->assertJsonPath('data.email', 'new-worker@rabbitrack.test')
            ->assertJsonPath('data.role', 'worker')
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.user_id', null);

        $this->assertDatabaseHas('farm_invitations', [
            'farm_id' => $farm->id,
            'email' => 'new-worker@rabbitrack.test',
            'role' => 'worker',
            'accepted_at' => null,
            'revoked_at' => null,
        ]);
        Mail::assertSent(
            FarmInvitationMail::class,
            fn (FarmInvitationMail $mail) => $mail->hasTo('new-worker@rabbitrack.test')
                && $mail->invitation->farm_id === $farm->id
                && $mail->invitation->role === 'worker'
        );
    }

    public function test_member_list_includes_pending_invitations(): void
    {
        $owner = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        FarmInvitation::query()->create([
            'farm_id' => $farm->id,
            'invited_by_id' => $owner->id,
            'email' => 'pending@rabbitrack.test',
            'role' => 'viewer',
        ]);

        Sanctum::actingAs($owner);

        $this->getJson("/api/v1/farms/{$farm->id}/members")
            ->assertOk()
            ->assertJsonPath('data.1.email', 'pending@rabbitrack.test')
            ->assertJsonPath('data.1.status', 'pending');
    }

    public function test_owner_can_resend_pending_invitation(): void
    {
        Mail::fake();
        $owner = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        $invitation = FarmInvitation::query()->create([
            'farm_id' => $farm->id,
            'invited_by_id' => $owner->id,
            'email' => 'resend@rabbitrack.test',
            'role' => 'worker',
        ]);

        Sanctum::actingAs($owner);

        $this->postJson("/api/v1/farms/{$farm->id}/invitations/{$invitation->id}/resend")
            ->assertOk()
            ->assertJsonPath('message', 'Invitation resent.');

        Mail::assertSent(
            FarmInvitationMail::class,
            fn (FarmInvitationMail $mail) => $mail->hasTo('resend@rabbitrack.test')
        );
    }

    public function test_owner_can_cancel_pending_invitation(): void
    {
        $owner = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        $invitation = FarmInvitation::query()->create([
            'farm_id' => $farm->id,
            'invited_by_id' => $owner->id,
            'email' => 'cancel@rabbitrack.test',
            'role' => 'viewer',
        ]);

        Sanctum::actingAs($owner);

        $this->deleteJson("/api/v1/farms/{$farm->id}/invitations/{$invitation->id}")
            ->assertOk()
            ->assertJsonPath('message', 'Invitation cancelled.');

        $this->assertNotNull($invitation->fresh()->revoked_at);

        $this->getJson("/api/v1/farms/{$farm->id}/members")
            ->assertOk()
            ->assertJsonMissing(['email' => 'cancel@rabbitrack.test']);
    }

    public function test_manager_cannot_add_farm_member(): void
    {
        $manager = User::factory()->create();
        $newMember = User::factory()->create(['email' => 'viewer@rabbitrack.test']);
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $manager->id,
            'role' => 'manager',
        ]);

        Sanctum::actingAs($manager);

        $this->postJson("/api/v1/farms/{$farm->id}/members", [
            'email' => $newMember->email,
            'role' => 'viewer',
        ])->assertNotFound();
    }

    public function test_owner_cannot_invite_new_owner(): void
    {
        Mail::fake();
        $owner = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);

        Sanctum::actingAs($owner);

        $this->postJson("/api/v1/farms/{$farm->id}/members", [
            'email' => 'owner-invite@rabbitrack.test',
            'role' => 'owner',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');

        $this->assertDatabaseMissing('farm_invitations', [
            'email' => 'owner-invite@rabbitrack.test',
        ]);
        Mail::assertNothingSent();
    }

    public function test_owner_cannot_add_duplicate_active_member(): void
    {
        $owner = User::factory()->create();
        $worker = User::factory()->create(['email' => 'duplicate@rabbitrack.test']);
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $worker->id,
            'role' => 'worker',
        ]);

        Sanctum::actingAs($owner);

        $this->postJson("/api/v1/farms/{$farm->id}/members", [
            'email' => 'duplicate@rabbitrack.test',
            'role' => 'viewer',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('email');
    }

    public function test_owner_can_update_member_role(): void
    {
        $owner = User::factory()->create();
        $worker = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        $membership = FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $worker->id,
            'role' => 'worker',
        ]);

        Sanctum::actingAs($owner);

        $this->patchJson("/api/v1/farms/{$farm->id}/members/{$membership->id}", [
            'role' => 'manager',
        ])
            ->assertOk()
            ->assertJsonPath('data.role', 'manager');

        $this->assertDatabaseHas('farm_memberships', [
            'id' => $membership->id,
            'role' => 'manager',
        ]);
    }

    public function test_owner_cannot_promote_member_to_owner_role(): void
    {
        $owner = User::factory()->create();
        $worker = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        $membership = FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $worker->id,
            'role' => 'worker',
        ]);

        Sanctum::actingAs($owner);

        $this->patchJson("/api/v1/farms/{$farm->id}/members/{$membership->id}", [
            'role' => 'owner',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');

        $this->assertDatabaseHas('farm_memberships', [
            'id' => $membership->id,
            'role' => 'worker',
        ]);
    }

    public function test_owner_can_remove_member(): void
    {
        $owner = User::factory()->create();
        $worker = User::factory()->create();
        $farm = Farm::factory()->create();
        FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);
        $membership = FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $worker->id,
            'role' => 'worker',
        ]);

        Sanctum::actingAs($owner);

        $this->deleteJson("/api/v1/farms/{$farm->id}/members/{$membership->id}")
            ->assertOk()
            ->assertJsonPath('message', 'Member removed.');

        $this->assertDatabaseHas('farm_memberships', [
            'id' => $membership->id,
            'is_active' => false,
        ]);
    }

    public function test_owner_cannot_remove_last_owner(): void
    {
        $owner = User::factory()->create();
        $farm = Farm::factory()->create();
        $membership = FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);

        Sanctum::actingAs($owner);

        $this->deleteJson("/api/v1/farms/{$farm->id}/members/{$membership->id}")
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');
    }

    public function test_owner_cannot_demote_last_owner(): void
    {
        $owner = User::factory()->create();
        $farm = Farm::factory()->create();
        $membership = FarmMembership::factory()->create([
            'farm_id' => $farm->id,
            'user_id' => $owner->id,
            'role' => 'owner',
        ]);

        Sanctum::actingAs($owner);

        $this->patchJson("/api/v1/farms/{$farm->id}/members/{$membership->id}", [
            'role' => 'manager',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('role');
    }
}
