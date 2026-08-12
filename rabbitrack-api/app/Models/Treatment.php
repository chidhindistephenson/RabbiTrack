<?php

namespace App\Models;

use Database\Factories\TreatmentFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Treatment extends Model
{
    /** @use HasFactory<TreatmentFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'farm_id',
        'health_event_id',
        'rabbit_id',
        'prescribed_by_id',
        'medication',
        'dosage',
        'route',
        'frequency',
        'started_on',
        'ended_on',
        'withdrawal_days',
        'withdrawal_ends_on',
        'status',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'started_on' => 'date',
            'ended_on' => 'date',
            'withdrawal_ends_on' => 'date',
        ];
    }

    public function healthEvent(): BelongsTo
    {
        return $this->belongsTo(HealthEvent::class);
    }

    public function rabbit(): BelongsTo
    {
        return $this->belongsTo(Rabbit::class);
    }
}
