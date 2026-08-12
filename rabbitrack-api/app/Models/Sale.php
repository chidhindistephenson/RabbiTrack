<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Sale extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'farm_id',
        'rabbit_id',
        'sold_by_id',
        'buyer_name',
        'buyer_phone',
        'sold_on',
        'sale_price',
        'currency',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'sold_on' => 'date',
            'sale_price' => 'decimal:2',
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

    public function soldBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sold_by_id');
    }
}
