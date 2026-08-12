<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('weanings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('litter_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('doe_id')->constrained('rabbits')->cascadeOnDelete();
            $table->foreignId('recorded_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('weaned_on');
            $table->unsignedInteger('number_weaned');
            $table->decimal('average_weight_value', 8, 3)->nullable();
            $table->string('weight_unit', 10)->default('kg');
            $table->string('destination')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['farm_id', 'weaned_on']);
            $table->index(['litter_id', 'weaned_on']);
            $table->index(['doe_id', 'weaned_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('weanings');
    }
};
