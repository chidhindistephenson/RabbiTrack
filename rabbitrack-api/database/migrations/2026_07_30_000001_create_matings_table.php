<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('matings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('farm_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('doe_id')->constrained('rabbits')->cascadeOnDelete();
            $table->foreignUuid('buck_id')->constrained('rabbits')->cascadeOnDelete();
            $table->foreignId('recorded_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('mated_at');
            $table->string('outcome')->default('observed');
            $table->string('behavior_observed')->nullable();
            $table->date('pregnancy_check_due_on');
            $table->date('expected_kindling_on');
            $table->date('nest_box_due_on');
            $table->string('status')->default('awaiting_pregnancy_check');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['farm_id', 'mated_at']);
            $table->index(['doe_id', 'mated_at']);
            $table->index(['buck_id', 'mated_at']);
            $table->index(['farm_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('matings');
    }
};
