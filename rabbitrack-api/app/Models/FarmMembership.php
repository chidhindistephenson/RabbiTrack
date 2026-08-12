<?php

namespace App\Models;

use Database\Factories\FarmMembershipFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FarmMembership extends Model
{
    /** @use HasFactory<FarmMembershipFactory> */
    use HasFactory, HasUuids;

    public const ROLES = [
        'owner',
        'administrator',
        'manager',
        'worker',
        'veterinarian',
        'viewer',
    ];

    protected $fillable = [
        'farm_id',
        'user_id',
        'role',
        'is_active',
        'joined_at',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'joined_at' => 'datetime',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
