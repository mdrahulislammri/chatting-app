<?php

namespace App\Policies;

use App\Enums\ConversationRole;
use App\Models\Conversation;
use App\Models\User;

class ConversationPolicy
{
    public function view(User $user, Conversation $conversation): bool
    {
        return $conversation->users()->where('users.id', $user->id)->exists();
    }

    public function sendMessage(User $user, Conversation $conversation): bool
    {
        return $conversation->users()->where('users.id', $user->id)->exists();
    }

    public function manageMembers(User $user, Conversation $conversation): bool
    {
        if ($conversation->type?->value !== 'group' && $conversation->type !== 'group') {
            return false;
        }

        return $conversation->users()
            ->where('users.id', $user->id)
            ->wherePivot('role', ConversationRole::ADMIN->value)
            ->exists();
    }
}
