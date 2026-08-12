<?php

namespace App\Mail;

use App\Models\FarmInvitation;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class FarmInvitationMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public FarmInvitation $invitation)
    {
        $this->invitation->loadMissing(['farm', 'invitedBy']);
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: "You're invited to {$this->invitation->farm->name} on RabbiTrack",
        );
    }

    public function content(): Content
    {
        return new Content(
            markdown: 'emails.farm-invitation',
            with: [
                'farmName' => $this->invitation->farm->name,
                'inviterName' => $this->invitation->invitedBy?->name ?? 'A farm owner',
                'email' => $this->invitation->email,
                'role' => str($this->invitation->role)->replace('_', ' ')->title()->toString(),
                'appUrl' => config('app.url'),
            ],
        );
    }
}
