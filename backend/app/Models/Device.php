<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Device extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'name',
        'public_identity_key',
        'is_active',
        'push_token',
        'platform',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function prekeyBundle(): HasOne
    {
        return $this->hasOne(PrekeyBundleModel::class, 'device_id');
    }

    public function oneTimePrekeys(): HasMany
    {
        return $this->hasMany(OneTimePrekey::class, 'device_id');
    }
}
