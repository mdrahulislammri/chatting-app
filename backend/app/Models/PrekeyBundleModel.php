<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PrekeyBundleModel extends Model
{
    use HasFactory;

    protected $table = 'prekey_bundles';

    protected $fillable = [
        'device_id',
        'signed_prekey',
        'signed_prekey_signature',
    ];

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }
}
