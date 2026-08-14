<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class GoogleIdTokenVerifier
{
    /**
     * @return array{sub:string,email:string,email_verified:bool,name?:string,picture?:string}
     */
    public function verify(string $idToken): array
    {
        $clientId = config('services.google.client_id');

        if (! is_string($clientId) || trim($clientId) === '') {
            throw ValidationException::withMessages([
                'id_token' => ['Google sign-in is not configured on the API server.'],
            ]);
        }

        $parts = explode('.', $idToken);
        if (count($parts) !== 3) {
            throw $this->invalidToken();
        }

        [$encodedHeader, $encodedPayload, $encodedSignature] = $parts;
        $header = $this->decodeJson($encodedHeader);
        $payload = $this->decodeJson($encodedPayload);

        if (($header['alg'] ?? null) !== 'RS256' || ! is_string($header['kid'] ?? null)) {
            throw $this->invalidToken();
        }

        $cert = $this->certificates()[$header['kid']] ?? null;
        if (! is_string($cert)) {
            throw $this->invalidToken();
        }

        $signature = $this->base64UrlDecode($encodedSignature);
        $verified = openssl_verify(
            "{$encodedHeader}.{$encodedPayload}",
            $signature,
            $cert,
            OPENSSL_ALGO_SHA256,
        );

        if ($verified !== 1) {
            throw $this->invalidToken();
        }

        $now = time();
        if (
            ! in_array($payload['iss'] ?? null, ['accounts.google.com', 'https://accounts.google.com'], true)
            || ($payload['aud'] ?? null) !== $clientId
            || ! is_numeric($payload['exp'] ?? null)
            || (int) $payload['exp'] < $now
            || ! is_string($payload['sub'] ?? null)
            || ! is_string($payload['email'] ?? null)
            || ($payload['email_verified'] ?? false) !== true
        ) {
            throw $this->invalidToken();
        }

        return $payload;
    }

    /**
     * @return array<string,string>
     */
    private function certificates(): array
    {
        return Cache::remember('google_oauth_certs', now()->addHours(6), function (): array {
            $response = Http::timeout(8)
                ->acceptJson()
                ->get('https://www.googleapis.com/oauth2/v1/certs');

            if (! $response->ok()) {
                throw ValidationException::withMessages([
                    'id_token' => ['Google sign-in could not verify the account right now.'],
                ]);
            }

            return $response->json();
        });
    }

    /**
     * @return array<string,mixed>
     */
    private function decodeJson(string $value): array
    {
        $decoded = json_decode($this->base64UrlDecode($value), true);

        if (! is_array($decoded)) {
            throw $this->invalidToken();
        }

        return $decoded;
    }

    private function base64UrlDecode(string $value): string
    {
        $base64 = strtr($value, '-_', '+/');
        $remainder = strlen($base64) % 4;
        $padded = $remainder === 0
            ? $base64
            : str_pad($base64, strlen($base64) + 4 - $remainder, '=', STR_PAD_RIGHT);
        $decoded = base64_decode($padded, true);

        if ($decoded === false) {
            throw $this->invalidToken();
        }

        return $decoded;
    }

    private function invalidToken(): ValidationException
    {
        return ValidationException::withMessages([
            'id_token' => ['Google sign-in could not verify this account.'],
        ]);
    }
}
