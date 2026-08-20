<?php

namespace App\Services;

use App\Models\User;

class TurnCredentialService
{
    public function generateCredentials(User $user, int $ttlSeconds = 3600): array
    {
        $turnSecret = config('services.turn.secret', 'e2e_turn_default_secret_key');
        $turnUrl = config('services.turn.url', 'turn:turn.e2e.internal:3478');

        $timestamp = time() + $ttlSeconds;
        $username = "{$timestamp}:{$user->id}";

        // HMAC-SHA1 short-lived TURN REST credential derivation
        $password = base64_encode(hash_hmac('sha1', $username, $turnSecret, true));

        return [
            'username' => $username,
            'password' => $password,
            'ttl' => $ttlSeconds,
            'uris' => [
                $turnUrl,
                "turns:turn.e2e.internal:5349",
            ],
        ];
    }
}
