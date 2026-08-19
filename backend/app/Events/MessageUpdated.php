<?php

namespace App\Events;

use App\Http\Resources\Api\V1\MessageResource;
use App\Models\Message;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

class MessageUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets;

    public array $messageData;
    public int $conversationId;

    public function __construct(Message $message)
    {
        $message->loadMissing(['sender', 'replyTo']);
        $this->conversationId = $message->conversation_id;
        $this->messageData = (new MessageResource($message))->resolve();
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('conversation.' . $this->conversationId),
        ];
    }

    public function broadcastAs(): string
    {
        return 'message.updated';
    }
}
