<x-mail::message>
# You're invited to {{ $farmName }}

{{ $inviterName }} invited you to join **{{ $farmName }}** on RabbiTrack as **{{ $role }}**.

Use this email address when you sign up or log in:

**{{ $email }}**

Once you enter RabbiTrack with this email, your access to the farm dashboard will be connected automatically.

<x-mail::button :url="$appUrl">
Open RabbiTrack
</x-mail::button>

Thanks,<br>
{{ config('app.name') }}
</x-mail::message>
