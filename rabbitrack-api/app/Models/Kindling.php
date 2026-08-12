<?php

namespace App\Models;

use Database\Factories\KindlingFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Kindling extends Model
{
    /** @use HasFactory<KindlingFactory> */
    use HasFactory, HasUuids;

    protected $fillable = [
        'farm_id',
        'mating_id',
        'litter_id',
        'doe_id',
        'recorded_by_id',
        'kindled_on',
        'kits_born_alive',
        'kits_stillborn',
        'kits_weak',
        'nest_condition',
        'doe_condition',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'kindled_on' => 'date',
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

    public function litter(): BelongsTo
    {
        return $this->belongsTo(Litter::class);
    }

    public function doe(): BelongsTo
    {
        return $this->belongsTo(Rabbit::class, 'doe_id');
    }
}
