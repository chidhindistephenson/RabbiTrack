<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Expense extends Model
{
    use HasFactory, HasUuids;

    public const CATEGORIES = [
        'feed',
        'medicine',
        'equipment',
        'housing',
        'labour',
        'utilities',
        'transport',
        'other',
    ];

    protected $fillable = [
        'farm_id',
        'recorded_by_id',
        'category',
        'vendor',
        'spent_on',
        'amount',
        'currency',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'spent_on' => 'date',
            'amount' => 'decimal:2',
        ];
    }

    public function farm(): BelongsTo
    {
        return $this->belongsTo(Farm::class);
    }

    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by_id');
    }
}
