<?php

namespace App\Models;

use Database\Factories\PregnancyCheckFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PregnancyCheck extends Model
{
    /** @use HasFactory<PregnancyCheckFactory> */
    use HasFactory, HasUuids;

    public const RESULTS = [
        'pregnant',
        'not_pregnant',
        'uncertain',
        'not_checked',
    ];

    protected $fillable = [
        'farm_id',
        'mating_id',
        'doe_id',
        'examiner_id',
        'checked_on',
        'result',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'checked_on' => 'date',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function mating(): BelongsTo
    {
        return $this->belongsTo(Mating::class);
    }

    public function doe(): BelongsTo
    {
        return $this->belongsTo(Rabbit::class, 'doe_id');
    }

    public function examiner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'examiner_id');
    }
}
