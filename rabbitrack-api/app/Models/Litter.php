<?php

namespace App\Models;

use Database\Factories\LitterFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Litter extends Model
{
    /** @use HasFactory<LitterFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    public const STATUSES = [
        'newborn',
        'nursing',
        'partially_weaned',
        'weaned',
        'closed',
        'archived',
    ];

    protected $fillable = [
        'farm_id',
        'identifier',
        'doe_id',
        'buck_id',
        'mating_id',
        'kindled_on',
        'kits_born_alive',
        'kits_stillborn',
        'kits_weak',
        'current_live_count',
        'planned_weaning_on',
        'status',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'kindled_on' => 'date',
            'planned_weaning_on' => 'date',
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

    public function mating(): BelongsTo
    {
        return $this->belongsTo(Mating::class);
    }

    public function weanings(): HasMany
    {
        return $this->hasMany(Weaning::class);
    }

    public function checks(): HasMany
    {
        return $this->hasMany(LitterCheck::class);
    }

    public function fostersOut(): HasMany
    {
        return $this->hasMany(LitterFoster::class, 'from_litter_id');
    }

    public function fostersIn(): HasMany
    {
        return $this->hasMany(LitterFoster::class, 'to_litter_id');
    }

    public function weightRecords(): HasMany
    {
        return $this->hasMany(WeightRecord::class);
    }
}
