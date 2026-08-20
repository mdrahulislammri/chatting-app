<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Call extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'conversation_id',
        'caller_id',
        'caller_device_id',
        'winner_device_id',
        'type',
        'state',
        'is_answered',
        'ended_at',
    ];

    protected $casts = [
        'is_answered' => 'boolean',
        'ended_at' => 'datetime',
    ];

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function caller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'caller_id');
    }

    public function signals(): HasMany
    {
        return $this->hasMany(CallSignal::class);
    }
}
