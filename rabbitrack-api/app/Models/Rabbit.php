<?php

namespace App\Models;

use Database\Factories\RabbitFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Rabbit extends Model
{
    /** @use HasFactory<RabbitFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    public const SEXES = [
        'female',
        'male',
        'unknown',
    ];

    public const STATUSES = [
        'growing',
        'available_for_breeding',
        'mated',
        'awaiting_pregnancy_check',
        'pregnant',
        'nursing',
        'resting',
        'quarantined',
        'under_treatment',
        'ready_for_sale',
        'sold',
        'retired',
        'deceased',
        'culled',
    ];

    public const ORIGIN_TYPES = [
        'born_on_farm',
        'purchased',
        'transferred_in',
        'existing_stock',
    ];

    protected $fillable = [
        'farm_id',
        'identifier',
        'name',
        'sex',
        'date_of_birth',
        'breed',
        'colour',
        'markings',
        'weight_value',
        'weight_unit',
        'tag_or_tattoo',
        'status',
        'current_location_id',
        'mother_id',
        'father_id',
        'origin_type',
        'origin_litter_id',
        'is_farm_born',
        'supplier',
        'acquired_at',
        'acquisition_cost',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'weight_value' => 'decimal:3',
            'is_farm_born' => 'boolean',
            'acquired_at' => 'date',
            'acquisition_cost' => 'decimal:2',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function currentLocation(): BelongsTo
    {
        return $this->belongsTo(Location::class, 'current_location_id');
    }

    public function mother(): BelongsTo
    {
        return $this->belongsTo(Rabbit::class, 'mother_id');
    }

    public function father(): BelongsTo
    {
        return $this->belongsTo(Rabbit::class, 'father_id');
    }

    public function originLitter(): BelongsTo
    {
        return $this->belongsTo(Litter::class, 'origin_litter_id');
    }

    public function movements(): HasMany
    {
        return $this->hasMany(RabbitMovement::class);
    }

    public function doeMatings(): HasMany
    {
        return $this->hasMany(Mating::class, 'doe_id');
    }

    public function buckMatings(): HasMany
    {
        return $this->hasMany(Mating::class, 'buck_id');
    }

    public function tasks(): HasMany
    {
        return $this->hasMany(Task::class);
    }

    public function pregnancyChecks(): HasMany
    {
        return $this->hasMany(PregnancyCheck::class, 'doe_id');
    }

    public function littersAsDoe(): HasMany
    {
        return $this->hasMany(Litter::class, 'doe_id');
    }

    public function littersAsBuck(): HasMany
    {
        return $this->hasMany(Litter::class, 'buck_id');
    }

    public function weanings(): HasMany
    {
        return $this->hasMany(Weaning::class, 'doe_id');
    }

    public function weightRecords(): HasMany
    {
        return $this->hasMany(WeightRecord::class);
    }

    public function healthEvents(): HasMany
    {
        return $this->hasMany(HealthEvent::class);
    }

    public function treatments(): HasMany
    {
        return $this->hasMany(Treatment::class);
    }

    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class);
    }
}
