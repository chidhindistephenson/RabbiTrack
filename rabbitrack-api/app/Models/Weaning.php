<?php

namespace App\Models;

use Database\Factories\WeaningFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Weaning extends Model
{
    /** @use HasFactory<WeaningFactory> */
    use HasFactory, HasUuids;

    protected $fillable = [
        'farm_id',
        'litter_id',
        'doe_id',
        'recorded_by_id',
        'weaned_on',
        'number_weaned',
        'average_weight_value',
        'weight_unit',
        'destination',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'weaned_on' => 'date',
            'average_weight_value' => 'decimal:3',
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

    public function doe(): BelongsTo
    {
        return $this->belongsTo(Rabbit::class, 'doe_id');
    }
}
