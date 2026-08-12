<?php

namespace App\Models;

use Database\Factories\HealthEventFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class HealthEvent extends Model
{
    /** @use HasFactory<HealthEventFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    public const SEVERITIES = [
        'mild',
        'moderate',
        'severe',
        'critical',
    ];

    public const STATUSES = [
        'open',
        'monitoring',
        'resolved',
        'closed',
    ];

    protected $fillable = [
        'farm_id',
        'rabbit_id',
        'recorded_by_id',
        'observed_on',
        'symptoms',
        'diagnosis',
        'severity',
        'body_system',
        'isolation_required',
        'status',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'observed_on' => 'date',
            'isolation_required' => 'boolean',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function rabbit(): BelongsTo
    {
        return $this->belongsTo(Rabbit::class);
    }

    public function treatments(): HasMany
    {
        return $this->hasMany(Treatment::class);
    }
}
