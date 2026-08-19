<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OneTimePrekey extends Model
{
    use HasFactory;

    protected $fillable = [
        'device_id',
        'public_key',
        'is_consumed',
    ];

    protected $casts = [
        'is_consumed' => 'boolean',
    ];

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }
}
