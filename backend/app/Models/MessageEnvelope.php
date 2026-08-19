<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MessageEnvelope extends Model
{
    use HasFactory;

    protected $fillable = [
        'message_id',
        'sender_device_id',
        'recipient_device_id',
        'sequence_number',
        'dh_public_key',
        'ciphertext',
        'auth_tag',
    ];

    public function message(): BelongsTo
    {
        return $this->belongsTo(Message::class);
    }

    public function senderDevice(): BelongsTo
    {
        return $this->belongsTo(Device::class, 'sender_device_id');
    }

    public function recipientDevice(): BelongsTo
    {
        return $this->belongsTo(Device::class, 'recipient_device_id');
    }
}
