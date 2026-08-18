<?php

namespace App\Models;

use Database\Factories\LitterFosterFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LitterFoster extends Model
{
    /** @use HasFactory<LitterFosterFactory> */
    use HasFactory, HasUuids;

    protected $fillable = [
        'farm_id',
        'from_litter_id',
        'to_litter_id',
        'recorded_by_id',
        'fostered_on',
        'kit_count',
        'reason',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'fostered_on' => 'date',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function fromLitter(): BelongsTo
    {
        return $this->belongsTo(Litter::class, 'from_litter_id');
    }

    public function toLitter(): BelongsTo
    {
        return $this->belongsTo(Litter::class, 'to_litter_id');
    }

    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by_id');
    }
}
