<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $isDeleted = $this->resource->trashed();
        $isEdited = $this->updated_at->gt($this->created_at);

        $reactionsGrouped = $this->whenLoaded('reactions', function () use ($request) {
            return $this->reactions
                ->groupBy('reaction')
                ->map(function ($items, $reaction) use ($request) {
                    return [
                        'reaction' => $reaction,
                        'count' => $items->count(),
                        'has_reacted' => $items->contains('user_id', $request->user()?->id),
                    ];
                })->values();
        });

        return [
            'id' => $this->id,
            'conversation_id' => $this->conversation_id,
            'sender' => $this->sender ? [
                'id' => $this->sender->id,
                'name' => $this->sender->name,
                'email' => $this->sender->email,
            ] : null,
            'client_message_id' => $this->client_message_id,
            'type' => $this->type,
            'content' => $isDeleted ? 'This message was deleted' : $this->content,
            'attachment' => $this->attachment_url ? [
                'type' => $this->mime_type,
                'attachment_name' => $this->attachment_name,
                'attachment_size' => $this->attachment_size,
                'download_url' => $this->attachment_url,
            ] : null,
            'reply_to' => $this->whenLoaded('replyTo', function () {
                if (!$this->replyTo) return null;
                return [
                    'id' => $this->replyTo->id,
                    'sender_name' => $this->replyTo->sender?->name,
                    'content' => $this->replyTo->trashed() ? 'This message was deleted' : $this->replyTo->content,
                    'is_deleted' => $this->replyTo->trashed(),
                ];
            }),
            'reactions' => $reactionsGrouped,
            'envelopes' => $this->whenLoaded('envelopes', function () {
                return $this->envelopes->map(function ($env) {
                    return [
                        'id' => $env->id,
                        'sender_device_id' => $env->sender_device_id,
                        'recipient_device_id' => $env->recipient_device_id,
                        'sequence_number' => $env->sequence_number,
                        'dh_public_key' => $env->dh_public_key,
                        'ciphertext' => $env->ciphertext,
                        'auth_tag' => $env->auth_tag,
                    ];
                });
            }),
            'is_edited' => $isEdited,
            'is_deleted' => $isDeleted,
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}
