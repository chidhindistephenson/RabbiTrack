<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('weight_records', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('rabbit_id')->nullable()->constrained('rabbits')->cascadeOnDelete();
            $table->foreignUuid('litter_id')->nullable()->constrained()->cascadeOnDelete();
            $table->foreignId('recorded_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('weighed_on');
            $table->decimal('weight_value', 8, 3);
            $table->string('weight_unit', 10)->default('kg');
            $table->string('method')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['farm_id', 'weighed_on']);
            $table->index(['rabbit_id', 'weighed_on']);
            $table->index(['litter_id', 'weighed_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('weight_records');
    }
};
