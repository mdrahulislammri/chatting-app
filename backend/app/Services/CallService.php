<?php

namespace App\Services;

use App\Models\Call;
use App\Models\CallSignal;
use App\Models\Conversation;
use App\Models\Device;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CallService
{
    protected static array $allowedTransitions = [
        'initiating' => ['ringing', 'ended', 'failed'],
        'ringing' => ['connecting', 'ended', 'failed'],
        'connecting' => ['connected', 'ended', 'failed'],
        'connected' => ['ended', 'failed'],
        'ended' => [],
        'failed' => [],
    ];

    public function initiateCall(User $caller, Conversation $conversation, array $data): Call
    {
        // 1. Authorization check: conversation membership
        if (!$conversation->users()->where('users.id', $caller->id)->exists()) {
            throw ValidationException::withMessages(['conversation' => 'Unauthorized conversation access.']);
        }

        // 2. Bidirectional blocking check
        $otherUser = $conversation->users()->where('users.id', '!=', $caller->id)->first();
        if ($otherUser && ($caller->isBlocking($otherUser->id) || $caller->isBlockedBy($otherUser->id))) {
            throw ValidationException::withMessages(['blocking' => 'Calling is blocked between these users.']);
        }

        // 3. Active device check
        $callerDevice = Device::find($data['caller_device_id']);
        if (!$callerDevice || !$callerDevice->is_active) {
            throw ValidationException::withMessages(['device' => 'Device is revoked or inactive.']);
        }

        return DB::transaction(function () use ($caller, $conversation, $data) {
            $call = Call::create([
                'conversation_id' => $conversation->id,
                'caller_id' => $caller->id,
                'caller_device_id' => $data['caller_device_id'],
                'type' => $data['type'] ?? 'audio',
                'state' => 'initiating',
                'is_answered' => false,
            ]);

            return $call;
        });
    }

    public function processSignal(User $sender, Call $call, array $data): array
    {
        // 1. Membership & Freshness check
        if (!$call->conversation->users()->where('users.id', $sender->id)->exists()) {
            throw ValidationException::withMessages(['conversation' => 'Unauthorized call signaling access.']);
        }

        $nowMs = (int) (microtime(true) * 1000);
        $timestampMs = (int) ($data['timestamp_ms'] ?? $nowMs);
        if (($nowMs - $timestampMs) > 30000) {
            throw ValidationException::withMessages(['signal' => 'Stale signaling payload rejected (>30s old).']);
        }

        $signalType = $data['type'];

        // 2. Atomic Multi-Device Answer Race Condition Lock
        if ($signalType === 'answer') {
            return DB::transaction(function () use ($sender, $call, $data, $timestampMs) {
                $lockedCall = Call::where('id', $call->id)->lockForUpdate()->first();

                if ($lockedCall->is_answered || $lockedCall->state === 'ended') {
                    throw ValidationException::withMessages([
                        'call' => 'Call already answered by another device or ended.',
                    ]);
                }

                $this->transitionState($lockedCall, 'connecting');
                $lockedCall->update([
                    'is_answered' => true,
                    'winner_device_id' => $data['sender_device_id'],
                ]);

                $signal = CallSignal::create([
                    'call_id' => $lockedCall->id,
                    'sender_id' => $sender->id,
                    'sender_device_id' => $data['sender_device_id'],
                    'type' => 'answer',
                    'payload' => json_encode($data['payload'] ?? []),
                    'sequence_number' => $data['sequence_number'] ?? 1,
                    'timestamp_ms' => $timestampMs,
                ]);

                return ['status' => 'winner', 'call' => $lockedCall, 'signal' => $signal];
            });
        }

        // Handle other signals (offer, ice_candidate, end, reject)
        return DB::transaction(function () use ($sender, $call, $data, $signalType, $timestampMs) {
            $lockedCall = Call::where('id', $call->id)->lockForUpdate()->first();

            if ($signalType === 'end' || $signalType === 'reject') {
                $this->transitionState($lockedCall, 'ended');
                $lockedCall->ended_at = now();
            } else if ($signalType === 'offer') {
                $this->transitionState($lockedCall, 'ringing');
            }

            $lockedCall->save();

            $signal = CallSignal::create([
                'call_id' => $lockedCall->id,
                'sender_id' => $sender->id,
                'sender_device_id' => $data['sender_device_id'],
                'type' => $signalType,
                'payload' => json_encode($data['payload'] ?? []),
                'sequence_number' => $data['sequence_number'] ?? 1,
                'timestamp_ms' => $timestampMs,
            ]);

            return ['status' => 'success', 'call' => $lockedCall, 'signal' => $signal];
        });
    }

    protected function transitionState(Call $call, String $newState): void
    {
        $currentState = $call->state;

        if ($currentState === $newState) {
            return;
        }

        $allowed = self::$allowedTransitions[$currentState] ?? [];
        if (!in_array($newState, $allowed, true)) {
            throw ValidationException::withMessages([
                'state' => "Invalid call state transition from [{$currentState}] to [{$newState}].",
            ]);
        }

        $call->state = $newState;
    }

    public function pruneStaleCalls(int $timeoutSeconds = 60): int
    {
        $cutoff = now()->subSeconds($timeoutSeconds);

        return Call::whereIn('state', ['initiating', 'ringing', 'connecting'])
            ->where('created_at', '<=', $cutoff)
            ->update([
                'state' => 'failed',
                'ended_at' => now(),
            ]);
    }
}
