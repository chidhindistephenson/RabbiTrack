<?php

namespace App\Models;

use Database\Factories\MatingFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Mating extends Model
{
    /** @use HasFactory<MatingFactory> */
    use HasFactory, HasUuids;

    public const OUTCOMES = [
        'observed',
        'attempted',
        'uncertain',
    ];

    public const STATUSES = [
        'awaiting_pregnancy_check',
        'pregnant',
        'not_pregnant',
        'uncertain',
        'kindled',
        'closed',
    ];

    protected $fillable = [
        'farm_id',
        'doe_id',
        'buck_id',
        'recorded_by_id',
        'mated_at',
        'outcome',
        'behavior_observed',
        'pregnancy_check_due_on',
        'expected_kindling_on',
        'nest_box_due_on',
        'status',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'mated_at' => 'datetime',
            'pregnancy_check_due_on' => 'date',
            'expected_kindling_on' => 'date',
            'nest_box_due_on' => 'date',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function doe(): BelongsTo
    {
        return $this->belongsTo(Rabbit::class, 'doe_id');
    }

    public function buck(): BelongsTo
    {
        return $this->belongsTo(Rabbit::class, 'buck_id');
    }

    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by_id');
    }

    public function pregnancyChecks(): HasMany
    {
        return $this->hasMany(PregnancyCheck::class);
    }

    public function litters(): HasMany
    {
        return $this->hasMany(Litter::class);
    }
}
