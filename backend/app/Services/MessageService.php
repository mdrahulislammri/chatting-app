<?php

namespace App\Services;

use App\Events\MessageSent;
use App\Events\MessageUpdated;
use App\Events\UserTyping;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\MessageEnvelope;
use App\Models\MessageRead;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class MessageService
{
    public function sendMessage(User $sender, Conversation $conversation, array $data): Message
    {
        // 1. Authorization check
        if (!$conversation->users()->where('users.id', $sender->id)->exists()) {
            throw ValidationException::withMessages(['conversation' => 'Unauthorized conversation access.']);
        }

        // 2. Bidirectional blocking check
        $typeVal = is_object($conversation->type) ? $conversation->type->value : (string) $conversation->type;
        if ($typeVal === 'direct') {
            $otherUser = $conversation->users()->where('users.id', '!=', $sender->id)->first();
            if ($otherUser && ($sender->isBlocking($otherUser->id) || $sender->isBlockedBy($otherUser->id))) {
                throw ValidationException::withMessages(['blocking' => 'Messaging is blocked between these users.']);
            }
        }

        // 3. Client-side message deduplication
        if (isset($data['client_message_id'])) {
            $existing = Message::where('conversation_id', $conversation->id)
                ->where('client_message_id', $data['client_message_id'])
                ->first();

            if ($existing) {
                return $existing;
            }
        }

        return DB::transaction(function () use ($sender, $conversation, $data) {
            // Unarchive conversation for participants (keep mute status intact)
            $conversation->users()->updateExistingPivot(
                $conversation->users->pluck('id'),
                ['archived_at' => null]
            );

            // Plaintext Elimination: For E2EE messages, messages.content MUST be NULL (or masked)
            $content = isset($data['envelopes']) ? null : ($data['content'] ?? null);

            $message = Message::create([
                'conversation_id' => $conversation->id,
                'sender_id' => $sender->id,
                'client_message_id' => $data['client_message_id'] ?? null,
                'reply_to_id' => $data['reply_to_id'] ?? null,
                'type' => $data['type'] ?? 'text',
                'content' => $content,
                'attachment_url' => $data['attachment_url'] ?? null,
                'attachment_name' => $data['attachment_name'] ?? null,
                'attachment_size' => $data['attachment_size'] ?? null,
                'mime_type' => $data['mime_type'] ?? null,
            ]);

            // Multi-Device Envelope Packaging & Storage
            if (isset($data['envelopes']) && is_array($data['envelopes'])) {
                foreach ($data['envelopes'] as $env) {
                    MessageEnvelope::create([
                        'message_id' => $message->id,
                        'sender_device_id' => $env['sender_device_id'],
                        'recipient_device_id' => $env['recipient_device_id'],
                        'sequence_number' => $env['sequence_number'] ?? 0,
                        'dh_public_key' => $env['dh_public_key'] ?? null,
                        'ciphertext' => $env['ciphertext'],
                        'auth_tag' => $env['auth_tag'] ?? null,
                    ]);
                }
            }

            // Fire real-time WebSocket broadcast after DB transaction commits
            DB::afterCommit(function () use ($message) {
                broadcast(new MessageSent($message))->toOthers();
            });

            $message->load(['sender', 'replyTo', 'reactions', 'envelopes']);
            return $message;
        });
    }

    public function editMessage(User $user, Message $message, string $newContent): Message
    {
        if ($message->sender_id !== $user->id) {
            throw ValidationException::withMessages(['message' => 'Only message sender can edit.']);
        }

        if ($message->trashed()) {
            throw ValidationException::withMessages(['message' => 'Deleted message cannot be edited.']);
        }

        $message->update(['content' => $newContent]);
        broadcast(new MessageUpdated($message))->toOthers();

        return $message;
    }

    public function deleteMessage(User $user, Message $message): bool
    {
        if ($message->sender_id !== $user->id) {
            throw ValidationException::withMessages(['message' => 'Only message sender can delete.']);
        }

        $deleted = $message->delete();
        broadcast(new MessageUpdated($message))->toOthers();

        return (bool) $deleted;
    }

    public function toggleReaction(User $user, Conversation $conversation, Message $message, string $reaction): array
    {
        if ($message->trashed()) {
            throw ValidationException::withMessages(['message' => 'Cannot react to deleted message.']);
        }

        $existing = $message->reactions()->where('user_id', $user->id)->where('reaction', $reaction)->first();

        if ($existing) {
            $existing->delete();
            return ['action' => 'removed', 'reaction' => $reaction];
        }

        $message->reactions()->create([
            'user_id' => $user->id,
            'reaction' => $reaction,
        ]);

        return ['action' => 'added', 'reaction' => $reaction];
    }

    public function searchMessages(Conversation $conversation, string $query): Collection
    {
        return Message::where('conversation_id', $conversation->id)
            ->whereNull('deleted_at')
            ->where('content', 'LIKE', "%{$query}%")
            ->get();
    }

    public function markAsRead(User $user, Conversation $conversation, Message $message): void
    {
        MessageRead::firstOrCreate([
            'message_id' => $message->id,
            'user_id' => $user->id,
        ]);
    }

    public function sendTyping(User $user, Conversation $conversation, bool $isTyping): void
    {
        broadcast(new UserTyping($conversation->id, $user, $isTyping))->toOthers();
    }

    public function getMessages(Conversation $conversation, int $limit = 50): Collection
    {
        return Message::withTrashed()->with(['sender', 'replyTo', 'reactions', 'envelopes'])
            ->where('conversation_id', $conversation->id)
            ->latest()
            ->take($limit)
            ->get()
            ->reverse();
    }
}
