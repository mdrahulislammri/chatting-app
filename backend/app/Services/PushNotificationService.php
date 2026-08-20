<?php

namespace App\Services;

use App\Models\Conversation;
use App\Models\Device;
use App\Models\Message;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class PushNotificationService
{
    public function sendNewMessageNotification(Message $message, Conversation $conversation): void
    {
        try {
            $sender = $message->sender;

            // Fetch active recipient devices for participants other than sender
            $recipientUsers = $conversation->users()
                ->where('users.id', '!=', $message->sender_id)
                ->get();

            foreach ($recipientUsers as $recipient) {
                // 1. Suppress if blocked relationship exists
                if ($sender && ($sender->isBlocking($recipient->id) || $sender->isBlockedBy($recipient->id))) {
                    continue;
                }

                // 2. Suppress if conversation is muted by recipient
                $pivot = $recipient->pivot ?? $conversation->users()->where('users.id', $recipient->id)->first()?->pivot;
                if ($pivot && !is_null($pivot->muted_at)) {
                    continue;
                }

                // 3. Dispatch ultra-private minimal push notification payload per device
                $devices = Device::where('user_id', $recipient->id)
                    ->where('is_active', true)
                    ->whereNotNull('push_token')
                    ->get();

                foreach ($devices as $device) {
                    $this->dispatchDevicePush($device, [
                        'type' => 'new_message',
                        'notification_id' => (string) Str::uuid(),
                        'recipient_device_id' => $device->id,
                    ]);
                }
            }
        } catch (\Throwable $e) {
            // Delivery Isolation: Push notification dispatch failure MUST NOT interrupt message DB transaction
            Log::warning('Push notification dispatch suppressed on error: ' . $e->getMessage());
        }
    }

    protected function dispatchDevicePush(Device $device, array $payload): void
    {
        // Mock FCM/APNs Provider Dispatch Hook
        // Ultra-private payload: zero plaintext, zero sender_id, zero keys in push body
        Log::info("Dispatched Push Alert to Device [{$device->id}] ({$device->platform}): " . json_encode($payload));
    }
}
