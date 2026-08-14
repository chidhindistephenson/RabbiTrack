<?php

namespace App\Models;

use Database\Factories\WeightRecordFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WeightRecord extends Model
{
    /** @use HasFactory<WeightRecordFactory> */
    use HasFactory, HasUuids;

    protected $fillable = [
        'farm_id',
        'rabbit_id',
        'litter_id',
        'stage',
        'recorded_by_id',
        'weighed_on',
        'weight_value',
        'weight_unit',
        'kit_count',
        'average_weight_value',
        'method',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'weighed_on' => 'date',
            'weight_value' => 'decimal:3',
            'average_weight_value' => 'decimal:3',
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

    public function litter(): BelongsTo
    {
        return $this->belongsTo(Litter::class);
    }
}
