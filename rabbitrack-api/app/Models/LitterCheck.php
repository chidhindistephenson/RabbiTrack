<?php

namespace App\Models;

use Database\Factories\LitterCheckFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LitterCheck extends Model
{
    /** @use HasFactory<LitterCheckFactory> */
    use HasFactory, HasUuids;

    protected $fillable = [
        'farm_id',
        'litter_id',
        'recorded_by_id',
        'checked_on',
        'live_count',
        'dead_count',
        'weak_count',
        'suspected_cause',
        'nest_observation',
        'corrective_action',
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

    public function litter(): BelongsTo
    {
        return $this->belongsTo(Litter::class);
    }

    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by_id');
    }
}
