<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Backup extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'protocol_version',
        'kdf_version',
        'salt',
        'nonce',
        'ciphertext',
        'auth_tag',
        'created_at_timestamp',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
