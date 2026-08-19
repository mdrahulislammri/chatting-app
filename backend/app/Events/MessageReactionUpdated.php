<?php

namespace App\Events;

use App\Models\User;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

class MessageReactionUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets;

    public int $conversationId;
    public int $messageId;
    public int $userId;
    public string $reaction;
    public string $action; // 'added' or 'removed'

    public function __construct(int $conversationId, int $messageId, User $user, string $reaction, string $action)
    {
        $this->conversationId = $conversationId;
        $this->messageId = $messageId;
        $this->userId = $user->id;
        $this->reaction = $reaction;
        $this->action = $action;
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('conversation.' . $this->conversationId),
        ];
    }

    public function broadcastAs(): string
    {
        return 'message.reaction';
    }
}
