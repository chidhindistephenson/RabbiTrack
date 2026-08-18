<?php

namespace App\Models;

use Database\Factories\TaskFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Task extends Model
{
    /** @use HasFactory<TaskFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    public const TYPES = [
        'pregnancy_check',
        'nest_box_preparation',
        'expected_kindling',
        'weaning',
        'kit_identification',
        'retirement_review',
        'manual',
    ];

    public const STATUSES = [
        'open',
        'completed',
        'snoozed',
        'cancelled',
    ];

    protected $fillable = [
        'farm_id',
        'assigned_to_id',
        'type',
        'title',
        'description',
        'due_on',
        'due_time',
        'priority',
        'status',
        'related_type',
        'related_id',
        'rabbit_id',
        'litter_id',
        'location_id',
        'metadata',
    ];

    protected function casts(): array
    {
        return [
            'due_on' => 'date',
            'metadata' => 'array',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function assignedTo(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_to_id');
    }

    public function rabbit(): BelongsTo
    {
        return $this->belongsTo(Rabbit::class);
    }

    public function location(): BelongsTo
    {
        return $this->belongsTo(Location::class);
    }
}
