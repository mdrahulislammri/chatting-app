<?php

namespace App\Services;

use App\Enums\ConversationRole;
use App\Enums\ConversationType;
use App\Enums\MessageType;
use App\Events\MessageSent;
use App\Models\Block;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use InvalidArgumentException;

class ConversationService
{
    public function getOrCreateDirectConversation(User $currentUser, int $targetUserId): Conversation
    {
        if ($currentUser->id === $targetUserId) {
            throw new InvalidArgumentException("Cannot create a direct conversation with yourself.");
        }

        // Check blocking rules
        if ($currentUser->isBlocking($targetUserId) || $currentUser->isBlockedBy($targetUserId)) {
            throw ValidationException::withMessages([
                'conversation' => ['Cannot create direct conversation due to user block settings.'],
            ]);
        }

        $minId = min($currentUser->id, $targetUserId);
        $maxId = max($currentUser->id, $targetUserId);
        $directKey = "{$minId}:{$maxId}";

        $existing = Conversation::where('type', ConversationType::DIRECT->value)
            ->where('direct_key', $directKey)
            ->first();

        if ($existing) {
            $existing->load(['users', 'latestMessage.sender']);
            return $existing;
        }

        return DB::transaction(function () use ($currentUser, $targetUserId, $directKey) {
            $conversation = Conversation::create([
                'type' => ConversationType::DIRECT,
                'direct_key' => $directKey,
            ]);

            $conversation->users()->attach([
                $currentUser->id => ['role' => ConversationRole::ADMIN->value],
                $targetUserId => ['role' => ConversationRole::MEMBER->value],
            ]);

            $conversation->load(['users', 'latestMessage.sender']);
            return $conversation;
        });
    }

    public function createGroupConversation(User $creator, string $name, array $memberIds): Conversation
    {
        return DB::transaction(function () use ($creator, $name, $memberIds) {
            $conversation = Conversation::create([
                'type' => ConversationType::GROUP,
                'name' => $name,
                'direct_key' => null,
            ]);

            $uniqueMemberIds = array_values(array_unique(array_merge([$creator->id], $memberIds)));

            $pivotData = [];
            foreach ($uniqueMemberIds as $id) {
                $pivotData[$id] = [
                    'role' => $id === $creator->id ? ConversationRole::ADMIN->value : ConversationRole::MEMBER->value,
                ];
            }

            $conversation->users()->attach($pivotData);

            $systemMsg = Message::create([
                'conversation_id' => $conversation->id,
                'sender_id' => $creator->id,
                'content' => "{$creator->name} created the group \"{$name}\"",
                'type' => MessageType::SYSTEM,
                'client_message_id' => (string) Str::uuid(),
            ]);

            MessageSent::dispatch($systemMsg);

            $conversation->load(['users', 'latestMessage.sender']);
            return $conversation;
        });
    }

    public function addMembers(User $admin, Conversation $conversation, array $memberIds): void
    {
        DB::transaction(function () use ($admin, $conversation, $memberIds) {
            $existingIds = $conversation->users()->pluck('users.id')->toArray();
            $newIds = array_values(array_diff($memberIds, $existingIds));

            if (!empty($newIds)) {
                $pivotData = [];
                foreach ($newIds as $id) {
                    $pivotData[$id] = ['role' => ConversationRole::MEMBER->value];
                }
                $conversation->users()->attach($pivotData);

                $newUsers = User::whereIn('id', $newIds)->pluck('name')->implode(', ');
                $systemMsg = Message::create([
                    'conversation_id' => $conversation->id,
                    'sender_id' => $admin->id,
                    'content' => "{$admin->name} added {$newUsers} to the group",
                    'type' => MessageType::SYSTEM,
                    'client_message_id' => (string) Str::uuid(),
                ]);

                MessageSent::dispatch($systemMsg);
            }
        });
    }

    public function removeMember(User $actor, Conversation $conversation, User $targetUser): void
    {
        DB::transaction(function () use ($actor, $conversation, $targetUser) {
            $adminCount = $conversation->users()
                ->wherePivot('role', ConversationRole::ADMIN->value)
                ->count();

            $isTargetAdmin = $conversation->users()
                ->where('users.id', $targetUser->id)
                ->wherePivot('role', ConversationRole::ADMIN->value)
                ->exists();

            $isSelf = $actor->id === $targetUser->id;

            if ($isTargetAdmin && $adminCount <= 1) {
                $otherMemberCount = $conversation->users()->where('users.id', '!=', $targetUser->id)->count();
                if ($otherMemberCount > 0) {
                    throw ValidationException::withMessages([
                        'group' => ['Cannot leave or remove the sole admin of the group. Promote another member to admin first.'],
                    ]);
                }
            }

            $conversation->users()->detach($targetUser->id);

            $text = $isSelf
                ? "{$targetUser->name} left the group"
                : "{$actor->name} removed {$targetUser->name} from the group";

            $systemMsg = Message::create([
                'conversation_id' => $conversation->id,
                'sender_id' => $actor->id,
                'content' => $text,
                'type' => MessageType::SYSTEM,
                'client_message_id' => (string) Str::uuid(),
            ]);

            MessageSent::dispatch($systemMsg);
        });
    }

    public function updateMemberRole(User $admin, Conversation $conversation, User $targetUser, string $newRole): void
    {
        DB::transaction(function () use ($admin, $conversation, $targetUser, $newRole) {
            if ($newRole === ConversationRole::MEMBER->value) {
                $adminCount = $conversation->users()
                    ->wherePivot('role', ConversationRole::ADMIN->value)
                    ->count();

                $isTargetAdmin = $conversation->users()
                    ->where('users.id', $targetUser->id)
                    ->wherePivot('role', ConversationRole::ADMIN->value)
                    ->exists();

                if ($isTargetAdmin && $adminCount <= 1) {
                    throw ValidationException::withMessages([
                        'group' => ['Cannot demote the sole admin of the group. Promote another member first.'],
                    ]);
                }
            }

            $conversation->users()->updateExistingPivot($targetUser->id, [
                'role' => $newRole,
            ]);

            $text = $newRole === ConversationRole::ADMIN->value
                ? "{$admin->name} made {$targetUser->name} an admin"
                : "{$admin->name} removed {$targetUser->name} from admins";

            $systemMsg = Message::create([
                'conversation_id' => $conversation->id,
                'sender_id' => $admin->id,
                'content' => $text,
                'type' => MessageType::SYSTEM,
                'client_message_id' => (string) Str::uuid(),
            ]);

            MessageSent::dispatch($systemMsg);
        });
    }

    public function muteConversation(User $user, Conversation $conversation, ?string $mutedUntil): void
    {
        $conversation->users()->updateExistingPivot($user->id, [
            'muted_until' => $mutedUntil ? now()->parse($mutedUntil) : null,
        ]);
    }

    public function archiveConversation(User $user, Conversation $conversation, bool $archive): void
    {
        $conversation->users()->updateExistingPivot($user->id, [
            'archived_at' => $archive ? now() : null,
        ]);
    }

    public function blockUser(User $blocker, User $targetUser): void
    {
        if ($blocker->id === $targetUser->id) {
            throw ValidationException::withMessages([
                'block' => ['You cannot block yourself.'],
            ]);
        }

        Block::firstOrCreate([
            'blocker_id' => $blocker->id,
            'blocked_id' => $targetUser->id,
        ]);
    }

    public function unblockUser(User $blocker, User $targetUser): void
    {
        Block::where('blocker_id', $blocker->id)
            ->where('blocked_id', $targetUser->id)
            ->delete();
    }
}
